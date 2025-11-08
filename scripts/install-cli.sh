#!/bin/bash

# Installation script for Dart Cloud CLI
# This script compiles and installs the CLI tool globally

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_DIR="$PROJECT_ROOT/dart_cloud_cli"
INSTALL_DIR="${HOME}/.local/bin"
BINARY_NAME="dart_cloud"

# Functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install Dart Cloud CLI globally on your system

OPTIONS:
    -h, --help              Show this help message
    -u, --uninstall         Uninstall the CLI
    --dev                   Install in development mode (uses dart run)
    --path <path>           Custom installation directory (default: ~/.local/bin)

EXAMPLES:
    $0                      # Install CLI globally
    $0 --uninstall          # Uninstall CLI
    $0 --path /usr/local/bin  # Install to custom directory

EOF
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    if ! command -v dart &> /dev/null; then
        print_error "Dart SDK is not installed"
        echo ""
        echo "Install Dart SDK:"
        echo "  macOS:   brew install dart-sdk"
        echo "  Linux:   https://dart.dev/get-dart"
        echo "  Windows: https://dart.dev/get-dart"
        exit 1
    fi
    
    local dart_version=$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_success "Dart SDK found (version $dart_version)"
}

compile_cli() {
    print_header "Compiling CLI"
    
    cd "$CLI_DIR"
    
    print_info "Getting dependencies..."
    dart pub get
    
    print_info "Compiling to native executable..."
    dart compile exe bin/main.dart -o "$BINARY_NAME"
    
    print_success "CLI compiled successfully"
}

install_cli() {
    print_header "Installing CLI"
    
    # Create install directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Creating installation directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Copy binary to install directory
    print_info "Installing $BINARY_NAME to $INSTALL_DIR..."
    cp "$CLI_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    
    print_success "CLI installed to $INSTALL_DIR/$BINARY_NAME"
    
    # Check if install directory is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_warning "Installation directory is not in your PATH"
        echo ""
        echo "Add the following line to your shell configuration file:"
        echo "  (~/.bashrc, ~/.zshrc, ~/.bash_profile, or ~/.profile)"
        echo ""
        echo -e "${YELLOW}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
        echo ""
        echo "Then reload your shell:"
        echo -e "${YELLOW}source ~/.zshrc${NC}  # or your shell config file"
        echo ""
    else
        print_success "Installation directory is in your PATH"
    fi
}

install_dev_mode() {
    print_header "Installing in Development Mode"
    
    cd "$CLI_DIR"
    
    print_info "Getting dependencies..."
    dart pub get
    
    print_info "Activating CLI globally..."
    dart pub global activate --source path .
    
    print_success "CLI activated in development mode"
    
    # Check if pub cache is in PATH
    local pub_cache_bin="$HOME/.pub-cache/bin"
    if [[ ":$PATH:" != *":$pub_cache_bin:"* ]]; then
        print_warning "Dart pub cache bin directory is not in your PATH"
        echo ""
        echo "Add the following line to your shell configuration file:"
        echo ""
        echo -e "${YELLOW}export PATH=\"\$PATH:$pub_cache_bin\"${NC}"
        echo ""
    fi
}

uninstall_cli() {
    print_header "Uninstalling CLI"
    
    # Remove binary
    if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        print_info "Removing $INSTALL_DIR/$BINARY_NAME..."
        rm "$INSTALL_DIR/$BINARY_NAME"
        print_success "Binary removed"
    else
        print_info "Binary not found at $INSTALL_DIR/$BINARY_NAME"
    fi
    
    # Deactivate global activation
    if dart pub global list | grep -q "dart_cloud_cli"; then
        print_info "Deactivating global package..."
        dart pub global deactivate dart_cloud_cli
        print_success "Global package deactivated"
    fi
    
    # Remove config directory
    local config_dir="$HOME/.dart_cloud"
    if [ -d "$config_dir" ]; then
        print_warning "Configuration directory found: $config_dir"
        read -p "Do you want to remove it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$config_dir"
            print_success "Configuration directory removed"
        fi
    fi
    
    print_success "CLI uninstalled successfully"
}

verify_installation() {
    print_header "Verifying Installation"
    
    if command -v "$BINARY_NAME" &> /dev/null; then
        print_success "CLI is accessible from PATH"
        echo ""
        print_info "Testing CLI..."
        "$BINARY_NAME" version
        echo ""
        print_success "Installation verified successfully!"
    else
        print_warning "CLI is not accessible from PATH"
        echo ""
        echo "You can run it directly from:"
        echo -e "${YELLOW}$INSTALL_DIR/$BINARY_NAME${NC}"
        echo ""
        echo "Or add $INSTALL_DIR to your PATH"
    fi
}

show_next_steps() {
    print_header "Next Steps"
    
    cat << EOF
${GREEN}Installation Complete!${NC}

Get started with these commands:

  1. Login to your account:
     ${YELLOW}$BINARY_NAME login${NC}

  2. Deploy a function:
     ${YELLOW}$BINARY_NAME deploy ./my_function${NC}

  3. List your functions:
     ${YELLOW}$BINARY_NAME list${NC}

  4. View function logs:
     ${YELLOW}$BINARY_NAME logs <function-id>${NC}

  5. Invoke a function:
     ${YELLOW}$BINARY_NAME invoke <function-id> --data '{"key": "value"}'${NC}

  6. Logout:
     ${YELLOW}$BINARY_NAME logout${NC}

For more help:
  ${YELLOW}$BINARY_NAME --help${NC}

Configuration is stored in: ${BLUE}~/.dart_cloud/config.json${NC}

EOF
}

# Parse arguments
UNINSTALL=false
DEV_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -u|--uninstall)
            UNINSTALL=true
            ;;
        --dev)
            DEV_MODE=true
            ;;
        --path)
            INSTALL_DIR="$2"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# Main execution
main() {
    print_header "Dart Cloud CLI Installation"
    
    check_dependencies
    
    if [ "$UNINSTALL" = true ]; then
        uninstall_cli
        exit 0
    fi
    
    if [ "$DEV_MODE" = true ]; then
        install_dev_mode
    else
        compile_cli
        install_cli
        verify_installation
    fi
    
    show_next_steps
}

# Run main function
main
