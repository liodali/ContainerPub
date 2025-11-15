#!/bin/bash

# Standalone installation script for Dart Cloud CLI
# Can be run with: curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="liodali/ContainerPub"
LATEST_RELEASE_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
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

detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
        linux*)
            PLATFORM="linux"
            BINARY_SUFFIX=""
            ;;
        darwin*)
            PLATFORM="macos"
            BINARY_SUFFIX=""
            case "$arch" in
                arm64|aarch64)
                    ARCH="arm64"
                    ;;
                *)
                    ARCH="x64"
                    ;;
            esac
            ;;
        msys*|mingw*|cygwin*)
            PLATFORM="windows"
            BINARY_SUFFIX=".exe"
            ARCH="x64"
            ;;
        *)
            print_error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
    
    if [ -z "$ARCH" ]; then
        case "$arch" in
            x86_64|amd64)
                ARCH="x64"
                ;;
            aarch64|arm64)
                ARCH="arm64"
                ;;
            *)
                print_error "Unsupported architecture: $arch"
                exit 1
                ;;
        esac
    fi
    
    BINARY_NAME_PLATFORM="${BINARY_NAME}-${PLATFORM}-${ARCH}${BINARY_SUFFIX}"
}

check_dependencies() {
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
}

download_and_install() {
    print_header "ContainerPub CLI Installation"
    
    detect_platform
    check_dependencies
    
    print_info "Platform: $PLATFORM-$ARCH"
    print_info "Binary: $BINARY_NAME_PLATFORM"
    
    # Fetch latest version
    print_info "Fetching latest release..."
    VERSION=$(curl -s "$LATEST_RELEASE_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$VERSION" ]; then
        print_error "Failed to fetch latest release version"
        exit 1
    fi
    
    print_success "Latest version: $VERSION"
    
    # Construct download URL
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${BINARY_NAME_PLATFORM}"
    CHECKSUM_URL="${DOWNLOAD_URL}.sha256"
    
    print_info "Downloading from: $DOWNLOAD_URL"
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download binary
    if ! curl -L -f -o "$BINARY_NAME" "$DOWNLOAD_URL"; then
        print_error "Failed to download binary"
        echo ""
        echo "URL: $DOWNLOAD_URL"
        echo ""
        echo "This might mean:"
        echo "  1. No release has been published yet"
        echo "  2. Your platform is not supported"
        echo "  3. Network connectivity issues"
        echo ""
        echo "Supported platforms:"
        echo "  - Linux x64"
        echo "  - macOS x64 (Intel)"
        echo "  - macOS ARM64 (Apple Silicon)"
        echo "  - Windows x64"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    print_success "Binary downloaded"
    
    # Download and verify checksum
    print_info "Downloading checksum..."
    if curl -L -f -o "${BINARY_NAME}.sha256" "$CHECKSUM_URL" 2>/dev/null; then
        print_info "Verifying checksum..."
        if command -v shasum &> /dev/null; then
            if shasum -a 256 -c "${BINARY_NAME}.sha256" 2>/dev/null; then
                print_success "Checksum verified"
            else
                print_warning "Checksum verification failed (continuing anyway)"
            fi
        else
            print_warning "shasum not found, skipping checksum verification"
        fi
    else
        print_warning "Checksum file not found, skipping verification"
    fi
    
    # Make executable
    chmod +x "$BINARY_NAME"
    
    # Create install directory if needed
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Creating installation directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Install binary
    print_info "Installing to $INSTALL_DIR..."
    mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    print_success "CLI installed successfully!"
    
    # Check if in PATH
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
    
    # Test installation
    if command -v "$BINARY_NAME" &> /dev/null; then
        echo ""
        print_info "Testing installation..."
        "$BINARY_NAME" --version
        echo ""
    else
        echo ""
        print_info "You can run the CLI with:"
        echo -e "${YELLOW}$INSTALL_DIR/$BINARY_NAME${NC}"
        echo ""
    fi
    
    print_header "Installation Complete!"
    
    cat << EOF
${GREEN}Get started with these commands:${NC}

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

For more help:
  ${YELLOW}$BINARY_NAME --help${NC}

Configuration is stored in: ${BLUE}~/.dart_cloud/config.json${NC}

EOF
}

# Run installation
download_and_install
