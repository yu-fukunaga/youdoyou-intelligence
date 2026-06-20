# Variables
SWIFT_FORMAT := swift-format
SOURCE_DIRS := YouDoYouClient Packages/AppCore/Sources Packages/AppCore/Tests

# Commands
.PHONY: format
format: swift-format precommit-format
	@echo "All formats applied."

.PHONY: swift-format
swift-format:
	@$(SWIFT_FORMAT) format --recursive --in-place $(SOURCE_DIRS)

.PHONY: precommit-format
precommit-format:
	@pre-commit run trailing-whitespace --all-files | grep "Fixing" || true;
	@pre-commit run end-of-file-fixer --all-files | grep "Fixing" || true;
	@pre-commit run check-yaml --all-files | grep "Fixing" || true;
	@pre-commit run check-added-large-files --all-files | grep "Fixing" || true;
	@pre-commit run check-merge-conflict --all-files | grep "Fixing" || true;

.PHONY: lint
lint:
	$(SWIFT_FORMAT) lint --recursive $(SOURCE_DIRS)

.PHONY: ci-lint
ci-lint:
	$(SWIFT_FORMAT) lint --recursive --strict $(SOURCE_DIRS)

.PHONY: secure
secure: gitleaks/staged semgrep
	@echo "Security checks completed!"

.PHONY: gitleaks
gitleaks:
	gitleaks protect --verbose --redact

.PHONY: gitleaks/staged
gitleaks/staged:
	gitleaks protect --verbose --redact --staged

.PHONY: gitleaks/full
gitleaks/full:
	gitleaks detect --verbose --redact

.PHONY: semgrep
semgrep:
	semgrep --config p/swift --config p/security-audit --config p/ci --error --quiet .
