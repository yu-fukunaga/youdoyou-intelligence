package handler

import (
	"context"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/usecase"
)

func HandleGithubWebhook(w http.ResponseWriter, r *http.Request, flowFunc func(context.Context, *usecase.GithubWebhookInput) (string, error)) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "failed to read body", http.StatusBadRequest)
		return
	}

	input := &usecase.GithubWebhookInput{
		EventType: r.Header.Get("X-GitHub-Event"),
		Payload:   body,
	}

	if _, err := flowFunc(r.Context(), input); err != nil {
		eventType := strings.ReplaceAll(strings.ReplaceAll(input.EventType, "\n", ""), "\r", "")
		log.Printf("github webhook error: event=%s err=%v", eventType, err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}
