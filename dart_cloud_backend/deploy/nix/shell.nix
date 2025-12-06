# shell.nix - For users not using Nix flakes
# Usage: nix-shell or direnv allow

{ pkgs ? import <nixpkgs> {} }:

let
  # Dart SDK
  dart = pkgs.dart;

  # PostgreSQL for local development
  postgresql = pkgs.postgresql_16;

in pkgs.mkShell {
  name = "dart-cloud-backend-dev";

  buildInputs = with pkgs; [
    # Dart SDK
    dart

    # Database
    postgresql

    # Container tools
    docker
    docker-compose

    # Build tools
    gnumake
    cmake
    pkg-config

    # Network tools
    curl
    jq
    httpie

    # Development utilities
    watchexec
    entr

    # Git
    git

    # Editor support
    nil # Nix LSP
  ];

  shellHook = ''
    echo "🚀 Dart Cloud Backend Development Environment"
    echo ""
    echo "Dart version: $(dart --version 2>&1)"
    echo "PostgreSQL version: $(postgres --version)"
    echo ""
    echo "Available commands:"
    echo "  dev-server    - Start development server"
    echo "  dev-db        - Start PostgreSQL in Docker"
    echo "  dev-test      - Run tests"
    echo "  dev-build     - Build the server executable"
    echo "  dev-clean     - Clean build artifacts"
    echo ""

    # Set up environment variables
    export DART_CLOUD_BACKEND_ROOT="$(pwd)/.."
    export FUNCTIONS_DIR="$DART_CLOUD_BACKEND_ROOT/functions"
    export DATABASE_URL="postgresql://dart_cloud:dart_cloud_password@localhost:5432/dart_cloud_db"

    # Create functions directory if it doesn't exist
    mkdir -p "$FUNCTIONS_DIR"

    # Aliases for common tasks
    alias dev-server='cd $DART_CLOUD_BACKEND_ROOT && dart run bin/server.dart'
    alias dev-db='docker-compose -f docker-compose.yml up -d postgres'
    alias dev-test='cd $DART_CLOUD_BACKEND_ROOT && dart test'
    alias dev-build='cd $DART_CLOUD_BACKEND_ROOT && dart compile exe bin/server.dart -o bin/server'
    alias dev-clean='cd $DART_CLOUD_BACKEND_ROOT && rm -rf .dart_tool build bin/server'
    alias dev-pub-get='cd $DART_CLOUD_BACKEND_ROOT && dart pub get'
  '';

  # Environment variables
  DART_VM_OPTIONS = "--enable-asserts";
}
