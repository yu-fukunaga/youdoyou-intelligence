package clients

import (
	"context"
	"net/http"
	"strconv"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v72/github"
	"github.com/yu-fukunaga/youdoyou-intelligence/functions/config"
)

func NewGitHubClient(ctx context.Context, cfg *config.Config) (*github.Client, error) {
	appID, err := strconv.ParseInt(cfg.GitHubAppID, 10, 64)
	if err != nil {
		return nil, err
	}
	installationID, err := strconv.ParseInt(cfg.GitHubInstallationID, 10, 64)
	if err != nil {
		return nil, err
	}

	privateKey := []byte(cfg.GitHubPrivateKey)

	itr, err := ghinstallation.New(http.DefaultTransport, appID, installationID, privateKey)
	if err != nil {
		return nil, err
	}

	return github.NewClient(&http.Client{Transport: itr}), nil
}
