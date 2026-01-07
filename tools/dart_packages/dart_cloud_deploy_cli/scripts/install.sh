#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Default install location
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.dart-cloud-deploy"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing dart_cloud_deploy CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect OS and architecture
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
        echo "✗ Unsupported OS: $OS"
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
        echo "✗ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BINARY_NAME="dart_cloud_deploy-$PLATFORM-$ARCH_NAME"
BINARY_PATH="$BUILD_DIR/$BINARY_NAME"

# Check if binary exists, if not try to build it
if [ ! -f "$BINARY_PATH" ]; then
    echo "▸ Binary not found, building..."
    "$SCRIPT_DIR/build.sh"
fi

# Create install directory if it doesn't exist
echo "▸ Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Create config directory
echo "▸ Creating config directory: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# Copy binary
echo "▸ Installing binary..."
cp "$BINARY_PATH" "$INSTALL_DIR/dart_cloud_deploy"
chmod +x "$INSTALL_DIR/dart_cloud_deploy"

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠ $INSTALL_DIR is not in your PATH"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then reload your shell:"
    echo "  source ~/.zshrc  # or ~/.bashrc"
    echo ""
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Binary installed to: $INSTALL_DIR/dart_cloud_deploy"
echo "Config directory: $CONFIG_DIR"
echo ""
echo "Run 'dart_cloud_deploy --help' to get started"
