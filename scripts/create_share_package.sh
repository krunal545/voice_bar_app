#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
STAGING="$DIST/voice_bar_app-windows-source"
ZIP="$DIST/voice_bar_app-windows-source.zip"

rm -rf "$STAGING" "$ZIP"
mkdir -p "$STAGING"

rsync -a \
  --exclude '.dart_tool' \
  --exclude 'build' \
  --exclude '.idea' \
  --exclude '.DS_Store' \
  --exclude 'dist' \
  --exclude '.git' \
  "$ROOT/" "$STAGING/"

(
  cd "$DIST"
  zip -r "$(basename "$ZIP")" "$(basename "$STAGING")" >/dev/null
)

echo "Created: $ZIP"
echo "Size: $(du -h "$ZIP" | awk '{print $1}')"
