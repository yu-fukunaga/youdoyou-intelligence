#!/bin/bash
# scripts/create_release_tag.sh

set -euo pipefail

COMPONENT=${1:?"Error: COMPONENT is required"}

LATEST=$(git tag --list "${COMPONENT}/v*" --sort=-version:refname | head -n 1)

if [ -z "$LATEST" ]; then
  NEW_TAG="${COMPONENT}/v0.1.0"
else
  VERSION=${LATEST#"${COMPONENT}/v"}

  IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

  # squash mergeのコミットメッセージからPR番号を抽出してブランチ名を取得
  PR_NUMBER=$(git log -1 --pretty=%B | head -n 1 | grep -oE '#[0-9]+' | tr -d '#' || true)

  BRANCH=""
  if [ -n "$PR_NUMBER" ]; then
    BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName' || true)
  fi

  if [[ $BRANCH == feature/* ]]; then
    MINOR=$((MINOR + 1))
    PATCH=0
  else
    PATCH=$((PATCH + 1))
  fi

  NEW_TAG="${COMPONENT}/v${MAJOR}.${MINOR}.${PATCH}"
fi

echo "Creating tag: $NEW_TAG"
git tag "$NEW_TAG"
git push origin "$NEW_TAG"

gh release create "$NEW_TAG" \
  --title "$NEW_TAG" \
  --generate-notes
