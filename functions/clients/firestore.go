// clients/firestore.go
package clients

import (
	"context"
	"log"

	"cloud.google.com/go/firestore"
)

func NewFirestoreClient(ctx context.Context) *firestore.Client {
	client, err := firestore.NewClient(ctx, firestore.DetectProjectID)
	if err != nil {
		log.Fatalf("failed to create firestore client: %v", err)
	}
	return client
}
