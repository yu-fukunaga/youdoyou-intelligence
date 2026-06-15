package clients

import (
	"context"
	"net/http"
	"strconv"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v72/github"

	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/usecase"
)

type githubClient struct {
	client *github.Client
}

func NewGithubClient(appID, installationID string, privateKeyStr string) (usecase.GithubAPIClient, error) {
	aid, err := strconv.ParseInt(appID, 10, 64)
	if err != nil {
		return nil, err
	}
	iid, err := strconv.ParseInt(installationID, 10, 64)
	if err != nil {
		return nil, err
	}

	privateKey := []byte(privateKeyStr)

	itr, err := ghinstallation.New(http.DefaultTransport, aid, iid, privateKey)
	if err != nil {
		return nil, err
	}

	return &githubClient{
		client: github.NewClient(&http.Client{Transport: itr}),
	}, nil
}

func (c *githubClient) ListCommitMessages(ctx context.Context, owner, repo string, prNumber int) ([]string, error) {
	commits, _, err := c.client.PullRequests.ListCommits(ctx, owner, repo, prNumber, nil)
	if err != nil {
		return nil, err
	}

	messages := make([]string, 0, len(commits))
	for _, commit := range commits {
		if msg := commit.GetCommit().GetMessage(); msg != "" {
			messages = append(messages, msg)
		}
	}
	return messages, nil
}
