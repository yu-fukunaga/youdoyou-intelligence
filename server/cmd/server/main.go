package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"cloud.google.com/go/firestore"
	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"
	"github.com/firebase/genkit/go/plugins/googlegenai"
	"github.com/firebase/genkit/go/plugins/ollama"
	"github.com/firebase/genkit/go/plugins/server"
	"github.com/go-chi/chi/v5"

	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/clients"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/config"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/handler"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/repository"
	"github.com/yu-fukunaga/youdoyou-intelligence/server/internal/usecase"
)

func main() {
	ctx := context.Background()
	cfg := config.LoadConfig()

	// --- 1. Init Plugins & Clients ---

	var g *genkit.Genkit
	var localModel ai.ModelRef

	if cfg.IsDev() {
		log.Printf("ENV=development: using local Ollama model %q at %s\n", cfg.OllamaModel, cfg.OllamaServerAddress)
		ollamaPlugin := &ollama.Ollama{ServerAddress: cfg.OllamaServerAddress}
		g = genkit.Init(ctx, genkit.WithPlugins(ollamaPlugin))

		model := ollamaPlugin.DefineModel(g,
			ollama.ModelDefinition{Name: cfg.OllamaModel, Type: "chat"},
			&ai.ModelOptions{Supports: &ai.ModelSupports{Multiturn: true}},
		)
		localModel = ai.NewModelRef(model.Name(), nil)
	} else {
		g = genkit.Init(ctx,
			genkit.WithPlugins(&googlegenai.GoogleAI{}),
			genkit.WithDefaultModel("googleai/gemini-3.5-flash"),
		)
	}

	firestoreClient, err := firestore.NewClient(ctx, cfg.ProjectID)
	if err != nil {
		log.Fatal(err)
	}

	defer func() {
		if err := firestoreClient.Close(); err != nil {
			log.Fatal(err)
		}
	}()

	// --- 2. Dependency Injection (DI) ---

	pingFlow := genkit.DefineFlow(g, "pingFlow", func(ctx context.Context, _ any) (string, error) {
		return "pong", nil
	})

	llmPingUsecase := usecase.NewLlmPingUsecase(g, localModel)
	llmPingFlow := genkit.DefineFlow(g, "llmPingFlow", llmPingUsecase.Execute)

	pullRequestRepo := repository.NewFirestorePullRequestRepository(firestoreClient)

	// --- 3. Routes ---

	r := chi.NewRouter()
	r.Route("/v1", func(r chi.Router) {
		r.Get("/ping", genkit.Handler(pingFlow))
		r.Post("/llm-ping", genkit.Handler(llmPingFlow))

		if cfg.GitHubAppID == "" {
			log.Println("GITHUB_WATCHER_APP_ID not set, GitHub webhook integration disabled")
		} else {
			githubClient, err := clients.NewGithubClient(cfg.GitHubAppID, cfg.GitHubInstallationID, cfg.GitHubPrivateKey)
			if err != nil {
				log.Fatal(err)
			}

			var repoDomainMap []usecase.RepoDomainMapping
			if err := json.Unmarshal([]byte(cfg.RepoDomainMapStr), &repoDomainMap); err != nil {
				log.Fatalf("failed to parse REPO_DOMAIN_MAP: %v", err)
			}

			githubWatcherUsecase := usecase.NewGithubWatcherUsecase(
				pullRequestRepo,
				githubClient,
				repoDomainMap,
			)
			githubWebhookFlow := genkit.DefineFlow(g, "githubWebhookFlow", githubWatcherUsecase.Execute)

			r.Post("/webhook/github", func(w http.ResponseWriter, r *http.Request) {
				handler.HandleGithubWebhook(w, r, githubWebhookFlow.Run)
			})
		}
	})

	// --- 4. Start Server ---

	log.Printf("======= Starting Genkit server on :%s =======", cfg.Port)
	mux := http.NewServeMux()
	mux.Handle("/", r)
	if err := server.Start(ctx, ":"+cfg.Port, mux); err != nil {
		log.Fatal(err)
	}
}
