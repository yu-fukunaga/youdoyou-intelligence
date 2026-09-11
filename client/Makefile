# Variables
SWIFT_FORMAT := swift-format

# Commands
.PHONY: format
format: swift-format precommit-format
	@echo "All formats applied."

.PHONY: swift-format
swift-format:
	@$(SWIFT_FORMAT) format --recursive --in-place .

.PHONY: precommit-format
precommit-format:
	@pre-commit run trailing-whitespace --all-files | grep "Fixing" || true;
	@pre-commit run end-of-file-fixer --all-files | grep "Fixing" || true;
	@pre-commit run check-yaml --all-files | grep "Fixing" || true;
	@pre-commit run check-added-large-files --all-files | grep "Fixing" || true;
	@pre-commit run check-merge-conflict --all-files | grep "Fixing" || true;

.PHONY: lint
lint:
	$(SWIFT_FORMAT) lint --recursive .

.PHONY: ci-lint
ci-lint:
	$(SWIFT_FORMAT) lint --recursive --strict .

# Build commands
.PHONY: build-package
build-package: build-package-ios build-package-macos
	@echo "✅ All package-builds completed!"

.PHONY: build-package-ios
build-package-ios:
	@echo "== build: iOS =="
	@cd Packages/YouDoYou && swift build --triple arm64-apple-ios26.0-simulator --sdk $$(xcrun --sdk iphonesimulator --show-sdk-path)

.PHONY: build-package-macos
build-package-macos:
	@echo "== build: macOS =="
	@cd Packages/YouDoYou && swift build --triple arm64-apple-macosx26.0 --sdk $$(xcrun --sdk macosx --show-sdk-path)

.PHONY: clean-package
clean-package:
	@echo "== package clean =="
	@cd Packages/YouDoYou && swift package clean

.PHONY: secure
secure: gitleaks semgrep
	@echo "Security checks completed!"

.PHONY: gitleaks
gitleaks:
	@gitleaks git --pre-commit --staged --no-banner || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)

.PHONY: semgrep
semgrep:
	semgrep --config p/swift --config p/security-audit --config p/ci --error --quiet .
