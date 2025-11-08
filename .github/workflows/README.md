# GitHub Actions Workflows

This directory contains automated workflows for ContainerPub.

## Workflows

### `release-cli.yml` - CLI Release Automation

Automatically builds and releases the Dart Cloud CLI for multiple platforms.

#### Triggers

- **Tag push**: Automatically runs when you push a version tag (e.g., `v1.0.0`)
- **Manual**: Can be triggered manually from GitHub Actions tab

#### What It Does

1. **Builds CLI** for multiple platforms:
   - Linux x64
   - macOS x64 (Intel)
   - macOS ARM64 (Apple Silicon)
   - Windows x64

2. **Runs tests** (if available)

3. **Creates checksums** (SHA256) for each binary

4. **Creates GitHub Release** with:
   - All platform binaries
   - Checksum files
   - Installation instructions
   - Release notes

5. **Tests installation** on Linux and macOS

#### Creating a Release

```bash
# 1. Update version in pubspec.yaml (if needed)
cd dart_cloud_cli
nano pubspec.yaml  # Update version: 1.0.0

# 2. Commit changes
git add .
git commit -m "Release v1.0.0"

# 3. Create and push tag
git tag v1.0.0
git push origin v1.0.0

# 4. GitHub Actions will automatically:
#    - Build binaries for all platforms
#    - Create GitHub release
#    - Upload all artifacts
```

#### Manual Trigger

1. Go to GitHub Actions tab
2. Select "Release CLI" workflow
3. Click "Run workflow"
4. Choose branch and click "Run workflow"

#### Release Assets

Each release includes:

```
dart_cloud-linux-x64              # Linux binary
dart_cloud-linux-x64.sha256       # Linux checksum
dart_cloud-macos-x64              # macOS Intel binary
dart_cloud-macos-x64.sha256       # macOS Intel checksum
dart_cloud-macos-arm64            # macOS Apple Silicon binary
dart_cloud-macos-arm64.sha256     # macOS Apple Silicon checksum
dart_cloud-windows-x64.exe        # Windows binary
dart_cloud-windows-x64.exe.sha256 # Windows checksum
```

#### Installation Methods

Users can install the CLI in multiple ways:

**1. Automated Installation (Recommended)**
```bash
curl -fsSL https://raw.githubusercontent.com/liodali/ContainerPub/main/scripts/install.sh | bash
```

**2. Using install-cli.sh**
```bash
./scripts/install-cli.sh --from-release
```

**3. Manual Download**
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

#### Verifying Downloads

Each binary includes a SHA256 checksum file:

```bash
# Download binary and checksum
curl -L -O https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-linux-x64
curl -L -O https://github.com/liodali/ContainerPub/releases/latest/download/dart_cloud-linux-x64.sha256

# Verify checksum
shasum -a 256 -c dart_cloud-linux-x64.sha256
```

#### Troubleshooting

**Workflow fails on build:**
- Check Dart SDK compatibility in `pubspec.yaml`
- Ensure all dependencies are available
- Review build logs in GitHub Actions

**Release not created:**
- Ensure tag follows format `v*.*.*` (e.g., `v1.0.0`)
- Check repository permissions
- Verify `GITHUB_TOKEN` has write access

**Binary not working:**
- Verify platform compatibility
- Check file permissions (`chmod +x`)
- Ensure binary is for correct architecture

#### Customization

**Change GitHub Repository:**

Edit `.github/workflows/release-cli.yml` and `scripts/install-cli.sh`:
```bash
GITHUB_REPO="your-username/your-repo"
```

**Add More Platforms:**

Add to the matrix in `release-cli.yml`:
```yaml
- os: ubuntu-latest
  artifact_name: dart_cloud-linux-arm64
  asset_name: dart_cloud-linux-arm64
```

**Customize Release Notes:**

Edit the `Create Release Notes` step in the workflow.

#### Security

- Binaries are built in GitHub's secure runners
- Checksums verify download integrity
- All artifacts are signed by GitHub
- Source code is publicly auditable

#### Best Practices

1. **Version Tags**: Use semantic versioning (v1.0.0, v1.1.0, etc.)
2. **Test Before Release**: Test locally before pushing tags
3. **Changelog**: Maintain a CHANGELOG.md file
4. **Breaking Changes**: Use major version bumps (v2.0.0)
5. **Pre-releases**: Use pre-release tags (v1.0.0-beta.1)

#### Pre-release Example

```bash
# Create pre-release
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1

# Mark as pre-release in workflow
prerelease: true  # Add to release step
```

#### Monitoring

- View workflow runs: GitHub Actions tab
- Download logs: Click on workflow run → Download logs
- Check release: Releases section in repository

#### Support

For issues with the release workflow:
1. Check GitHub Actions logs
2. Verify tag format
3. Ensure repository permissions
4. Review workflow file syntax

---

**Related Documentation:**
- [Installation Guide](../../scripts/README.md)
- [CLI Documentation](../../dart_cloud_cli/README.md)
- [Contributing Guide](../../CONTRIBUTING.md)
