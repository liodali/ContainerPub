#!/bin/bash

set -e

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.dart-cloud-deploy"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Uninstalling dart_cloud_deploy CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Remove binary
if [ -f "$INSTALL_DIR/dart_cloud_deploy" ]; then
    echo "▸ Removing binary..."
    rm "$INSTALL_DIR/dart_cloud_deploy"
    echo "✓ Binary removed"
else
    echo "ℹ Binary not found at $INSTALL_DIR/dart_cloud_deploy"
fi

# Ask about config directory
if [ -d "$CONFIG_DIR" ]; then
    echo ""
    read -p "Remove config directory $CONFIG_DIR? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "✓ Config directory removed"
    else
        echo "ℹ Config directory preserved"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Uninstallation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
