package parser

import (
	"strings"
	"testing"
)

// Helper functions for creating test schemas
func makeFields(fields map[string]Field) OrderedMap[Field] {
	keys := make([]string, 0, len(fields))
	for k := range fields {
		keys = append(keys, k)
	}
	return OrderedMap[Field]{Keys: keys, Values: fields}
}

func makeModels(models map[string]Model) OrderedMap[Model] {
	keys := make([]string, 0, len(models))
	for k := range models {
		keys = append(keys, k)
	}
	return OrderedMap[Model]{Keys: keys, Values: models}
}

func makeCollections(cols map[string]Collection) OrderedMap[Collection] {
	keys := make([]string, 0, len(cols))
	for k := range cols {
		keys = append(keys, k)
	}
	return OrderedMap[Collection]{Keys: keys, Values: cols}
}

func TestValidate_ValidSchema(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"name": {Type: "string"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {
				Model: "User",
			},
		}),
	}

	errs := schema.Validate()
	if len(errs) > 0 {
		t.Errorf("expected no errors, got %d: %v", len(errs), errs)
	}
}

func TestValidate_NoModels(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	if len(errs) == 0 {
		t.Error("expected error for missing models")
	}

	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "at least one model") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about missing models section")
	}
}

func TestValidate_NoCollections(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id": {Type: "id"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{}),
	}

	errs := schema.Validate()
	if len(errs) == 0 {
		t.Error("expected error for missing collections")
	}

	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "at least one collection") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about missing collections section")
	}
}

func TestValidate_ModelNameMustStartWithUppercase(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"user": { // lowercase - should fail
				Fields: makeFields(map[string]Field{
					"id": {Type: "id"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "user"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "must start with uppercase") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about model name starting with uppercase")
	}
}

func TestValidate_ModelMustHaveFields(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{}), // no fields
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "at least one field") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about model having at least one field")
	}
}

func TestValidate_FieldTypeMustBeValid(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"data": {Type: "invalid_type"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "invalid type") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about invalid field type")
	}
}

func TestValidate_AllValidFieldTypes(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"Nested": {
				Fields: makeFields(map[string]Field{
					"value": {Type: "string"},
				}),
			},
			"Test": {
				Fields: makeFields(map[string]Field{
					"id":              {Type: "id"},
					"name":            {Type: "string"},
					"count":           {Type: "integer"},
					"price":           {Type: "float"},
					"active":          {Type: "boolean"},
					"createdAt":       {Type: "timestamp"},
					"serverCreatedAt": {Type: "server_timestamp"},
					"tags":            {Type: "array", ItemType: "string"},
					"meta":            {Type: "map", Model: "Nested"},
					"embedding":       {Type: "vector(768)"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"tests": {Model: "Test"},
		}),
	}

	errs := schema.Validate()
	if len(errs) > 0 {
		t.Errorf("expected no errors for valid types, got: %v", errs)
	}
}

func TestValidate_ArrayRequiresItemTypeOrItemModel(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"tags": {Type: "array"}, // missing item_type or item_model
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "item_type") && strings.Contains(err.Error(), "item_model") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about array requiring item_type or item_model")
	}
}

func TestValidate_ArrayCannotHaveBothItemTypeAndItemModel(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"Tag": {
				Fields: makeFields(map[string]Field{
					"name": {Type: "string"},
				}),
			},
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"tags": {Type: "array", ItemType: "string", ItemModel: "Tag"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "cannot have both") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about array having both item_type and item_model")
	}
}

func TestValidate_ArrayItemTypeMustBeValid(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"tags": {Type: "array", ItemType: "invalid"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "invalid item_type") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about invalid item_type")
	}
}

func TestValidate_ArrayItemModelMustExist(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":   {Type: "id"},
					"tags": {Type: "array", ItemModel: "NonExistent"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "non-existent model") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about non-existent item_model")
	}
}

func TestValidate_MapRequiresModel(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":      {Type: "id"},
					"profile": {Type: "map"}, // missing model
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "map type requires") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about map requiring model reference")
	}
}

func TestValidate_MapModelMustExist(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":      {Type: "id"},
					"profile": {Type: "map", Model: "NonExistent"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "non-existent model") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about non-existent model reference")
	}
}

func TestValidate_EnumOnlyWithStringType(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":     {Type: "id"},
					"status": {Type: "integer", Enum: []string{"1", "2"}}, // enum on non-string
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "enum can only be used with string") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about enum only being used with string type")
	}
}

func TestValidate_EnumValueCannotBeEmpty(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":     {Type: "id"},
					"status": {Type: "string", Enum: []string{"active", "", "banned"}},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "cannot be empty") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about empty enum value")
	}
}

func TestValidate_VectorTypeFormat(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id":        {Type: "id"},
					"embedding": {Type: "vector(768"}, // missing closing paren
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {Model: "User"},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "invalid vector type format") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about invalid vector type format")
	}
}

func TestValidate_VectorTypeRequiresPositiveInteger(t *testing.T) {
	for _, typ := range []string{"vector(abc)", "vector()", "vector(0)", "vector(7.5)"} {
		schema := &Schema{
			Models: makeModels(map[string]Model{
				"User": {
					Fields: makeFields(map[string]Field{
						"id":        {Type: "id"},
						"embedding": {Type: typ},
					}),
				},
			}),
			Collections: makeCollections(map[string]Collection{
				"users": {Model: "User"},
			}),
		}

		errs := schema.Validate()
		found := false
		for _, err := range errs {
			if strings.Contains(err.Error(), "invalid vector type format") {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("expected error about invalid vector type format for %q, got: %v", typ, errs)
		}
	}
}

func TestValidate_CollectionModelMustExist(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id": {Type: "id"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"posts": {Model: "Post"}, // Post doesn't exist
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "non-existent model") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about collection referencing non-existent model")
	}
}

func TestValidate_CollectionMustHaveModel(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"User": {
				Fields: makeFields(map[string]Field{
					"id": {Type: "id"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"users": {}, // missing model
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "model reference is required") {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected error about collection requiring model reference")
	}
}

func TestValidate_SubcollectionValidation(t *testing.T) {
	schema := &Schema{
		Models: makeModels(map[string]Model{
			"Thread": {
				Fields: makeFields(map[string]Field{
					"id": {Type: "id"},
				}),
			},
		}),
		Collections: makeCollections(map[string]Collection{
			"threads": {
				Model: "Thread",
				Subcollections: makeCollections(map[string]Collection{
					"messages": {Model: "Message"}, // Message doesn't exist
				}),
			},
		}),
	}

	errs := schema.Validate()
	found := false
	for _, err := range errs {
		if strings.Contains(err.Error(), "threads/messages") && strings.Contains(err.Error(), "non-existent") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected error about subcollection referencing non-existent model, got: %v", errs)
	}
}

func TestIsValidModelName(t *testing.T) {
	tests := []struct {
		name     string
		expected bool
	}{
		{"User", true},
		{"UserProfile", true},
		{"A", true},
		{"user", false},
		{"userProfile", false},
		{"123User", false},
		{"_User", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := isValidModelName(tt.name)
			if result != tt.expected {
				t.Errorf("isValidModelName(%q) = %v, expected %v", tt.name, result, tt.expected)
			}
		})
	}
}
