package main

import (
	"fmt"
	"os"

	"github.com/yu-fukunaga/youdoyou-intelligence/firebase/generator/internal/parser"
)

func main() {
	schemaPath := "./schema/firestore.yaml"
	if len(os.Args) > 1 {
		schemaPath = os.Args[1]
	}

	schema, err := parser.ParseFile(schemaPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing schema: %v\n", err)
		os.Exit(1)
	}

	errs := schema.Validate()
	if len(errs) > 0 {
		fmt.Fprintf(os.Stderr, "Schema validation failed with %d error(s):\n", len(errs))
		for _, e := range errs {
			fmt.Fprintf(os.Stderr, "  - %s\n", e)
		}
		os.Exit(1)
	}

	fmt.Println("Schema validation passed.")
}
