package handlers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/google/go-github/v72/github"

	"github.com/yu-fukunaga/youdoyou-intelligence/functions/clients"
	"github.com/yu-fukunaga/youdoyou-intelligence/functions/config"
)

type GithubWatcher struct {
	firestoreClient *firestore.Client
	githubClient    *github.Client
	cfg             *config.Config
}

func NewGithubWatcher() *GithubWatcher {
	ctx := context.Background()
	cfg := config.LoadGithubWatcherConfig()

	firestoreClient := clients.NewFirestoreClient(ctx)

	githubClient, err := clients.NewGitHubClient(ctx, cfg)
	if err != nil {
		log.Fatalf("failed to create github client: %v", err)
	}

	return &GithubWatcher{
		firestoreClient: firestoreClient,
		githubClient:    githubClient,
		cfg:             cfg,
	}
}

func (gw *GithubWatcher) Handle(w http.ResponseWriter, req *http.Request) {
	secret := []byte(gw.cfg.GitHubWebhookSecret)
	if gw.cfg.IsLocalEnv() {
		secret = []byte{}
	}

	payload, err := github.ValidatePayload(req, secret)
	if err != nil {
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}

	event, err := github.ParseWebHook(github.WebHookType(req), payload)
	if err != nil {
		http.Error(w, "failed to parse webhook", http.StatusBadRequest)
		return
	}

	switch e := event.(type) {
	case *github.IssuesEvent:
		if err := gw.handleIssue(req.Context(), e); err != nil {
			http.Error(w, "failed to handle issue", http.StatusInternalServerError)
			return
		}
	case *github.PullRequestEvent:
		if err := gw.handlePull(req.Context(), e); err != nil {
			http.Error(w, "failed to handle pull", http.StatusInternalServerError)
			return
		}
	}

	if _, err := fmt.Fprint(w, "ok"); err != nil {
		log.Printf("failed to write response: %v", err)
	}
}

func (gw *GithubWatcher) handleIssue(ctx context.Context, e *github.IssuesEvent) error {

	repoName := e.GetRepo().GetFullName()
	if repoName == "" {
		return nil
	}

	domainID := findDomainIDByRepo(repoName, gw.cfg.RepoDomainMapping)
	log.Printf("handleIssue: domainID=%s", domainID)
	if domainID == "" {
		return nil
	}

	topicID := repoName + "-" + strconv.Itoa(e.Issue.GetNumber())
	topic := map[string]interface{}{
		"id":       topicID,
		"title":    extractTitle(e.Issue.GetTitle()),
		"imageUrl": "",
	}

	domainRef := gw.firestoreClient.Collection("domains").Doc(domainID)

	switch e.GetAction() {
	case "opened":
		_, err := domainRef.Update(ctx, []firestore.Update{
			{Path: "topics", Value: firestore.ArrayUnion(topic)},
		})
		return err
	case "edited", "closed", "reopened":
		docSnap, err := domainRef.Get(ctx)
		if err != nil {
			return err
		}

		var domain map[string]interface{}
		if err := docSnap.DataTo(&domain); err != nil {
			return err
		}

		topics, _ := domain["topics"].([]interface{})
		updated := replaceTopic(topics, topic)

		_, err = domainRef.Update(ctx, []firestore.Update{
			{Path: "topics", Value: updated},
		})
		return err
	}

	return nil
}

func (gw *GithubWatcher) handlePull(ctx context.Context, e *github.PullRequestEvent) error {

	repoName := e.GetRepo().GetFullName()
	if repoName == "" {
		return nil
	}

	domainID := findDomainIDByRepo(repoName, gw.cfg.RepoDomainMapping)
	if domainID == "" {
		return nil
	}

	parts := strings.Split(repoName, "/")
	if len(parts) != 2 {
		return fmt.Errorf("invalid repo name: %s", repoName)
	}
	owner, repo := parts[0], parts[1]

	var fullNote string
	commits, _, err := gw.githubClient.PullRequests.ListCommits(ctx, owner, repo, e.PullRequest.GetNumber(), nil)
	if err != nil {
		fullNote = e.PullRequest.GetBody()
	} else {
		var commitMessages string
		for _, c := range commits {
			commitMessages += c.Commit.GetMessage() + "\n"
		}
		fullNote = e.PullRequest.GetBody() + "\n---\n" + commitMessages
	}

	status := "open"
	if e.PullRequest.GetMerged() {
		status = "merged"
	} else if e.PullRequest.GetState() == "closed" {
		status = "closed"
	}

	var closedAt *time.Time
	if e.PullRequest.MergedAt != nil {
		t := e.PullRequest.MergedAt.Time
		closedAt = &t
	} else if e.PullRequest.ClosedAt != nil {
		t := e.PullRequest.ClosedAt.Time
		closedAt = &t
	}

	issueNumber := extractTopicID(
		e.PullRequest.GetBody(),
		e.PullRequest.GetTitle(),
		e.PullRequest.GetHead().GetRef(),
	)

	topicID := ""
	if issueNumber != "" {
		topicID = repoName + "-" + issueNumber
	}

	pull := map[string]interface{}{
		"id":         e.PullRequest.GetNodeID(),
		"domainId":   domainID,
		"topicId":    topicID,
		"prNumber":   e.PullRequest.GetNumber(),
		"title":      e.PullRequest.GetTitle(),
		"status":     status,
		"fullNote":   fullNote,
		"url":        e.PullRequest.GetHTMLURL(),
		"repository": repoName,
		"createdAt":  e.PullRequest.GetCreatedAt().Time,
		"closedAt":   closedAt,
		"updatedAt":  firestore.ServerTimestamp,
	}

	_, err = gw.firestoreClient.Collection("githubPulls").Doc(e.PullRequest.GetNodeID()).Set(ctx, pull)
	return err
}

func findDomainIDByRepo(repoFullName string, mappings []config.RepoDomainMapping) string {
	for _, m := range mappings {
		if m.Repo == repoFullName {
			return m.DomainID
		}
	}
	return ""
}

func replaceTopic(topics []interface{}, topic map[string]interface{}) []interface{} {
	for i, t := range topics {
		tp, _ := t.(map[string]interface{})
		if tp["id"] == topic["id"] {
			topics[i] = topic
			return topics
		}
	}
	return append(topics, topic)
}

func extractTitle(title string) string {
	re := regexp.MustCompile(`^\[.+?\]\s*`)
	return re.ReplaceAllString(title, "")
}

func extractTopicID(body, title, branch string) string {
	re := regexp.MustCompile(`(?i)closes\s+#(\d+)`)
	if m := re.FindStringSubmatch(body); len(m) >= 2 {
		return m[1]
	}

	re = regexp.MustCompile(`\[#(\d+)\]`)
	if m := re.FindStringSubmatch(title); len(m) >= 2 {
		return m[1]
	}

	re = regexp.MustCompile(`^[^/]+/(\d+)`)
	if m := re.FindStringSubmatch(branch); len(m) >= 2 {
		return m[1]
	}

	return ""
}
