# Build and Release Process

This document outlines the automated build and release process for the ContainerPub CLI.

## Overview

The CLI is automatically built and released for multiple platforms using GitHub Actions. This process is triggered by pushing a new tag to the repository.

## How It Works

1.  **Push a tag**: A developer pushes a new tag (e.g., `v1.2.3`) to the GitHub repository.
2.  **Trigger workflow**: The `release-cli.yml` GitHub Actions workflow is triggered.
3.  **Build binaries**: The workflow builds the CLI for Linux, macOS (x64/ARM64), and Windows.
4.  **Create checksums**: SHA256 checksums are generated for each binary.
5.  **Create release**: A new GitHub release is created with the binaries and checksums as assets.

## Creating a Release

1.  **Update the version** in `dart_cloud_cli/pubspec.yaml`.
2.  **Commit and tag** the release:

    ```bash
    git add .
    git commit -m "Release v1.2.3"
    git tag v1.2.3
    git push origin main
    git push origin v1.2.3
    ```

3.  **Monitor the workflow** in the GitHub Actions tab.

## Installation for Users

Users can install the CLI with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
```
