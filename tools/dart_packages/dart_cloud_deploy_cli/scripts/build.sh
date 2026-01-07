#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
VERSION=$(grep 'version:' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Building dart_cloud_deploy CLI v$VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        PLATFORM="macos"
        ;;
    Linux)
        PLATFORM="linux"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64)
        ARCH_NAME="x64"
        ;;
    arm64|aarch64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

OUTPUT_NAME="dart_cloud_deploy-$PLATFORM-$ARCH_NAME"

echo "Platform: $PLATFORM ($ARCH_NAME)"
echo "Output: $OUTPUT_NAME"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Navigate to project directory
cd "$PROJECT_DIR"

# Get dependencies
echo "▸ Fetching dependencies..."
dart pub get

# Compile to native executable
echo "▸ Compiling to native executable..."
dart compile exe bin/dart_cloud_deploy.dart -o "$BUILD_DIR/$OUTPUT_NAME"

# Create versioned archive
echo "▸ Creating archive..."
cd "$BUILD_DIR"
tar -czvf "$OUTPUT_NAME-v$VERSION.tar.gz" "$OUTPUT_NAME"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Build complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Executable: $BUILD_DIR/$OUTPUT_NAME"
echo "Archive: $BUILD_DIR/$OUTPUT_NAME-v$VERSION.tar.gz"
echo ""
echo "To install locally, run:"
echo "  ./scripts/install.sh"
