package functions

import (
	"github.com/yu-fukunaga/youdoyou-intelligence/functions/handlers"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	githubWatcher := handlers.NewGithubWatcher()
	functions.HTTP("GithubWebhook", githubWatcher.Handle)
}
