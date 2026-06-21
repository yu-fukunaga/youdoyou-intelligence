package parser

import (
	"fmt"
	"regexp"
	"strings"
)

// vectorTypeRe matches vector(N) where N is a positive integer.
var vectorTypeRe = regexp.MustCompile(`^vector\([1-9]\d*\)$`)

// Valid primitive types for fields
var validFieldTypes = map[string]bool{
	"string":           true,
	"integer":          true,
	"float":            true,
	"boolean":          true,
	"timestamp":        true,
	"server_timestamp": true,
	"id":               true,
	"array":            true,
	"map":              true,
}

// Valid primitive types for array items
var validItemTypes = map[string]bool{
	"string":  true,
	"integer": true,
	"float":   true,
	"boolean": true,
}

// Validate validates the schema and returns a list of errors.
func (s *Schema) Validate() []error {
	var errs []error

	// Validate models
	if len(s.Models.Values) == 0 {
		errs = append(errs, fmt.Errorf("schema must have at least one model in 'models' section"))
	}

	for _, modelName := range s.Models.Keys {
		model := s.Models.Values[modelName]
		errs = append(errs, s.validateModel(modelName, model)...)
	}

	// Validate collections
	if len(s.Collections.Values) == 0 {
		errs = append(errs, fmt.Errorf("schema must have at least one collection in 'collections' section"))
	}

	for _, collectionName := range s.Collections.Keys {
		collection := s.Collections.Values[collectionName]
		errs = append(errs, s.validateCollection(collectionName, collection)...)
	}

	return errs
}

func (s *Schema) validateModel(modelName string, model Model) []error {
	var errs []error

	if modelName == "" {
		errs = append(errs, fmt.Errorf("model name cannot be empty"))
		return errs
	}

	if !isValidModelName(modelName) {
		errs = append(errs, fmt.Errorf("model '%s': name must start with uppercase letter", modelName))
	}

	if len(model.Fields.Values) == 0 {
		errs = append(errs, fmt.Errorf("model '%s': must have at least one field", modelName))
		return errs
	}

	for _, fieldName := range model.Fields.Keys {
		field := model.Fields.Values[fieldName]
		errs = append(errs, s.validateField(modelName, fieldName, field)...)
	}

	return errs
}

func (s *Schema) validateField(modelName, fieldName string, field Field) []error {
	var errs []error
	prefix := fmt.Sprintf("model '%s', field '%s'", modelName, fieldName)

	if fieldName == "" {
		errs = append(errs, fmt.Errorf("%s: field name cannot be empty", prefix))
		return errs
	}

	if field.Type == "" {
		errs = append(errs, fmt.Errorf("%s: type is required", prefix))
		return errs
	}

	// Check if type is valid
	if !validFieldTypes[field.Type] && !strings.HasPrefix(field.Type, "vector(") {
		errs = append(errs, fmt.Errorf("%s: invalid type '%s'. Valid types: string, integer, float, boolean, timestamp, server_timestamp, id, array, map, vector(N)", prefix, field.Type))
	}

	// Validate array fields
	if field.Type == "array" {
		if field.ItemType == "" && field.ItemModel == "" {
			errs = append(errs, fmt.Errorf("%s: array type requires 'item_type' or 'item_model'", prefix))
		}
		if field.ItemType != "" && field.ItemModel != "" {
			errs = append(errs, fmt.Errorf("%s: array type cannot have both 'item_type' and 'item_model'", prefix))
		}
		if field.ItemType != "" && !validItemTypes[field.ItemType] {
			errs = append(errs, fmt.Errorf("%s: invalid item_type '%s'. Valid types: string, integer, float, boolean", prefix, field.ItemType))
		}
		if field.ItemModel != "" {
			if _, exists := s.Models.Values[field.ItemModel]; !exists {
				errs = append(errs, fmt.Errorf("%s: item_model '%s' references non-existent model", prefix, field.ItemModel))
			}
		}
	}

	// Validate map fields
	if field.Type == "map" {
		if field.Model == "" {
			errs = append(errs, fmt.Errorf("%s: map type requires 'model' reference", prefix))
		} else {
			if _, exists := s.Models.Values[field.Model]; !exists {
				errs = append(errs, fmt.Errorf("%s: model '%s' references non-existent model", prefix, field.Model))
			}
		}
	}

	// Validate enum
	if len(field.Enum) > 0 {
		if field.Type != "string" {
			errs = append(errs, fmt.Errorf("%s: enum can only be used with string type", prefix))
		}
		for i, v := range field.Enum {
			if v == "" {
				errs = append(errs, fmt.Errorf("%s: enum value at index %d cannot be empty", prefix, i))
			}
		}
	}

	// Validate vector type format
	if strings.HasPrefix(field.Type, "vector(") {
		if !vectorTypeRe.MatchString(field.Type) {
			errs = append(errs, fmt.Errorf("%s: invalid vector type format '%s'. Expected: vector(N) where N is a positive integer", prefix, field.Type))
		}
	}

	return errs
}

func (s *Schema) validateCollection(collectionName string, collection Collection) []error {
	var errs []error
	prefix := fmt.Sprintf("collection '%s'", collectionName)

	if collectionName == "" {
		errs = append(errs, fmt.Errorf("collection name cannot be empty"))
		return errs
	}

	if collection.Model == "" {
		errs = append(errs, fmt.Errorf("%s: model reference is required", prefix))
	} else {
		if _, exists := s.Models.Values[collection.Model]; !exists {
			errs = append(errs, fmt.Errorf("%s: model '%s' references non-existent model", prefix, collection.Model))
		}
	}

	// Validate subcollections
	for _, subName := range collection.Subcollections.Keys {
		subCollection := collection.Subcollections.Values[subName]
		errs = append(errs, s.validateCollection(fmt.Sprintf("%s/%s", collectionName, subName), subCollection)...)
	}

	return errs
}

func isValidModelName(name string) bool {
	if len(name) == 0 {
		return false
	}
	// Model names should start with uppercase
	first := rune(name[0])
	return first >= 'A' && first <= 'Z'
}
