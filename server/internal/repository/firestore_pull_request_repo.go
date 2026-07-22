package repository

import (
	"context"

	"cloud.google.com/go/firestore"

	schema "github.com/yu-fukunaga/youdoyou-intelligence/gen-go/schema"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/usecase"
)

type FirestorePullRequestRepository struct {
	client *firestore.Client
}

func NewFirestorePullRequestRepository(client *firestore.Client) usecase.PullRequestRepository {
	return &FirestorePullRequestRepository{
		client: client,
	}
}

func (r *FirestorePullRequestRepository) Save(ctx context.Context, pull schema.GithubPull) (string, error) {
	docRef := r.client.Collection(schema.CollectionGithub_pulls).Doc(pull.ID)
	if _, err := docRef.Set(ctx, pull); err != nil {
		return "", err
	}
	return pull.ID, nil
}
