# Nix Development Environment

This directory contains Nix configuration for the Dart Cloud Backend development environment.

## Prerequisites

- [Nix](https://nixos.org/download.html) installed on your system
- (Optional) [direnv](https://direnv.net/) for automatic environment loading

## Quick Start

### Using Nix Flakes (Recommended)

```bash
# Enter development shell
cd dart_cloud_backend/deploy
nix develop ./nix

# Or run directly
nix develop ./nix -c dart run ../bin/server.dart
```

### Using Traditional Nix

```bash
# Enter development shell
cd dart_cloud_backend/deploy
nix-shell ./nix/shell.nix
```

### Using direnv

```bash
# Copy .envrc to deploy directory
cp nix/.envrc .envrc

# Allow direnv (one-time)
direnv allow

# Environment loads automatically when entering the directory
```

## Available Development Shells

### Default Shell

Full development environment with all tools:

```bash
nix develop ./nix
```

### Minimal Shell

Just Dart and Git:

```bash
nix develop ./nix#minimal
```

### CI Shell

For CI/CD pipelines:

```bash
nix develop ./nix#ci
```

## Available Commands

Once in the development shell, these aliases are available:

| Command       | Description                  |
| ------------- | ---------------------------- |
| `dev-server`  | Start the development server |
| `dev-db`      | Start PostgreSQL in Docker   |
| `dev-test`    | Run tests                    |
| `dev-build`   | Build the server executable  |
| `dev-clean`   | Clean build artifacts        |
| `dev-pub-get` | Get Dart dependencies        |

## Building

### Build the Server

```bash
# Using flakes
nix build ./nix

# Using traditional nix
nix-build ./nix/default.nix
```

### Build Docker Image

```bash
nix build ./nix#docker
docker load < result
```

## Environment Variables

The following environment variables are set automatically:

| Variable                  | Default            | Description                  |
| ------------------------- | ------------------ | ---------------------------- |
| `DART_CLOUD_BACKEND_ROOT` | `../`              | Path to backend root         |
| `FUNCTIONS_DIR`           | `../functions`     | Functions storage directory  |
| `DATABASE_URL`            | `postgresql://...` | PostgreSQL connection string |
| `PORT`                    | `8080`             | Server port                  |

## Included Tools

- **Dart SDK** - Latest stable version
- **PostgreSQL 16** - Database server
- **Docker & Docker Compose** - Container tools
- **curl, jq, httpie** - HTTP/API testing
- **watchexec, entr** - File watching for hot reload
- **nil** - Nix LSP for editor support

## Customization

### Adding Dependencies

Edit `flake.nix` or `shell.nix` and add packages to `buildInputs`:

```nix
buildInputs = with pkgs; [
  dart
  # Add your packages here
  redis
  minio
];
```

### Custom Shell Hook

Add commands to `shellHook` in the nix files:

```nix
shellHook = ''
  # Your custom setup here
  echo "Custom setup complete"
'';
```

## Troubleshooting

### Flake not found

```bash
# Enable flakes in your Nix configuration
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Permission denied for Docker

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Dart pub get fails

```bash
# Clear Dart cache
rm -rf ~/.pub-cache
dart pub get
```
