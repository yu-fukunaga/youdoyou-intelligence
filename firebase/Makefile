-include .env
export

.PHONY: emulators
emulators:
	@echo "Starting emulators..."
firebase emulators:start

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

upgrade-tools:
	go get -tool golang.org/x/vuln/cmd/govulncheck@latest
	go mod tidy

.PHONY: gen
gen:
	@$(MAKE) --no-print-directory gen/go
	@echo "Done."

.PHONY: gen/go
gen/go:
	go run ./generator/cmd/gen/main.go -target=go -schema=./schema/firestore.yaml

.PHONY: gen/swift
gen/swift:
	go run ./generator/cmd/gen/main.go -target=swift -schema=./schema/firestore.yaml

# test
.PHONY: test
test:
	go test -v ./...

# lint
.PHONY: lint
lint:
	@echo "Running linter..."
	$(PWD)/bin/golangci-lint run --enable=gosec
	@$(MAKE) lint/schema

.PHONY: lint/schema
lint/schema:
	go run ./generator/cmd/lint-schema/main.go

# format
.PHONY: format
format:
	@echo "Formatting code..."
	go fmt ./...
	$(PWD)/bin/golangci-lint run --fix

# secure
.PHONY: gitleaks
gitleaks:
	@gitleaks git --pre-commit --staged --no-banner || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)

vulncheck:
	@go tool govulncheck ./...

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
