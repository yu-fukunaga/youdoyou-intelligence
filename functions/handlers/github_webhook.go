package handlers

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"

	"github.com/google/go-github/v72/github"

	"github.com/yu-fukunaga/youdoyou-intelligence/functions/config"
)

type GithubWebhook struct {
	cfg        *config.Config
	httpClient *http.Client
}

func NewGithubWebhook() *GithubWebhook {
	cfg := config.LoadGithubWebhookConfig()
	return &GithubWebhook{
		cfg:        cfg,
		httpClient: &http.Client{},
	}
}

func (gw *GithubWebhook) Handle(w http.ResponseWriter, req *http.Request) {
	secret := []byte(gw.cfg.GitHubWebhookSecret)
	if gw.cfg.IsLocalEnv() {
		secret = []byte{}
	}

	payload, err := github.ValidatePayload(req, secret)
	if err != nil {
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}

	eventType := github.WebHookType(req)
	targetURL := gw.cfg.ServerURL + "/v1/webhook/github"

	parsedURL, err := url.ParseRequestURI(targetURL)
	if err != nil || (parsedURL.Scheme != "https" && parsedURL.Scheme != "http") {
		log.Printf("invalid server URL: %s", targetURL)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	proxyReq, err := http.NewRequestWithContext(req.Context(), http.MethodPost, parsedURL.String(), bytes.NewReader(payload))
	if err != nil {
		log.Printf("failed to create proxy request: %v", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	proxyReq.Header.Set("Content-Type", "application/json")
	proxyReq.Header.Set("X-GitHub-Event", eventType)

	if !gw.cfg.IsLocalEnv() {
		token, err := fetchIDToken(req.Context(), gw.cfg.ServerURL)
		if err != nil {
			log.Printf("failed to fetch id token: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		proxyReq.Header.Set("Authorization", "Bearer "+token)
	}

	resp, err := gw.httpClient.Do(proxyReq) //nolint:gosec // G704: URL is constructed from server config, not user input
	if err != nil {
		log.Printf("failed to forward to server: %v", err)
		http.Error(w, "failed to forward request", http.StatusBadGateway)
		return
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.Printf("failed to close response body: %v", err)
		}
	}()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("server returned non-200: status=%d body=%s", resp.StatusCode, body)
		http.Error(w, "server error", http.StatusBadGateway)
		return
	}

	if _, err := fmt.Fprint(w, "ok"); err != nil {
		log.Printf("failed to write response: %v", err)
	}
}

func fetchIDToken(ctx context.Context, audience string) (string, error) {
	metadataURL := "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=" + url.QueryEscape(audience)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, metadataURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Metadata-Flavor", "Google")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.Printf("failed to close response body: %v", err)
		}
	}()

	token, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	return string(token), nil
}
