-include .env
export

DEPLOY_REGION := asia-northeast1

.PHONY: secrets

# Secret scan with gitleaks
gitleaks/all:
	@echo "Running gitleaks for commits history..."
	@gitleaks git . --no-banner
	@echo "---"
	@$(MAKE) gitleaks

gitleaks:
	@echo "Running gitleaks for staged changes..."
	@gitleaks git --pre-commit --staged --verbose --no-banner

.PHONY: pre-commit/install
pre-commit/install:
	pre-commit install

.PHONY: pre-commit/format
pre-commit/format:
	@pre-commit run trailing-whitespace --all-files || true
	@pre-commit run end-of-file-fixer --all-files || true

pre-commit/run:
	pre-commit run --all-files

.PHONY: backend/deploy/dev
backend/deploy/dev:
	$(MAKE) -C backend deploy/dev SRC_DIR=./backend
