package generator

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"generator/internal/parser"
)

// Helper functions for creating test schemas
func makeFields(fields map[string]parser.Field) parser.OrderedMap[parser.Field] {
	keys := make([]string, 0, len(fields))
	for k := range fields {
		keys = append(keys, k)
	}
	return parser.OrderedMap[parser.Field]{Keys: keys, Values: fields}
}

func makeModels(models map[string]parser.Model) parser.OrderedMap[parser.Model] {
	keys := make([]string, 0, len(models))
	for k := range models {
		keys = append(keys, k)
	}
	return parser.OrderedMap[parser.Model]{Keys: keys, Values: models}
}

func makeCollections(cols map[string]parser.Collection) parser.OrderedMap[parser.Collection] {
	keys := make([]string, 0, len(cols))
	for k := range cols {
		keys = append(keys, k)
	}
	return parser.OrderedMap[parser.Collection]{Keys: keys, Values: cols}
}

func TestGenerate_BasicStruct(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":   {Type: "id"},
					"name": {Type: "string"},
					"age":  {Type: "integer"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {
				Model: "User",
			},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	// Read generated file
	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check package declaration
	if !strings.Contains(code, "package schema") {
		t.Error("expected 'package schema' in generated code")
	}

	// Check struct definition
	if !strings.Contains(code, "type User struct") {
		t.Error("expected 'type User struct' in generated code")
	}

	// Check ID field with special tag
	if !strings.Contains(code, `ID string`) && !strings.Contains(code, `firestore:"-"`) {
		t.Error("expected ID field with firestore:\"-\" tag")
	}

	// Check other fields (with tabs and tags)
	if !strings.Contains(code, "Name") || !strings.Contains(code, "string") {
		t.Error("expected Name string field")
	}
	if !strings.Contains(code, "Age") || !strings.Contains(code, "int") {
		t.Error("expected Age int field")
	}

	// Check getters
	if !strings.Contains(code, "func (u *User) GetName()") {
		t.Error("expected GetName getter method")
	}
	if !strings.Contains(code, "func (u *User) GetAge()") {
		t.Error("expected GetAge getter method")
	}
	if !strings.Contains(code, "func (u *User) GetID()") {
		t.Error("expected GetID getter method")
	}
}

func TestGenerate_WithEnum(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":     {Type: "id"},
					"status": {Type: "string", Enum: []string{"active", "inactive"}},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {Model: "User"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check enum type
	if !strings.Contains(code, "type UserStatus string") {
		t.Errorf("expected 'type UserStatus string' enum type, got:\n%s", code)
	}

	// Check enum constants
	if !strings.Contains(code, "UserStatusActive") {
		t.Errorf("expected UserStatusActive constant, got:\n%s", code)
	}
	if !strings.Contains(code, "UserStatusInactive") {
		t.Errorf("expected UserStatusInactive constant, got:\n%s", code)
	}
}

func TestGenerate_WithArrayAndMap(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"Tag": {
				Fields: makeFields(map[string]parser.Field{
					"name": {Type: "string"},
				}),
			},
			"Profile": {
				Fields: makeFields(map[string]parser.Field{
					"bio": {Type: "string"},
				}),
			},
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":      {Type: "id"},
					"tags":    {Type: "array", ItemType: "string"},
					"friends": {Type: "array", ItemModel: "Tag"},
					"profile": {Type: "map", Model: "Profile"},
					"scores":  {Type: "array", ItemType: "integer"},
					"ratings": {Type: "array", ItemType: "float"},
					"flags":   {Type: "array", ItemType: "boolean"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {Model: "User"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check array of primitives
	if !strings.Contains(code, "Tags") || !strings.Contains(code, "[]string") {
		t.Errorf("expected Tags []string field, got:\n%s", code)
	}

	// Check array of model
	if !strings.Contains(code, "Friends") || !strings.Contains(code, "[]*Tag") {
		t.Errorf("expected Friends []*Tag field, got:\n%s", code)
	}

	// Check map with model
	if !strings.Contains(code, "Profile") || !strings.Contains(code, "*Profile") {
		t.Errorf("expected Profile *Profile field, got:\n%s", code)
	}

	// Check other array types
	if !strings.Contains(code, "Scores") || !strings.Contains(code, "[]int") {
		t.Errorf("expected Scores []int field, got:\n%s", code)
	}
	if !strings.Contains(code, "Ratings") || !strings.Contains(code, "[]float64") {
		t.Errorf("expected Ratings []float64 field, got:\n%s", code)
	}
	if !strings.Contains(code, "Flags") || !strings.Contains(code, "[]bool") {
		t.Errorf("expected Flags []bool field, got:\n%s", code)
	}

	// Check referenced models are generated
	if !strings.Contains(code, "type Tag struct") {
		t.Error("expected Tag struct to be generated")
	}
	if !strings.Contains(code, "type Profile struct") {
		t.Error("expected Profile struct to be generated")
	}
}

func TestGenerate_WithTimestamp(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":        {Type: "id"},
					"createdAt": {Type: "timestamp"},
					"updatedAt": {Type: "server_timestamp"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {Model: "User"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check import
	if !strings.Contains(code, `"time"`) {
		t.Error("expected 'time' import")
	}

	// Check fields
	if !strings.Contains(code, "CreatedAt time.Time") {
		t.Error("expected 'CreatedAt time.Time' field")
	}
	if !strings.Contains(code, "UpdatedAt time.Time") {
		t.Error("expected 'UpdatedAt time.Time' field")
	}
}

func TestGenerate_WithVector(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"Document": {
				Fields: makeFields(map[string]parser.Field{
					"id":        {Type: "id"},
					"embedding": {Type: "vector(768)"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"documents": {Model: "Document"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "document.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check vector field
	if !strings.Contains(code, "Embedding []float64") {
		t.Error("expected 'Embedding []float64' field")
	}
}

func TestGenerate_WithSubcollections(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"Thread": {
				Fields: makeFields(map[string]parser.Field{
					"id":    {Type: "id"},
					"title": {Type: "string"},
				}),
			},
			"Message": {
				Fields: makeFields(map[string]parser.Field{
					"id":      {Type: "id"},
					"content": {Type: "string"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"threads": {
				Model: "Thread",
				Subcollections: makeCollections(map[string]parser.Collection{
					"messages": {Model: "Message"},
				}),
			},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "thread.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Both Thread and Message should be in the same file
	if !strings.Contains(code, "type Thread struct") {
		t.Error("expected Thread struct")
	}
	if !strings.Contains(code, "type Message struct") {
		t.Error("expected Message struct in same file as parent collection")
	}
}

func TestToPascalCase(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"name", "Name"},
		{"firstName", "FirstName"},
		{"id", "Id"},
		{"", ""},
		{"A", "A"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := toPascalCase(tt.input)
			if result != tt.expected {
				t.Errorf("toPascalCase(%q) = %q, expected %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestSingularize(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"users", "user"},
		{"threads", "thread"},
		{"messages", "message"},
		{"categories", "category"},
		{"addresses", "address"}, // sses -> ss
		{"statuses", "status"},   // ses -> s
		{"boss", "boss"},         // ss stays
		{"user", "user"},         // no s
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := singularize(tt.input)
			if result != tt.expected {
				t.Errorf("singularize(%q) = %q, expected %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestZeroValueForType(t *testing.T) {
	gen := &Generator{}

	tests := []struct {
		goType   string
		expected string
	}{
		{"string", `""`},
		{"int", "0"},
		{"float64", "0"},
		{"bool", "false"},
		{"time.Time", "time.Time{}"},
		{"*User", "nil"},
		{"[]string", "nil"},
		{"[]*Tag", "nil"},
		{"map[string]interface{}", "nil"},
		{"Status", `""`}, // enum type
	}

	for _, tt := range tests {
		t.Run(tt.goType, func(t *testing.T) {
			result := gen.zeroValueForType(tt.goType)
			if result != tt.expected {
				t.Errorf("zeroValueForType(%q) = %q, expected %q", tt.goType, result, tt.expected)
			}
		})
	}
}

func TestFieldToGoType(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"Tag": {
				Fields: makeFields(map[string]parser.Field{
					"name": {Type: "string"},
				}),
			},
		}),
	}
	gen := New(schema, "")

	tests := []struct {
		name     string
		field    parser.Field
		expected string
	}{
		{"string", parser.Field{Type: "string"}, "string"},
		{"integer", parser.Field{Type: "integer"}, "int"},
		{"float", parser.Field{Type: "float"}, "float64"},
		{"boolean", parser.Field{Type: "boolean"}, "bool"},
		{"timestamp", parser.Field{Type: "timestamp"}, "time.Time"},
		{"timestamp_optional", parser.Field{Type: "timestamp", Optional: true}, "*time.Time"},
		{"server_timestamp", parser.Field{Type: "server_timestamp"}, "time.Time"},
		{"array_string", parser.Field{Type: "array", ItemType: "string"}, "[]string"},
		{"array_int", parser.Field{Type: "array", ItemType: "integer"}, "[]int"},
		{"array_model", parser.Field{Type: "array", ItemModel: "Tag"}, "[]*Tag"},
		{"map", parser.Field{Type: "map", Model: "Tag"}, "*Tag"},
		{"vector", parser.Field{Type: "vector(768)"}, "[]float64"},
		{"enum", parser.Field{Type: "string", Enum: []string{"a", "b"}}, "UserStatus"}, // uses model name + field name
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// For enum test, use "status" as field name
			fieldName := tt.name
			if tt.name == "enum" {
				fieldName = "status"
			}
			result := gen.fieldToGoType(fieldName, tt.field, "User")
			if result != tt.expected {
				t.Errorf("fieldToGoType(%q, %+v) = %q, expected %q", fieldName, tt.field, result, tt.expected)
			}
		})
	}
}

func TestGenerate_NilSafeGetters(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":   {Type: "id"},
					"name": {Type: "string"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {Model: "User"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check nil check in getter
	if !strings.Contains(code, "if u == nil") {
		t.Error("expected nil check in getter")
	}
	if !strings.Contains(code, `return ""`) {
		t.Error("expected empty string return for nil case")
	}
}

func TestGenerate_FirestoreAndJSONTags(t *testing.T) {
	schema := &parser.Schema{
		Models: makeModels(map[string]parser.Model{
			"User": {
				Fields: makeFields(map[string]parser.Field{
					"id":        {Type: "id"},
					"firstName": {Type: "string"},
				}),
			},
		}),
		Collections: makeCollections(map[string]parser.Collection{
			"users": {Model: "User"},
		}),
	}

	tmpDir := t.TempDir()
	gen := New(schema, tmpDir)

	if err := gen.Generate(); err != nil {
		t.Fatalf("Generate failed: %v", err)
	}

	content, err := os.ReadFile(filepath.Join(tmpDir, "user.go"))
	if err != nil {
		t.Fatalf("failed to read generated file: %v", err)
	}

	code := string(content)

	// Check both firestore and json tags
	if !strings.Contains(code, `firestore:"firstName"`) {
		t.Error("expected firestore tag")
	}
	if !strings.Contains(code, `json:"firstName"`) {
		t.Error("expected json tag")
	}
}
