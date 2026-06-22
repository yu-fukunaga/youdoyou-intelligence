package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/iterator"
	"gopkg.in/yaml.v3"
)

func seedCollectionGeneric[T any](ctx context.Context, client *firestore.Client, name string, config CollectionConfig) error {
	// Load as map[string]any to ensure we don't lose keys (like subcollections) not defined in the struct T.
	rawDocs, err := loadSeeds[map[string]any](dataDir, name)
	if err != nil {
		return err
	}

	numDocs := len(rawDocs)
	if numDocs == 0 {
		log.Printf("Warning: No seed data found for collection %s", name)
		return nil
	}

	for _, doc := range rawDocs {
		// Optional: Validate schema by attempting to convert the map to the generic type T.
		if yamlBytes, err := yaml.Marshal(doc); err == nil {
			var schemaCheck T
			if err := yaml.Unmarshal(yamlBytes, &schemaCheck); err != nil {
				log.Printf("Warning: document in %s might not match the schema: %v", name, err)
			}
		} else {
			log.Printf("Warning: failed to marshal document in %s for schema check: %v", name, err)
		}

		convertTimestamps(doc)

		id, ok := doc["id"].(string)
		if !ok || id == "" {
			return fmt.Errorf("seed document in %s must have a string id", name)
		}

		// Extract subcollection data before writing the parent document
		subData := make(map[string][]map[string]any)
		for _, sub := range config.Subcollections {
			if raw, exists := doc[sub.Key]; exists && raw != nil {
				switch items := raw.(type) {
				case []interface{}:
					var subDocs []map[string]any
					for _, item := range items {
						if m, ok := item.(map[string]any); ok {
							subDocs = append(subDocs, m)
						}
					}
					subData[sub.Key] = subDocs
				case []map[string]any:
					subData[sub.Key] = items
				default:
					return fmt.Errorf("unexpected type for subcollection %s: expected list, got %T", sub.Key, raw)
				}
				// Remove from the parent document fields since it's stored as a subcollection
				delete(doc, sub.Key)
			}
		}

		// Idempotency: delete existing document and subcollections
		if err := deleteDocument(ctx, client, config, id); err != nil {
			return fmt.Errorf("failed to delete %s/%s: %w", name, id, err)
		}

		// Remove id from the map (used as document path, not stored as a field)
		delete(doc, "id")

		// Create document
		docRef := client.Doc(config.Path(id))
		if _, err := docRef.Set(ctx, doc); err != nil {
			return fmt.Errorf("failed to create %s/%s: %w", name, id, err)
		}
		fmt.Printf("[%s] Created %s\n", id, name)

		// Create subcollection documents
		for _, sub := range config.Subcollections {
			for _, subDoc := range subData[sub.Key] {
				subID, ok := subDoc["id"].(string)
				if !ok || subID == "" {
					return fmt.Errorf("subcollection %s document must have a string id", sub.Key)
				}
				delete(subDoc, "id")

				// Sub-document timestamps should also be converted
				convertTimestamps(subDoc)

				subRef := client.Doc(sub.DocPath(id, subID))
				if _, err := subRef.Set(ctx, subDoc); err != nil {
					return fmt.Errorf("failed to create %s/%s/%s/%s: %w", name, id, sub.Key, subID, err)
				}
				fmt.Printf("[%s] Created %s: %s\n", id, sub.Key, subID)
			}
		}
	}
	return nil
}

func deleteDocument(ctx context.Context, client *firestore.Client, config CollectionConfig, id string) error {
	// Delete subcollection documents first
	for _, sub := range config.Subcollections {
		iter := client.Collection(sub.CollectionPath(id)).DocumentRefs(ctx)
		for {
			ref, err := iter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				return err
			}
			if _, err := ref.Delete(ctx); err != nil {
				return err
			}
		}
	}

	// Delete the document itself
	_, err := client.Doc(config.Path(id)).Delete(ctx)
	return err
}

// loadSeeds loads a specific collection's YAML file from a directory.
// It expects the file to be named <collectionName>.yaml and contain a list of documents.
func loadSeeds[T any](dir string, collectionName string) ([]T, error) {
	f := filepath.Join(dir, collectionName+".yaml")
	data, err := os.ReadFile(f) // #nosec G304 -- collectionName comes from the fixed collectionsMap defined in main.go, dir is an operator-supplied CLI flag for local seeding only
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // Return empty list if file doesn't exist
		}
		return nil, fmt.Errorf("failed to read file %s: %w", f, err)
	}

	var list []T
	if err := yaml.Unmarshal(data, &list); err != nil {
		return nil, fmt.Errorf("failed to unmarshal file %s: %w", f, err)
	}
	return list, nil
}

// convertTimestamps recursively converts RFC3339 strings to time.Time
// so that Firestore stores them as timestamps instead of strings.
func convertTimestamps(data map[string]any) {
	for k, v := range data {
		switch val := v.(type) {
		case string:
			if t, err := time.Parse(time.RFC3339, val); err == nil {
				data[k] = t
			}
		case map[string]any:
			convertTimestamps(val)
		case []any:
			for _, item := range val {
				if m, ok := item.(map[string]any); ok {
					convertTimestamps(m)
				}
			}
		case []map[string]any:
			for _, item := range val {
				convertTimestamps(item)
			}
		}
	}
}
