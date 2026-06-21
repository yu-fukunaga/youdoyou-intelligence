-include .env
export

# version
.PHONY: version/gen
version/gen:
	@git describe --tags --match "gen/v*" --abbrev=0 2>/dev/null || echo "no gen version"

.PHONY: version/seed
version/seed:
	@git describe --tags --match "seed/v*" --abbrev=0 2>/dev/null || echo "no seed version"

# tools
.PHONY: gen-work
gen-work: MODULES := ./generator ./seed
gen-work:
	@if [ ! -f go.work ]; then go work init $(MODULES); \
	else go work use $(MODULES) 2>/dev/null || true; fi

.PHONY: gen
gen:
	@$(MAKE) --no-print-directory gen/go
	@echo "Done."

.PHONY: gen/go
gen/go:
	cd generator && go run ./cmd/gen/main.go -target=go -schema=../schema/firestore.yaml

.PHONY: gen/swift
gen/swift:
	cd generator && go run ./cmd/gen/main.go -target=swift -schema=../schema/firestore.yaml

.PHONY: emulators
emulators:
	@echo "Starting emulators..."
	cd emulator && firebase emulators:start

.PHONY: seed
seed:
	@echo "Seeding data..."
	cd seed && go run . --dir=collection_data/
	@echo "Done."

# setup
.PHONY: setup
setup: setup/generator setup/seed

.PHONY: setup/generator
setup/generator:
	cd generator && go mod download && go mod tidy

.PHONY: setup/seed
setup/seed:
	cd seed && go mod download && go mod tidy

.PHONY: setup/hooks
setup/hooks:
	pre-commit install

# test
.PHONY: test
test: test/generator test/seed

.PHONY: test/generator
test/generator:
	cd generator && go test -v ./...

.PHONY: test/seed
test/seed:
	cd seed && go test -v ./...

# lint
.PHONY: lint
lint: lint/generator lint/seed lint/schema

.PHONY: lint/generator
lint/generator:
	cd generator && go tool golangci-lint run ./...

.PHONY: lint/seed
lint/seed:
	cd seed && go tool golangci-lint run ./...

.PHONY: lint/schema
lint/schema:
	cd generator && go run ./cmd/lint-schema/main.go

# format
.PHONY: format
format: format/generator format/seed
	pre-commit run trailing-whitespace --all-files || true
	pre-commit run end-of-file-fixer --all-files || true

.PHONY: format/generator
format/generator:
	cd generator && go fmt ./...
	cd generator && GOWORK=off go tool golangci-lint run --fix

.PHONY: format/seed
format/seed:
	cd seed && go fmt ./...
	cd seed && GOWORK=off go tool golangci-lint run --fix

# secure
.PHONY: secrets
secrets:
	@echo "Running gitleaks..."
	gitleaks detect --source .

.PHONY: semgrep
semgrep:
	@echo "Running semgrep..."
	semgrep --config auto . --quiet

.PHONY: secure
secure: secrets semgrep
	@echo "Security checks completed!"

.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files
