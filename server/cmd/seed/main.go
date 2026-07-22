package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"

	"cloud.google.com/go/firestore"

	"github.com/yu-fukunaga/youdoyou-intelligence/gen-go/schema"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/config"
)

var dataDir string

type SubcollectionConfig struct {
	Key            string
	CollectionPath func(string) string
	DocPath        func(string, string) string
}

type CollectionConfig struct {
	Path           func(string) string
	Subcollections []SubcollectionConfig
	// Seed defines how to load and seed this collection.
	Seed func(ctx context.Context, client *firestore.Client, name string, config CollectionConfig) error
}

// collectionsMap defines all seedable collections.
// To add a new collection, add a CollectionConfig entry here.
var collectionsMap = map[string]CollectionConfig{
	schema.CollectionThreads: {
		Path: schema.ThreadPath,
		Subcollections: []SubcollectionConfig{
			{Key: schema.CollectionMessages, CollectionPath: schema.MessageCollectionPath, DocPath: schema.MessagePath},
		},
		Seed: seedCollectionGeneric[schema.Thread],
	},
	schema.CollectionDomains: {
		Path: schema.DomainPath,
		Seed: seedCollectionGeneric[schema.Domain],
	},
	schema.CollectionActivities: {
		Path: schema.ActivityPath,
		Seed: seedCollectionGeneric[schema.Activity],
	},
}

func main() {
	flag.StringVar(&dataDir, "dir", "./cmd/seed/collection_data", "Directory containing seed files")
	flag.Parse()
	ctx := context.Background()

	cfg := config.LoadConfig()

	emulatorHost := os.Getenv("FIRESTORE_EMULATOR_HOST")
	if emulatorHost == "" {
		log.Fatalln("Error: FIRESTORE_EMULATOR_HOST environment variable is not set")
	}

	authEmulatorHost := os.Getenv("FIREBASE_AUTH_EMULATOR_HOST")
	if authEmulatorHost == "" {
		log.Fatalln("Error: FIREBASE_AUTH_EMULATOR_HOST environment variable is not set")
	}
	log.Printf("Target: firestore (%s), auth (%s), project: %s", emulatorHost, authEmulatorHost, cfg.ProjectID) // #nosec G706 -- values are operator-supplied env vars for this local-only CLI, not untrusted input

	if err := run(ctx, cfg); err != nil {
		log.Fatal(err)
	}
}

func run(ctx context.Context, cfg *config.Config) error {
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: cfg.ProjectID})
	if err != nil {
		log.Fatalf("Failed to init firebase app: %v", err)
	}
	authClient, err := app.Auth(ctx)
	if err != nil {
		log.Fatalf("Failed to get auth client: %v", err)
	}

	firestoreClient, err := firestore.NewClient(ctx, cfg.ProjectID)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer func() {
		if err := firestoreClient.Close(); err != nil {
			log.Println(err)
		}
	}()

	log.Println("Clearing database...")
	if err := clearDatabase(os.Getenv("FIRESTORE_EMULATOR_HOST"), cfg.ProjectID); err != nil {
		return fmt.Errorf("failed to clear database: %w", err)
	}

	if err := SeedAuthUsers(ctx, authClient); err != nil {
		return err
	}

	for name, config := range collectionsMap {
		if err := config.Seed(ctx, firestoreClient, name, config); err != nil {
			return fmt.Errorf("failed to seed %s: %w", name, err)
		}
	}
	return nil
}
