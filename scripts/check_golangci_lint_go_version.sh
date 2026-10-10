#!/usr/bin/env bash
set -euo pipefail

# Warn when the active Go toolchain is newer than the Go golangci-lint itself
# was built with, since golangci-lint can't analyze stdlib source gated to a
# newer Go version than its own build (see docs/task-notes/done/0030).

golangci_lint_bin="${1:-./bin/golangci-lint}"

build_version=$("$golangci_lint_bin" version 2>&1 | sed -n 's/.*built with \(go[0-9.]*\).*/\1/p')
active_version=$(go version | sed -n 's/^go version \(go[0-9.]*\).*/\1/p')

version_key() {
  echo "$1" | sed 's/^go//' | awk -F. '{ printf "%d%03d", $1, $2 }'
}

if [ "$(version_key "$active_version")" -gt "$(version_key "$build_version")" ]; then
  echo "⚠️  Active Go ($active_version) is newer than the Go golangci-lint was built with ($build_version)."
  echo "    golangci-lint may panic analyzing newer stdlib source."
  echo "    Run 'direnv allow' in this directory, or upgrade golangci-lint if this is expected."
fi
