package functions

import (
	"github.com/yu-fukunaga/youdoyou-intelligence/functions/handlers"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	githubWebhook := handlers.NewGithubWebhook()
	functions.HTTP("GithubWebhook", githubWebhook.Handle)
}
