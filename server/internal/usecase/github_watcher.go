package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"

	"github.com/google/go-github/v72/github"

	schema "github.com/yu-fukunaga/youdoyou-intelligence/gen-go/schema"
)

var (
	reBodyCloses = regexp.MustCompile(`(?i)closes\s+#(\d+)`)
	reTitleIssue = regexp.MustCompile(`\[#(\d+)\]`)
	reBranchNum  = regexp.MustCompile(`^[^/]+/(\d+)`)
)

type RepoDomainMapping struct {
	Repo     string `json:"repo"`
	DomainID string `json:"domain_id"`
}

type GithubWatcherUsecase interface {
	Execute(ctx context.Context, input *GithubWebhookInput) (string, error)
}

type GithubWebhookInput struct {
	EventType string          `json:"eventType"`
	Payload   json.RawMessage `json:"payload"`
}

type githubWatcherUsecase struct {
	pullRepo      PullRequestRepository
	githubClient  GithubAPIClient
	repoDomainMap []RepoDomainMapping
}

func NewGithubWatcherUsecase(
	pullRepo PullRequestRepository,
	githubClient GithubAPIClient,
	repoDomainMap []RepoDomainMapping,
) GithubWatcherUsecase {
	return &githubWatcherUsecase{
		pullRepo:      pullRepo,
		githubClient:  githubClient,
		repoDomainMap: repoDomainMap,
	}
}

func (u *githubWatcherUsecase) Execute(ctx context.Context, input *GithubWebhookInput) (string, error) {
	event, err := github.ParseWebHook(input.EventType, input.Payload)
	if err != nil {
		return "", fmt.Errorf("parse webhook: %w", err)
	}

	switch e := event.(type) {
	case *github.PullRequestEvent:
		if err := u.handlePull(ctx, e); err != nil {
			return "", err
		}
	}

	return "ok", nil
}

func (u *githubWatcherUsecase) handlePull(ctx context.Context, e *github.PullRequestEvent) error {
	repoName := e.GetRepo().GetFullName()
	if repoName == "" {
		return nil
	}

	domainID := u.findDomainID(repoName)
	if domainID == "" {
		return nil
	}

	parts := strings.Split(repoName, "/")
	if len(parts) != 2 {
		return fmt.Errorf("invalid repo name: %s", repoName)
	}
	owner, repo := parts[0], parts[1]

	var fullNote string
	messages, err := u.githubClient.ListCommitMessages(ctx, owner, repo, e.PullRequest.GetNumber())
	if err != nil {
		log.Printf("failed to list commit messages: %v", err)
		fullNote = e.PullRequest.GetBody()
	} else {
		fullNote = e.PullRequest.GetBody() + "\n---\n" + strings.Join(messages, "\n")
	}

	status := schema.GithubPullStatusOpen
	if e.PullRequest.GetMerged() {
		status = schema.GithubPullStatusMerged
	} else if e.PullRequest.GetState() == "closed" {
		status = schema.GithubPullStatusClosed
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

	pull := schema.GithubPull{
		ID:         e.PullRequest.GetNodeID(),
		DomainId:   domainID,
		TopicId:    topicID,
		PrNumber:   e.PullRequest.GetNumber(),
		Title:      e.PullRequest.GetTitle(),
		Status:     status,
		FullNote:   fullNote,
		Url:        e.PullRequest.GetHTMLURL(),
		Repository: repoName,
		CreatedAt:  e.PullRequest.GetCreatedAt().Time,
		ClosedAt:   closedAt,
	}

	if _, err := u.pullRepo.Save(ctx, pull); err != nil {
		return fmt.Errorf("save pull request: %w", err)
	}
	return nil
}

func (u *githubWatcherUsecase) findDomainID(repoFullName string) string {
	for _, m := range u.repoDomainMap {
		if m.Repo == repoFullName {
			return m.DomainID
		}
	}
	return ""
}

func extractTopicID(body, title, branch string) string {
	if m := reBodyCloses.FindStringSubmatch(body); len(m) >= 2 {
		return m[1]
	}
	if m := reTitleIssue.FindStringSubmatch(title); len(m) >= 2 {
		return m[1]
	}
	if m := reBranchNum.FindStringSubmatch(branch); len(m) >= 2 {
		return m[1]
	}
	return ""
}
