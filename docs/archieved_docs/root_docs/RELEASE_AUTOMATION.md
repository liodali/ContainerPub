# CLI Release Automation

This document explains the automated CLI release system for ContainerPub.

## Overview

The CLI is automatically built and released for multiple platforms using GitHub Actions. Users can install pre-built binaries without needing the Dart SDK.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │   Build    │  │   Build    │  │   Build    │       │
│  │   Linux    │  │   macOS    │  │  Windows   │       │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘       │
│         │                │                │             │
│         └────────────────┼────────────────┘             │
│                          │                              │
│                  ┌───────▼────────┐                     │
│                  │ Create Release │                     │
│                  │  + Checksums   │                     │
│                  └───────┬────────┘                     │
└──────────────────────────┼──────────────────────────────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ GitHub Release │
                  │  - Binaries    │
                  │  - Checksums   │
                  │  - Notes       │
                  └────────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │  curl    │    │ install  │    │  Manual  │
   │ install  │    │ -cli.sh  │    │ Download │
   └──────────┘    └──────────┘    └──────────┘
```

## Files Created

### 1. GitHub Actions Workflow

**`.github/workflows/release-cli.yml`**

Multi-platform CI/CD pipeline that:
- Builds CLI for Linux, macOS (Intel & ARM), Windows
- Runs tests
- Creates SHA256 checksums
- Publishes GitHub release
- Tests installation

### 2. Installation Scripts

**`scripts/install.sh`** - Standalone installer
- Can be curled directly from GitHub
- Auto-detects platform
- Downloads latest release
- Verifies checksums
- Installs to `~/.local/bin`

**`scripts/install-cli.sh`** - Enhanced installer
- Supports `--from-release` flag
- Downloads from GitHub releases
- Compiles from source (fallback)
- Development mode support

### 3. Documentation

**`.github/workflows/README.md`** - Workflow documentation
**`RELEASE_AUTOMATION.md`** - This file

## Creating a Release

### Method 1: Tag Push (Automatic)

```bash
# 1. Update version (optional)
cd dart_cloud_cli
nano pubspec.yaml  # version: 1.0.0

# 2. Commit changes
git add .
git commit -m "Release v1.0.0"

# 3. Create and push tag
git tag v1.0.0
git push origin main
git push origin v1.0.0

# GitHub Actions automatically:
# - Builds all platforms
# - Creates release
# - Uploads binaries
```

### Method 2: Manual Trigger

1. Go to GitHub → Actions
2. Select "Release CLI"
3. Click "Run workflow"
4. Choose branch
5. Click "Run workflow"

## Installation Methods

### For End Users

**1. One-Line Install (Easiest)**
```bash
curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
```

**2. Using Repository Script**
```bash
git clone https://github.com/liodali/ContainerPub.git
cd ContainerPub
./scripts/install-cli.sh --from-release
```

**3. Manual Download**
```bash
# Get latest version
VERSION=$(curl -s https://api.github.com/repos/liodali/ContainerPub/releases/latest | grep tag_name | cut -d '"' -f 4)

# Download for your platform
curl -L -o dart_cloud "https://github.com/liodali/ContainerPub/releases/download/${VERSION}/dart_cloud-linux-x64"
chmod +x dart_cloud
sudo mv dart_cloud /usr/local/bin/
```

**4. Specific Version**
```bash
./scripts/install-cli.sh --from-release --version v1.0.0
```

### For Developers

**Compile from Source**
```bash
./scripts/install-cli.sh
# or
./scripts/install-cli.sh --dev  # Development mode
```

## Supported Platforms

| Platform | Architecture | Binary Name |
|----------|-------------|-------------|
| Linux | x64 | `dart_cloud-linux-x64` |
| macOS | x64 (Intel) | `dart_cloud-macos-x64` |
| macOS | ARM64 (M1/M2) | `dart_cloud-macos-arm64` |
| Windows | x64 | `dart_cloud-windows-x64.exe` |

## Release Assets

Each release includes:

```
dart_cloud-linux-x64              # 15-20 MB
dart_cloud-linux-x64.sha256       # Checksum
dart_cloud-macos-x64              # 15-20 MB
dart_cloud-macos-x64.sha256       # Checksum
dart_cloud-macos-arm64            # 15-20 MB
dart_cloud-macos-arm64.sha256     # Checksum
dart_cloud-windows-x64.exe        # 15-20 MB
dart_cloud-windows-x64.exe.sha256 # Checksum
```

## Verification

### Verify Checksum

```bash
# Download binary and checksum
curl -L -O https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-linux-x64
curl -L -O https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-linux-x64.sha256

# Verify
shasum -a 256 -c dart_cloud-linux-x64.sha256
# Should output: dart_cloud-linux-x64: OK
```

### Verify Installation

```bash
# Check version
dart_cloud --version

# Test basic functionality
dart_cloud --help
```

## Workflow Details

### Build Matrix

```yaml
matrix:
  include:
    - os: ubuntu-latest
      artifact_name: dart_cloud-linux-x64
    - os: macos-latest
      artifact_name: dart_cloud-macos-x64
    - os: macos-latest-xlarge  # M1/M2
      artifact_name: dart_cloud-macos-arm64
    - os: windows-latest
      artifact_name: dart_cloud-windows-x64.exe
```

### Steps

1. **Checkout** - Clone repository
2. **Setup Dart** - Install Dart SDK
3. **Get Dependencies** - `dart pub get`
4. **Run Tests** - `dart test` (if available)
5. **Compile** - `dart compile exe`
6. **Create Checksum** - SHA256 hash
7. **Upload Artifact** - Store for release
8. **Create Release** - Publish to GitHub
9. **Test Installation** - Verify downloads work

### Permissions

```yaml
permissions:
  contents: write  # Required for creating releases
```

## Customization

### Change Repository

Update in all files:
```bash
GITHUB_REPO="your-username/your-repo"
```

Files to update:
- `.github/workflows/release-cli.yml`
- `scripts/install-cli.sh`
- `scripts/install.sh`
- `README.md`

### Add Platform

Add to workflow matrix:
```yaml
- os: ubuntu-latest
  artifact_name: dart_cloud-linux-arm64
  asset_name: dart_cloud-linux-arm64
```

Update `detect_platform()` in install scripts.

### Custom Release Notes

Edit the `Create Release Notes` step in workflow:
```yaml
- name: Create Release Notes
  run: |
    cat > release_notes.md << 'EOF'
    Your custom release notes here
    EOF
```

## Troubleshooting

### Build Fails

**Check Dart SDK compatibility:**
```yaml
- name: Setup Dart SDK
  uses: dart-lang/setup-dart@v1
  with:
    sdk: stable  # or specific version
```

**Check dependencies:**
```bash
cd dart_cloud_cli
dart pub get
dart analyze
```

### Release Not Created

**Verify tag format:**
```bash
# Correct
git tag v1.0.0

# Incorrect
git tag 1.0.0
git tag release-1.0.0
```

**Check permissions:**
- Repository settings → Actions → General
- Workflow permissions → Read and write

### Download Fails

**Check release exists:**
```bash
curl -s https://api.github.com/repos/liodali/ContainerPub/releases/latest
```

**Check binary name:**
```bash
# List all assets
curl -s https://api.github.com/repos/liodali/ContainerPub/releases/latest | grep browser_download_url
```

### Binary Won't Run

**Check permissions:**
```bash
chmod +x dart_cloud
```

**Check platform:**
```bash
file dart_cloud
# Should match your system
```

**Check architecture:**
```bash
uname -m
# x86_64 = x64
# arm64/aarch64 = ARM64
```

## Security

### Checksums

Every binary includes SHA256 checksum:
```bash
shasum -a 256 dart_cloud-linux-x64
```

### Signed Releases

GitHub automatically signs releases:
- Verified by GitHub
- Traceable to repository
- Audit log available

### Source Verification

All builds are from public source:
- Open source repository
- Public build logs
- Reproducible builds

## Best Practices

### Versioning

Use semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor update
- `v1.0.1` - Patch/bugfix

### Pre-releases

For beta versions:
```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

Mark as pre-release in workflow:
```yaml
prerelease: true
```

### Changelog

Maintain `CHANGELOG.md`:
```markdown
## [1.0.0] - 2024-01-01
### Added
- New feature X
### Fixed
- Bug Y
```

### Testing

Test before releasing:
```bash
# Local test
cd dart_cloud_cli
dart test

# Compile test
dart compile exe bin/main.dart -o test_binary
./test_binary --version
```

## Monitoring

### View Workflow Runs

GitHub → Actions → Release CLI

### Download Logs

Click workflow run → Download logs

### Check Release

GitHub → Releases → Latest

### Monitor Downloads

GitHub → Insights → Traffic → Popular content

## Integration

### Package Managers

Future integration options:

**Homebrew (macOS/Linux):**
```ruby
class DartCloud < Formula
  desc "ContainerPub CLI"
  homepage "https://github.com/liodali/ContainerPub"
  url "https://github.com/liodali/ContainerPub/releases/download/v1.0.0/dart_cloud-macos-x64"
  sha256 "..."
end
```

**Scoop (Windows):**
```json
{
  "version": "1.0.0",
  "url": "https://github.com/liodali/ContainerPub/releases/download/v1.0.0/dart_cloud-windows-x64.exe",
  "hash": "..."
}
```

### CI/CD Integration

**GitHub Actions:**
```yaml
- name: Install Dart Cloud CLI
  run: |
    curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
    export PATH="$PATH:$HOME/.local/bin"
```

**GitLab CI:**
```yaml
install_cli:
  script:
    - curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
    - export PATH="$PATH:$HOME/.local/bin"
```

## Future Enhancements

- [ ] Auto-update mechanism
- [ ] Package manager integration (Homebrew, Scoop)
- [ ] Docker image with CLI
- [ ] ARM Linux support
- [ ] Code signing for macOS/Windows
- [ ] Notarization for macOS
- [ ] Snap package for Linux
- [ ] Chocolatey package for Windows

## Support

For issues:
1. Check [GitHub Actions logs](.github/workflows/README.md)
2. Review [Installation Guide](scripts/README.md)
3. Open GitHub issue
4. Check [Discussions](https://github.com/liodali/ContainerPub/discussions)

---

**Related Documentation:**
- [GitHub Actions Workflow](.github/workflows/README.md)
- [Installation Scripts](scripts/README.md)
- [CLI Documentation](dart_cloud_cli/README.md)
- [Main README](README.md)
