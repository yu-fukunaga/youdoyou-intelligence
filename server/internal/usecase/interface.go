package usecase

import (
	"context"

	schema "github.com/yu-fukunaga/youdoyou-intelligence/gen-go/schema"
)

type PullRequestRepository interface {
	Save(ctx context.Context, pull schema.GithubPull) (string, error)
}

type GithubAPIClient interface {
	ListCommitMessages(ctx context.Context, owner, repo string, prNumber int) ([]string, error)
}
