.PHONY: build run seed check test clean setup lint secure semgrep secrets create-message

PWD := $(shell pwd)
DEPLOY_REGION := asia-northeast1


# Setup dependencies
setup:
	@echo "Setting up..."
	$(MAKE) install-tools
	go mod tidy

install-tools:
	echo "Installing tools..."
	go get -tool github.com/air-verse/air@latest
	go get -tool golang.org/x/vuln/cmd/govulncheck@latest
	@if [ "$(SKIP_GOLANGCI_LINT)" != "1" ]; then \
		curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b $(PWD)/bin v2.12.2; \
	fi

# Run the server
dev:
	@$(MAKE) -j 2 dev-server dev-ui

dev-server:
	@echo "Running server with air hot reload (ENV=dev)..."
	GENKIT_ENV=dev GCP_PROJECT_ID=$(GCP_PROJECT_ID_PREFIX)-dev go tool air

dev-ui:
	@echo "Starting Genkit Developer UI..."
	GENKIT_ENV=dev genkit start

ping:
	@PORT_NUM=$${PORT:-8081}; \
	curl -s http://localhost:$$PORT_NUM/v1/ping | jq .;

ping/cloud/dev:
	@URL=$$(gcloud run services describe server \
		--region=$(DEPLOY_REGION) \
		--project=$(GCP_PROJECT_ID_PREFIX)-dev \
		--format="value(status.url)"); \
	curl -s -H "Authorization: Bearer $$(gcloud auth print-identity-token)" \
		$$URL/v1/ping;

# Build all binaries
build:
	@echo "Building..."
	go build -o bin/server ./cmd/server

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Run linter
lint:
	@echo "Running linter..."
	$(PWD)/bin/golangci-lint run --enable=gosec

# Format code
format:
	@echo "Formatting code..."
	go fmt ./...
	$(PWD)/bin/golangci-lint run --fix

vulncheck:
	@go tool govulncheck ./...

# Secret scan with gitleaks
gitleaks:
	@echo "Running gitleaks..."
	gitleaks detect --source .

# All security checks
DIVIDER := "-----------------------------"
secure:
	@echo $(DIVIDER)
	@echo "[1/2] gitleaks"
	@echo $(DIVIDER)
	@$(MAKE) gitleaks || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)
	@echo $(DIVIDER)
	@echo "[2/2] govulncheck"
	@echo $(DIVIDER)
	@$(MAKE) vulncheck|| (echo ""; echo "❌ govulncheck failed!"; echo ""; exit 1)
	@echo "✅ All checks passed!"


# ---------------------------------------------------
# Deploy
# ---------------------------------------------------

# Deploy to dev (current HEAD)
# Usage: make deploy/dev
deploy/dev:
	gcloud run deploy server \
		--flags-file=../deploy-config/server/deploy-config.dev.yaml

# Deploy to prod (latest tag)
# Usage: make deploy/prod
deploy/prod:
	@LATEST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null); \
	if [ -z "$$LATEST_TAG" ]; then \
		echo "Error: No tags found."; \
		exit 1; \
	fi; \
	$(MAKE) deploy/prod/$$LATEST_TAG

# Deploy to prod (specific tag)
# Usage: make deploy/prod/v1.0.0
deploy/prod/%:
	@REVISION_SUFFIX=$$(echo "$*" | sed 's/^v//' | tr '.' '-' | tr '[:upper:]' '[:lower:]'); \
	CURRENT_BRANCH=$$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD); \
	git checkout "$*"; \
	gcloud run deploy server \
		--flags-file=../deploy-config/server/deploy-config.prod.yaml \
		--revision-suffix=$$REVISION_SUFFIX; \
	git checkout $$CURRENT_BRANCH
