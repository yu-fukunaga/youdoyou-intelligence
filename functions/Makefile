PWD := $(shell pwd)
GCP_PROJECT_ID := $(GOOGLE_CLOUD_PROJECT)

.PHONY: setup
setup:
	@echo "Setting up..."
	$(MAKE) install-tools
	go mod tidy

.PHONY: install-tools
install-tools:
	echo "Installing tools..."
	go get -tool github.com/air-verse/air@latest
	go get -tool golang.org/x/vuln/cmd/govulncheck@latest
	@if [ "$(SKIP_GOLANGCI_LINT)" != "1" ]; then \
		curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b $(PWD)/bin v2.12.2; \
	fi

# Lint
.PHONY: lint
lint:
	@echo "Running linter..."
	$(PWD)/bin/golangci-lint run

.PHONY: format
format:
	@echo "Formatting code..."
	go fmt ./...
	$(PWD)/bin/golangci-lint run --fix

# Secure
DIVIDER := "-----------------------------"

.PHONY: vulncheck
vulncheck:
	@echo $(DIVIDER)
	@echo "[1/3] govulncheck"
	@echo $(DIVIDER)
	@go tool govulncheck ./... || (echo ""; echo "❌ govulncheck failed!"; echo ""; exit 1)

.PHONY: gosec
gosec:
	@echo $(DIVIDER)
	@echo "[2/3] gosec"
	@echo $(DIVIDER)
	@$(PWD)/bin/golangci-lint run --enable=gosec || (echo ""; echo "❌ gosec failed!"; echo ""; exit 1)

.PHONY: gitleaks
gitleaks:
	@echo $(DIVIDER)
	@echo "[3/3] gitleaks"
	@echo $(DIVIDER)
	@gitleaks git --pre-commit --staged --no-banner || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)

.PHONY: secure
secure: vulncheck gosec
	@if [ "$(SKIP_GITLEAKS)" != "1" ]; then \
		$(MAKE) gitleaks; \
	else \
		echo $(DIVIDER); \
		echo "[3/3] gitleaks"; \
		echo $(DIVIDER); \
		echo "  =>  SKIP"; \
	fi
	@echo ""
	@echo "✅ All checks passed!"
	@echo $(DIVIDER)
