package parser

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// OrderedMap preserves the order of keys as they appear in YAML.
type OrderedMap[V any] struct {
	Keys   []string
	Values map[string]V
}

// NewOrderedMap creates an OrderedMap from keys and a map (for testing).
func NewOrderedMap[V any](keys []string, values map[string]V) OrderedMap[V] {
	return OrderedMap[V]{Keys: keys, Values: values}
}

// UnmarshalYAML implements custom unmarshaling to preserve key order.
func (o *OrderedMap[V]) UnmarshalYAML(node *yaml.Node) error {
	if node.Kind != yaml.MappingNode {
		return fmt.Errorf("expected mapping node, got %v", node.Kind)
	}

	o.Keys = make([]string, 0, len(node.Content)/2)
	o.Values = make(map[string]V, len(node.Content)/2)

	for i := 0; i < len(node.Content); i += 2 {
		keyNode := node.Content[i]
		valueNode := node.Content[i+1]

		var key string
		if err := keyNode.Decode(&key); err != nil {
			return err
		}

		var value V
		if err := valueNode.Decode(&value); err != nil {
			return err
		}

		o.Keys = append(o.Keys, key)
		o.Values[key] = value
	}

	return nil
}

// Schema represents the root structure of the YAML schema file.
type Schema struct {
	Models      OrderedMap[Model]      `yaml:"models"`
	Collections OrderedMap[Collection] `yaml:"collections"`
}

// Model represents a reusable model definition.
type Model struct {
	Fields OrderedMap[Field] `yaml:"fields"`
}

// Collection represents a Firestore collection definition.
type Collection struct {
	Path           string                 `yaml:"path"`
	Model          string                 `yaml:"model"` // Reference to a model name
	Description    string                 `yaml:"description"`
	Subcollections OrderedMap[Collection] `yaml:"subcollections"`
}

// Field represents a field definition within a model.
type Field struct {
	Type        string   `yaml:"type"`
	Description string   `yaml:"description"`
	Enum        []string `yaml:"enum"`
	ItemType    string   `yaml:"item_type"`  // For array of primitives
	ItemModel   string   `yaml:"item_model"` // For array of models
	Model       string   `yaml:"model"`      // For map referencing a model
	Optional    bool     `yaml:"optional"`   // Whether the field is optional
}

// ParseFile reads and parses a YAML schema file.
func ParseFile(path string) (*Schema, error) {
	data, err := os.ReadFile(path) // #nosec G304 -- path is an explicit CLI argument for the schema file to generate from
	if err != nil {
		return nil, err
	}

	var schema Schema
	if err := yaml.Unmarshal(data, &schema); err != nil {
		return nil, err
	}

	return &schema, nil
}
