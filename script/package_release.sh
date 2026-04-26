#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TimeMenubar"
PROJECT="TimeMenubar.xcodeproj"
SCHEME="TimeMenubar"
CONFIGURATION="Release"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME.app.zip"

cd "$ROOT_DIR"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

/usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "$ZIP_PATH"
