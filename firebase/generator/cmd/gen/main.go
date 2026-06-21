package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/yu-fukunaga/youdoyou-intelligence/firebase/generator/internal/generator"
	"github.com/yu-fukunaga/youdoyou-intelligence/firebase/generator/internal/parser"
)

type genTargetLang string

const (
	GenTargetLang_Go    genTargetLang = "go"
	GenTargetLang_Swift genTargetLang = "swift"
)

type genConfig struct {
	outputDir string
}

var genConfigMap = map[genTargetLang]genConfig{
	GenTargetLang_Go:    {outputDir: "../../server/gen/schema"},
	GenTargetLang_Swift: {outputDir: "../../client/Packages/AppCore/Sources/AppCore/Generated"},
}

func main() {
	target := flag.String("target", "", "Specify the target for code generation go or swift")
	schemaPath := flag.String("schema", "schema/firestore.yaml", "Specify the path to the schema file")
	flag.Parse()
	if err := run(genTargetLang(*target), *schemaPath); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(lang genTargetLang, schemaPath string) error {
	schema, err := parser.ParseFile(schemaPath)
	if err != nil {
		return fmt.Errorf("parsing schema: %w", err)
	}

	config, ok := genConfigMap[lang]
	if !ok {
		return fmt.Errorf("invalid target specified: %s", lang)
	}
	if err := os.MkdirAll(config.outputDir, 0750); err != nil {
		return fmt.Errorf("creating output directory: %w", err)
	}

	switch lang {
	case GenTargetLang_Go:
		gen := generator.New(schema, config.outputDir)
		if err := gen.Generate(); err != nil {
			return fmt.Errorf("generating Go code: %w", err)
		}
	case GenTargetLang_Swift:
		swiftGen := generator.NewSwift(schema, config.outputDir)
		if err := swiftGen.Generate(); err != nil {
			return fmt.Errorf("generating Swift code: %w", err)
		}
	default:
		return fmt.Errorf("unhandled language: %s", lang)
	}

	fmt.Println("Code generation completed successfully.")
	return nil
}
