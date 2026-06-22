.PHONY: build run seed check test clean setup lint secure semgrep secrets create-message upgrade-tools

PWD := $(shell pwd)
DEPLOY_REGION := asia-northeast1


# Setup dependencies
setup:
	@echo "Setting up..."
	$(MAKE) install-tools
	go mod tidy

install-tools:
	echo "Installing tools..."
	@if [ "$(SKIP_GOLANGCI_LINT)" != "1" ]; then \
		curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b $(PWD)/bin v2.12.2; \
	fi

# Bump pinned tool versions in go.mod (run manually, then commit the diff)
upgrade-tools:
	go get -tool github.com/air-verse/air@latest
	go get -tool golang.org/x/vuln/cmd/govulncheck@latest
	go mod tidy

# Run the server
dev:
	@$(MAKE) -j 2 dev-server dev-ui

dev-server:
	@echo "Running server with air hot reload (ENV=dev)..."
	GENKIT_ENV=dev GCP_PROJECT_ID=$(GCP_PROJECT_ID_PREFIX)-dev go tool air

dev-ui:
	@echo "Starting Genkit Developer UI..."
	GENKIT_ENV=dev genkit start

seed:
	@echo "Seeding Firestore emulator..."
	GCP_PROJECT_ID=firebase-emulator go run ./cmd/seed -dir=./cmd/seed/collection_data

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

# Temporarily allow external traffic for local testing (internal-only by default)
ingress/dev/open:
	gcloud run services update server \
		--region=$(DEPLOY_REGION) \
		--project=$(GCP_PROJECT_ID_PREFIX)-dev \
		--ingress=all

ingress/dev/close:
	gcloud run services update server \
		--region=$(DEPLOY_REGION) \
		--project=$(GCP_PROJECT_ID_PREFIX)-dev \
		--ingress=internal

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
	gcloud builds submit --config=cloudbuild.yaml --project=$(GCP_PROJECT_ID_PREFIX)-dev .
