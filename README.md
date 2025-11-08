# ContainerPub - Dart Serverless Cloud Platform

A serverless cloud platform for hosting and managing Dart functions with CLI deployment tools.

## Architecture

### Components

1. **CLI (`dart_cloud_cli/`)** - Command-line tool for deploying and managing Dart functions
2. **Backend (`dart_cloud_backend/`)** - Server platform for hosting, executing, and monitoring Dart functions

### Features

- 🚀 Deploy Dart functions via CLI
- 🔒 **Client-side security analysis before deployment**
- 📊 Monitor function execution and performance
- 🔄 Auto-scaling and load balancing
- 📝 Function logs and metrics
- 🔐 Authentication and authorization
- 🌐 HTTP endpoints for deployed functions

## Project Structure

```
ContainerPub/
├── dart_cloud_cli/          # CLI tool
│   ├── bin/
│   ├── lib/
│   └── pubspec.yaml
├── dart_cloud_backend/      # Backend server
│   ├── bin/
│   ├── lib/
│   └── pubspec.yaml
└── README.md
```

## Quick Start

### Installation

**Automated Installation (Recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
```

**Or download from releases:**
```bash
# Linux
curl -L -o dart_cloud https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-linux-x64
chmod +x dart_cloud
sudo mv dart_cloud /usr/local/bin/

# macOS (Intel)
curl -L -o dart_cloud https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-macos-x64
chmod +x dart_cloud
sudo mv dart_cloud /usr/local/bin/

# macOS (Apple Silicon)
curl -L -o dart_cloud https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-macos-arm64
chmod +x dart_cloud
sudo mv dart_cloud /usr/local/bin/
```

**Or compile from source:**
```bash
./scripts/install-cli.sh
```

### CLI Usage

```bash
# Login to platform
dart_cloud login

# Deploy a function
dart_cloud deploy ./my_function

# List deployed functions
dart_cloud list

# View function logs
dart_cloud logs <function-id>

# Delete a function
dart_cloud delete <function-id>
```

### Backend Setup

```bash
cd dart_cloud_backend
dart run bin/server.dart
```

## Technology Stack

- **Language**: Dart 3.x
- **Backend Framework**: Shelf (HTTP server)
- **Database**: PostgreSQL (for metadata)
- **Storage**: File system / Object storage
- **Monitoring**: Custom metrics collection
- **Containerization**: Docker isolates for function execution
