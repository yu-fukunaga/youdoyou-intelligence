package config

import (
	"log"
	"sync"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Env                 string `envconfig:"ENV" default:"production"`
	GitHubWebhookSecret string `envconfig:"GITHUB_WATCHER_WEBHOOK_SECRET" required:"true"`
	ServerURL           string `envconfig:"SERVER_URL" required:"true"`
}

var (
	configInstance *Config
	once           sync.Once
)

func LoadGithubWebhookConfig() *Config {
	once.Do(func() {
		if err := godotenv.Load(); err != nil {
			log.Println("No .env file found, relying on environment variables")
		}

		var cfg Config
		if err := envconfig.Process("", &cfg); err != nil {
			log.Fatalf("Failed to load environment variables: %v", err)
		}
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
