# Release Process

This document describes how to create a new release of the S3 Client Dart package with pre-built native libraries.

## Overview

The package uses GitHub Actions to automatically build native libraries for macOS, Linux, and Windows when you create a new version tag.

## Release Steps

### 1. Update Version

Update the version in `pubspec.yaml`:

```yaml
version: 1.0.0  # Change to your new version
```

### 2. Update CHANGELOG

Add release notes to `CHANGELOG.md`:

```markdown
## 1.0.0

- Initial release
- S3 operations: upload, download, list, delete
- Support for AWS S3 and S3-compatible services (Cloudflare R2, MinIO, etc.)
- Automatic library download from GitHub releases
```

### 3. Commit Changes

```bash
git add .
git commit -m "Release v1.0.0"
```

### 4. Create and Push Tag

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to trigger GitHub Actions
git push origin v1.0.0
```

### 5. Monitor GitHub Actions

1. Go to your repository on GitHub
2. Click on "Actions" tab
3. You should see "Build and Release Native Libraries" workflow running
4. Wait for all jobs to complete (macOS, Linux, Windows builds)

### 6. Verify Release

Once the workflow completes:

1. Go to "Releases" tab in your repository
2. You should see a new release with version tag (e.g., `v1.0.0`)
3. Verify that all three library files are attached:
   - `s3_client_dart-darwin-amd64.tar.gz` (macOS)
   - `s3_client_dart-linux-amd64.tar.gz` (Linux)
   - `s3_client_dart-windows-amd64.zip` (Windows)

## Manual Trigger

You can also manually trigger the workflow:

1. Go to "Actions" tab
2. Select "Build and Release Native Libraries"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Testing the Release

After creating a release, test that the auto-download works:

```dart
import 'package:s3_client_dart/s3_client_dart.dart';

void main() {
  // This will automatically download the library if not found
  final client = S3Client(autoDownload: true);
  
  // Initialize and use...
}
```

## Manual Library Download

Users can also manually download libraries:

```dart
import 'package:s3_client_dart/s3_client_dart.dart';

void main() async {
  // Download library manually
  final libraryPath = await LibraryDownloader.downloadLibrary(
    version: 'v1.0.0',  // or 'latest'
  );
  
  print('Library downloaded to: $libraryPath');
  
  // Use with custom path
  final client = S3Client(
    libraryPath: libraryPath,
    autoDownload: false,
  );
}
```

## Troubleshooting

### Build Fails

If the GitHub Actions build fails:

1. Check the workflow logs for errors
2. Verify that `go_ffi/deploy.sh` is executable
3. Ensure Go dependencies are properly specified in `go.mod`
4. Test the build locally:
   ```bash
   cd go_ffi
   ./deploy.sh dylib  # macOS
   ./deploy.sh so     # Linux
   ```

### Release Not Created

If the release is not created:

1. Verify you have the `GITHUB_TOKEN` secret (it's automatic)
2. Check repository permissions (Actions need write access)
3. Ensure the tag follows the pattern `v*.*.*`

### Download Fails

If users report download failures:

1. Verify the release exists and is public
2. Check that asset names match the expected format
3. Verify the GitHub repository path in `library_downloader.dart`:
   ```dart
   static const String _githubRepo = 'liodali/ContainerPub';
   ```

## Version Naming Convention

Follow semantic versioning:

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backwards compatible
- **Patch** (0.0.1): Bug fixes, backwards compatible

Examples:
- `v1.0.0` - First stable release
- `v1.1.0` - Added new S3 operations
- `v1.1.1` - Fixed upload bug
- `v2.0.0` - Changed API (breaking)

## Pre-release Versions

For beta/alpha releases:

```bash
git tag -a v1.0.0-beta.1 -m "Beta release"
git push origin v1.0.0-beta.1
```

Mark as pre-release in GitHub:
1. Edit the release
2. Check "This is a pre-release"
3. Save

## Hotfix Process

For urgent fixes:

1. Create a hotfix branch from the tag:
   ```bash
   git checkout -b hotfix/1.0.1 v1.0.0
   ```

2. Make your fixes and commit

3. Create new tag:
   ```bash
   git tag -a v1.0.1 -m "Hotfix: Fixed critical bug"
   git push origin v1.0.1
   ```

4. Merge back to main:
   ```bash
   git checkout main
   git merge hotfix/1.0.1
   git push origin main
   ```

## Cleanup Old Releases

To keep the repository clean:

1. Keep the last 3-5 releases
2. Delete very old releases (but keep tags)
3. Users can still download from tags if needed

## Publishing to pub.dev

After creating a GitHub release:

1. Ensure `pubspec.yaml` is updated
2. Run tests:
   ```bash
   dart test
   ```

3. Publish:
   ```bash
   dart pub publish --dry-run  # Test first
   dart pub publish            # Actual publish
   ```

Note: The native libraries will be automatically downloaded by users, so you don't need to include them in the pub.dev package.
