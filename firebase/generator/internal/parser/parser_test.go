package parser

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseFile(t *testing.T) {
	// Create a temporary YAML file
	content := `
models:
  User:
    fields:
      id:
        type: id
      name:
        type: string
      age:
        type: integer

collections:
  users:
    path: "users/{userId}"
    model: User
`
	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "test.yaml")
	if err := os.WriteFile(tmpFile, []byte(content), 0600); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	schema, err := ParseFile(tmpFile)
	if err != nil {
		t.Fatalf("ParseFile failed: %v", err)
	}

	// Check models
	if len(schema.Models.Values) != 1 {
		t.Errorf("expected 1 model, got %d", len(schema.Models.Values))
	}
	user, exists := schema.Models.Values["User"]
	if !exists {
		t.Fatal("User model not found")
	}
	if len(user.Fields.Values) != 3 {
		t.Errorf("expected 3 fields, got %d", len(user.Fields.Values))
	}

	// Check collections
	if len(schema.Collections.Values) != 1 {
		t.Errorf("expected 1 collection, got %d", len(schema.Collections.Values))
	}
	users, exists := schema.Collections.Values["users"]
	if !exists {
		t.Fatal("users collection not found")
	}
	if users.Model != "User" {
		t.Errorf("expected model 'User', got %q", users.Model)
	}
}

func TestParseFile_WithSubcollections(t *testing.T) {
	content := `
models:
  Thread:
    fields:
      id:
        type: id
      title:
        type: string
  Message:
    fields:
      id:
        type: id
      content:
        type: string

collections:
  threads:
    path: "threads/{threadId}"
    model: Thread
    subcollections:
      messages:
        path: "threads/{threadId}/messages/{messageId}"
        model: Message
`
	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "test.yaml")
	if err := os.WriteFile(tmpFile, []byte(content), 0600); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	schema, err := ParseFile(tmpFile)
	if err != nil {
		t.Fatalf("ParseFile failed: %v", err)
	}

	threads := schema.Collections.Values["threads"]
	if len(threads.Subcollections.Values) != 1 {
		t.Errorf("expected 1 subcollection, got %d", len(threads.Subcollections.Values))
	}

	messages, exists := threads.Subcollections.Values["messages"]
	if !exists {
		t.Fatal("messages subcollection not found")
	}
	if messages.Model != "Message" {
		t.Errorf("expected model 'Message', got %q", messages.Model)
	}
}

func TestParseFile_WithArrayAndMap(t *testing.T) {
	content := `
models:
  Tag:
    fields:
      name:
        type: string
  Profile:
    fields:
      bio:
        type: string
  User:
    fields:
      id:
        type: id
      tags:
        type: array
        item_type: string
      friends:
        type: array
        item_model: Tag
      profile:
        type: map
        model: Profile

collections:
  users:
    path: "users/{userId}"
    model: User
`
	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "test.yaml")
	if err := os.WriteFile(tmpFile, []byte(content), 0600); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	schema, err := ParseFile(tmpFile)
	if err != nil {
		t.Fatalf("ParseFile failed: %v", err)
	}

	user := schema.Models.Values["User"]

	// Check array with item_type
	tags := user.Fields.Values["tags"]
	if tags.Type != "array" {
		t.Errorf("expected type 'array', got %q", tags.Type)
	}
	if tags.ItemType != "string" {
		t.Errorf("expected item_type 'string', got %q", tags.ItemType)
	}

	// Check array with item_model
	friends := user.Fields.Values["friends"]
	if friends.ItemModel != "Tag" {
		t.Errorf("expected item_model 'Tag', got %q", friends.ItemModel)
	}

	// Check map with model
	profile := user.Fields.Values["profile"]
	if profile.Type != "map" {
		t.Errorf("expected type 'map', got %q", profile.Type)
	}
	if profile.Model != "Profile" {
		t.Errorf("expected model 'Profile', got %q", profile.Model)
	}
}

func TestParseFile_WithEnum(t *testing.T) {
	content := `
models:
  User:
    fields:
      id:
        type: id
      status:
        type: string
        enum: [active, inactive, banned]

collections:
  users:
    path: "users/{userId}"
    model: User
`
	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "test.yaml")
	if err := os.WriteFile(tmpFile, []byte(content), 0600); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	schema, err := ParseFile(tmpFile)
	if err != nil {
		t.Fatalf("ParseFile failed: %v", err)
	}

	user := schema.Models.Values["User"]
	status := user.Fields.Values["status"]
	if len(status.Enum) != 3 {
		t.Errorf("expected 3 enum values, got %d", len(status.Enum))
	}
	expected := []string{"active", "inactive", "banned"}
	for i, v := range expected {
		if status.Enum[i] != v {
			t.Errorf("expected enum[%d] to be %q, got %q", i, v, status.Enum[i])
		}
	}
}

func TestParseFile_FileNotFound(t *testing.T) {
	_, err := ParseFile("/nonexistent/path/file.yaml")
	if err == nil {
		t.Error("expected error for non-existent file")
	}
}

func TestParseFile_InvalidYAML(t *testing.T) {
	content := `
models:
  User
    fields:  # invalid indentation
`
	tmpDir := t.TempDir()
	tmpFile := filepath.Join(tmpDir, "invalid.yaml")
	if err := os.WriteFile(tmpFile, []byte(content), 0600); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}

	_, err := ParseFile(tmpFile)
	if err == nil {
		t.Error("expected error for invalid YAML")
	}
}
