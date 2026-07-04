.PHONY: dev build lint fmt secure

dev:
	hugo server

build:
	hugo --minify

lint:
	djlint . --check --lint

fmt:
	djlint . --reformat

.PHONY: gitleaks
gitleaks:
	@gitleaks git --pre-commit --staged --no-banner
semgrep:
	semgrep --config=.semgrep.yaml --quiet .

DIVIDER := "-----------------------------"
secure:
	@echo $(DIVIDER)
	@echo "[1/2] gitleaks"
	@echo $(DIVIDER)
	@$(MAKE) gitleaks || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)
	@echo $(DIVIDER)
	@echo "[2/2] semgrep"
	@echo $(DIVIDER)
	@$(MAKE) semgrep || (echo ""; echo "❌ semgrep failed!"; echo ""; exit 1)
	@echo "✅ All checks passed!"
