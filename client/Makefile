# Variables
SWIFT_FORMAT := swift-format
SIMULATOR := iPhone 17 Pro
SIMULATOR_OS := 26.5

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

# Test commands (xcodebuild)
.PHONY: test
test: test-ios test-macos
	@echo "✅ All tests completed!"

.PHONY: test-ios
test-ios:
	@echo "== test: iOS Simulator =="
	@rm -rf /tmp/test-ios.xcresult
	@xcodebuild test \
		-project YouDoYouClient.xcodeproj \
		-scheme YouDoYou_iOS_Test \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR),OS=$(SIMULATOR_OS)' \
		-enableCodeCoverage YES \
		-resultBundlePath /tmp/test-ios.xcresult; \
	TEST_EXIT=$$?; \
	$(MAKE) coverage; \
	exit $$TEST_EXIT

.PHONY: coverage
coverage:
	@if [ -d /tmp/test-ios.xcresult ]; then \
		xcrun xccov view --report --files-for-target AppCore /tmp/test-ios.xcresult; \
	else \
		echo "No coverage data found. Run 'make test-ios' first."; \
	fi

.PHONY: test-macos
test-macos:
	@echo "== test: macOS =="
# 	xcodebuild test \
# 		-project YouDoYouClient.xcodeproj \
# 		-scheme YouDoYou_macOS_Test \
# 		-destination 'platform=macOS'

.PHONY: secure
secure: gitleaks semgrep
	@echo "Security checks completed!"

.PHONY: gitleaks
gitleaks:
	@gitleaks git --pre-commit --staged --no-banner || (echo ""; echo "❌ gitleaks: secrets detected!"; echo ""; exit 1)

.PHONY: semgrep
semgrep:
	semgrep --config p/swift --config p/security-audit --config p/ci --error --quiet .
