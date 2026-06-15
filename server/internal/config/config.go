package config

import (
	"context"
	"log"
	"sync"

	"cloud.google.com/go/compute/metadata"
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Port      string `envconfig:"PORT" default:"8081"`
	ProjectID string `envconfig:"GCP_PROJECT_ID"`
	Env       string `envconfig:"ENV" default:"production"`

	GitHubAppID          string `envconfig:"GITHUB_WATCHER_APP_ID" required:"true"`
	GitHubInstallationID string `envconfig:"GITHUB_WATCHER_INSTALLATION_ID" required:"true"`
	GitHubPrivateKey     string `envconfig:"GITHUB_WATCHER_PRIVATE_KEY" required:"true"`
	RepoDomainMapStr     string `envconfig:"REPO_DOMAIN_MAP" required:"true"`
}

var (
	configInstance *Config
	once           sync.Once
)

func LoadConfig() *Config {
	once.Do(func() {
		if err := godotenv.Load(); err != nil {
			log.Println("No .env file found, relying on environment variables")
		} else {
			log.Println(".env file loaded")
		}

		var cfg Config
		if err := envconfig.Process("", &cfg); err != nil {
			log.Fatalf("Failed to load environment variables: %v", err)
		}

		if cfg.ProjectID == "" && metadata.OnGCE() {
			if id, err := metadata.ProjectIDWithContext(context.Background()); err == nil {
				cfg.ProjectID = id
				log.Printf("GCP_PROJECT_ID automatically detected from GCP: %s\n", cfg.ProjectID)
			}
		}
		if cfg.ProjectID == "" {
			log.Fatalf("Failed to load environment variables: required key GCP_PROJECT_ID missing value")
		}

		configInstance = &cfg
	})
	return configInstance
}
