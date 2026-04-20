#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/Flow Bell.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE="$BUILD_DIR/module-cache"
SWIFTPM_CACHE="$BUILD_DIR/swiftpm-cache"
SWIFTPM_CONFIG="$BUILD_DIR/swiftpm-config"
SWIFTPM_SECURITY="$BUILD_DIR/swiftpm-security"
SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX14.4.sdk"
MASTER_ICON="$ROOT_DIR/Resources/AppIcon-master.png"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/Resources/AppIcon.icns"
ZIP_PATH="$DIST_DIR/Flow.Bell.zip"
INSTALLER_PATH="$DIST_DIR/Install Flow Bell.command"

mkdir -p "$DIST_DIR" "$MODULE_CACHE" "$SWIFTPM_CACHE" "$SWIFTPM_CONFIG" "$SWIFTPM_SECURITY"
rm -rf "$APP_DIR" "$ZIP_PATH" "$ICONSET_DIR"

if [[ -d "$SDK_PATH" ]]; then
export SDKROOT="$SDK_PATH"
fi
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"

run_swift() {
  local stdout_file stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  if swift "$@" \
    --cache-path "$SWIFTPM_CACHE" \
    --config-path "$SWIFTPM_CONFIG" \
    --security-path "$SWIFTPM_SECURITY" \
    --manifest-cache local \
    > "$stdout_file" \
    2> "$stderr_file"; then
    cat "$stdout_file"
    grep -v \
      -e "warning: could not determine XCTest paths" \
      -e "xcrun: error: unable to lookup item 'PlatformPath' from command line tools installation" \
      -e "xcrun: error: unable to lookup item 'PlatformPath' in SDK '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk'" \
      "$stderr_file" >&2 || true
  else
    cat "$stdout_file"
    cat "$stderr_file" >&2
    rm -f "$stdout_file" "$stderr_file"
    return 1
  fi

  rm -f "$stdout_file" "$stderr_file"
}

swift "$ROOT_DIR/Scripts/generate_icon.swift" "$MASTER_ICON"

mkdir -p "$ICONSET_DIR"
cp "$MASTER_ICON" "$ICONSET_DIR/icon_512x512@2x.png"
sips -z 16 16 "$MASTER_ICON" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_ICON" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_ICON" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_ICON" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_ICON" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

run_swift build -c release

BIN_PATH="$BUILD_DIR/$(uname -m)-apple-macosx/release"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_PATH/flow-random-bell-mac" "$MACOS_DIR/Flow Bell"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICNS_PATH" "$RESOURCES_DIR/AppIcon.icns"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

cat > "$INSTALLER_PATH" <<'EOF'
#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Flow Bell.app"
SOURCE_APP="$SCRIPT_DIR/$APP_NAME"
TARGET_DIR="/Applications"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Missing app bundle: $SOURCE_APP"
  exit 1
fi

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR/$APP_NAME"
cp -R "$SOURCE_APP" "$TARGET_DIR/$APP_NAME"

echo "Installed to:"
echo "$TARGET_DIR/$APP_NAME"
EOF

chmod +x "$INSTALLER_PATH"

echo "Built app bundle:"
echo "$APP_DIR"
echo "Installer:"
echo "$INSTALLER_PATH"
echo "Zip package:"
echo "$ZIP_PATH"
