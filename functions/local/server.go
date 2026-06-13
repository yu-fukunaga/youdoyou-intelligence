package main

import (
	"log"

	"github.com/GoogleCloudPlatform/functions-framework-go/funcframework"

	_ "github.com/yu-fukunaga/youdoyou-intelligence/functions"
)

// if you want to use a local HTTP server
func main() {

	log.Println("Starting function on http://localhost:8082/")
	if err := funcframework.Start("8082"); err != nil {
		log.Fatalf("Failed to start function: %v\n", err)
	}
}
