package config

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Env                  string `envconfig:"ENV" default:"production"`
	GitHubAppID          string `envconfig:"GITHUB_WATCHER_APP_ID" required:"true"`
	GitHubInstallationID string `envconfig:"GITHUB_WATCHER_INSTALLATION_ID" required:"true"`
	GitHubPrivateKey     string `envconfig:"GITHUB_WATCHER_PRIVATE_KEY" required:"true"`
	GitHubWebhookSecret  string `envconfig:"GITHUB_WATCHER_WEBHOOK_SECRET" required:"true"`
	RepoDomainMapStr     string `envconfig:"REPO_DOMAIN_MAP" required:"true"`
	RepoDomainMapping    []RepoDomainMapping
}

type RepoDomainMapping struct {
	Repo     string `json:"repo"`
	DomainID string `json:"domain_id"`
}

var (
	configInstance *Config
	once           sync.Once
)

func LoadGithubWatcherConfig() *Config {
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

		var mappings []RepoDomainMapping
		if err := json.Unmarshal([]byte(cfg.RepoDomainMapStr), &mappings); err != nil {
			log.Fatalf("failed to parse REPO_DOMAIN_MAP: %v", err)
		}
		cfg.RepoDomainMapping = mappings
		configInstance = &cfg
	})
	return configInstance
}

func (cfg *Config) IsDevEnv() bool {
	return cfg.Env == "development"
}

func (cfg *Config) IsLocalEnv() bool {
	return cfg.Env == "local"
}
