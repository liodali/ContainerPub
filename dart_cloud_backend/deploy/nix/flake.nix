{
  description = "Dart Cloud Backend - Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Dart SDK version
        dart = pkgs.dart;

        # PostgreSQL for local development
        postgresql = pkgs.postgresql_16;

        # Development tools
        devTools = with pkgs; [
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

        # Shell hook for development setup
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

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "dart-cloud-backend-dev";
          buildInputs = devTools;
          inherit shellHook;
        };

        # Alternative shells for specific use cases
        devShells.minimal = pkgs.mkShell {
          name = "dart-cloud-backend-minimal";
          buildInputs = with pkgs; [ dart git ];
          shellHook = ''
            echo "🚀 Minimal Dart Development Environment"
            echo "Dart version: $(dart --version 2>&1)"
          '';
        };

        devShells.ci = pkgs.mkShell {
          name = "dart-cloud-backend-ci";
          buildInputs = with pkgs; [
            dart
            git
            docker
          ];
          shellHook = ''
            echo "🔧 CI Environment for Dart Cloud Backend"
          '';
        };

        # Package for building the server
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "dart-cloud-backend";
          version = "1.0.0";

          src = ./..;

          nativeBuildInputs = [ dart ];

          buildPhase = ''
            export HOME=$TMPDIR
            dart pub get --offline || dart pub get
            dart compile exe bin/server.dart -o bin/server
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp bin/server $out/bin/dart-cloud-backend
          '';

          meta = with pkgs.lib; {
            description = "Backend server for hosting and managing Dart serverless functions";
            license = licenses.mit;
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        # Docker image build
        packages.docker = pkgs.dockerTools.buildImage {
          name = "dart-cloud-backend";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ self.packages.${system}.default ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Cmd = [ "/bin/dart-cloud-backend" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
            Env = [
              "PORT=8080"
            ];
          };
        };
      }
    );
}
