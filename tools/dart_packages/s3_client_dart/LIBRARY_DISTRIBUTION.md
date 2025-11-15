# Library Distribution System

This document explains how the native library distribution system works for the S3 Client Dart package.

## Overview

The package uses a hybrid approach for distributing native libraries:

1. **Automatic Download** (Default) - Libraries are downloaded from GitHub releases on first use
2. **Manual Build** (Optional) - Developers can build libraries locally
3. **Custom Path** (Advanced) - Users can specify a custom library location

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User's Dart Application                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      S3Client Class                          │
│  - Accepts libraryPath and autoDownload parameters           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   S3FFIBindings Class                        │
│  - Loads dynamic library                                     │
│  - Triggers auto-download if needed                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
┌──────────────────────┐   ┌──────────────────────────┐
│  Local Library       │   │  LibraryDownloader       │
│  (if exists)         │   │  - Downloads from GitHub │
└──────────────────────┘   │  - Extracts archive      │
                           │  - Caches locally        │
                           └──────────────────────────┘
                                       │
                                       ▼
                           ┌──────────────────────────┐
                           │  GitHub Releases         │
                           │  - Pre-built libraries   │
                           │  - Version tagged        │
                           └──────────────────────────┘
```

## Components

### 1. GitHub Actions Workflow

**File:** `.github/workflows/release-libraries.yml`

**Triggers:**
- Push of version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Jobs:**
- `build-macos` - Builds `.dylib` for macOS
- `build-linux` - Builds `.so` for Linux
- `build-windows` - Builds `.dll` for Windows
- `create-release` - Creates GitHub release with all libraries

**Outputs:**
- `s3_client_dart-darwin-amd64.tar.gz`
- `s3_client_dart-linux-amd64.tar.gz`
- `s3_client_dart-windows-amd64.zip`

### 2. LibraryDownloader

**File:** `lib/src/library_downloader.dart`

**Responsibilities:**
- Detects current platform
- Fetches latest release info from GitHub API
- Downloads appropriate library archive
- Extracts library to local cache
- Sets executable permissions (Unix)

**Cache Location:**
- macOS/Linux: `~/.s3_client_dart/lib/`
- Windows: `%USERPROFILE%\.s3_client_dart\lib\`

**Key Methods:**
```dart
// Download library (async)
Future<String> downloadLibrary({
  String version = 'latest',
  String? targetDir,
})

// Check if library exists
bool libraryExists(String libraryPath)

// Get default library path
Future<String> getDefaultLibraryPath()
```

### 3. S3FFIBindings

**File:** `lib/src/s3_ffi_bindings.dart`

**Loading Strategy:**
1. If `libraryPath` provided → Use it directly
2. Check default platform paths (`go_ffi/darwin/`, etc.)
3. If `autoDownload` enabled → Download from GitHub
4. Otherwise → Throw error

**Parameters:**
- `libraryPath` - Custom library location (optional)
- `autoDownload` - Enable automatic download (default: `true`)

### 4. S3Client

**File:** `lib/src/s3_client_dart_base.dart`

**User-Facing API:**
```dart
S3Client({
  String? libraryPath,
  bool autoDownload = true,
})
```

## Usage Scenarios

### Scenario 1: Default (Auto-Download)

**User Code:**
```dart
final client = S3Client();
```

**What Happens:**
1. S3Client creates S3FFIBindings with `autoDownload: true`
2. FFI bindings try to load from default paths
3. Library not found → Triggers download
4. Downloads from latest GitHub release
5. Extracts to `~/.s3_client_dart/lib/`
6. Loads the downloaded library
7. Subsequent runs use cached library

**Pros:**
- Zero setup for end users
- Always gets compatible version
- Works across all platforms

**Cons:**
- Requires internet on first run
- Initial startup delay (~5-10 seconds)

### Scenario 2: Manual Build

**User Code:**
```dart
final client = S3Client(
  libraryPath: '/path/to/s3_client_dart.dylib',
  autoDownload: false,
);
```

**What Happens:**
1. User builds library locally:
   ```bash
   cd go_ffi
   ./deploy.sh dylib
   ```
2. Specifies path to built library
3. FFI bindings load directly from path
4. No download attempted

**Pros:**
- Full control over library version
- No internet required
- Faster startup (no download check)

**Cons:**
- Requires Go toolchain
- Platform-specific builds
- Manual updates needed

### Scenario 3: Pre-Downloaded

**User Code:**
```dart
// Download once during setup
final path = await LibraryDownloader.downloadLibrary(
  version: 'v1.0.0',
);

// Use in application
final client = S3Client(
  libraryPath: path,
  autoDownload: false,
);
```

**What Happens:**
1. Explicit download during app initialization
2. Path stored for later use
3. Subsequent runs use stored path
4. No automatic downloads

**Pros:**
- Control over download timing
- Can show progress to user
- Version pinning

**Cons:**
- More complex setup code
- Need to handle download errors

### Scenario 4: Bundled Library

**User Code:**
```dart
final client = S3Client(
  libraryPath: 'assets/libs/s3_client_dart.dylib',
  autoDownload: false,
);
```

**What Happens:**
1. Developer bundles library with app
2. Library included in app assets
3. Direct load from asset path
4. No downloads ever

**Pros:**
- Offline support
- Predictable behavior
- No external dependencies

**Cons:**
- Larger app size
- Platform-specific packaging
- Manual updates

## Release Process

### Creating a Release

1. **Update version:**
   ```bash
   # Edit pubspec.yaml
   version: 1.0.0
   ```

2. **Create tag:**
   ```bash
   git tag -a v1.0.0 -m "Release 1.0.0"
   git push origin v1.0.0
   ```

3. **GitHub Actions runs:**
   - Builds libraries for all platforms
   - Creates release with attached binaries

4. **Users get update:**
   - Auto-download fetches new version
   - Or manual download from releases page

### Version Management

**Semantic Versioning:**
- `v1.0.0` - Major.Minor.Patch
- Breaking changes → Major bump
- New features → Minor bump
- Bug fixes → Patch bump

**GitHub Release Tags:**
- Must start with `v`
- Example: `v1.0.0`, `v2.1.3`
- Pre-releases: `v1.0.0-beta.1`

## Security Considerations

### Download Security

1. **HTTPS Only** - All downloads use HTTPS
2. **GitHub Releases** - Official GitHub infrastructure
3. **Version Pinning** - Users can specify exact versions
4. **Checksum Verification** - (TODO: Add SHA256 checksums)

### Library Verification

**Current:**
- Downloads from trusted source (GitHub)
- Uses official release artifacts

**Future Improvements:**
- Add SHA256 checksums to releases
- Verify checksums before extraction
- Sign libraries with code signing certificates

## Troubleshooting

### Download Fails

**Symptoms:**
- "Failed to download library" error
- HTTP errors

**Solutions:**
1. Check internet connection
2. Verify GitHub is accessible
3. Try specific version: `version: 'v1.0.0'`
4. Manual download from releases page

### Library Not Found

**Symptoms:**
- "Library not found" error
- DynamicLibrary.open fails

**Solutions:**
1. Enable auto-download: `autoDownload: true`
2. Check library path is correct
3. Verify file permissions (Unix)
4. Rebuild library locally

### Platform Not Supported

**Symptoms:**
- "Unsupported platform" error

**Solutions:**
1. Check platform is supported (macOS, Linux, Windows)
2. Build library manually for your platform
3. Open issue for platform support request

## Performance

### Download Performance

**Typical Download Times:**
- macOS (.dylib): ~2-5 MB, 2-5 seconds
- Linux (.so): ~2-5 MB, 2-5 seconds
- Windows (.dll): ~2-5 MB, 2-5 seconds

**Optimization:**
- Libraries are stripped (`-s -w` flags)
- Compressed archives (tar.gz/zip)
- Cached after first download

### Runtime Performance

**Library Loading:**
- Cached: <100ms
- First download: 2-10 seconds
- Subsequent runs: <100ms

**Operation Performance:**
- Native Go performance
- No FFI overhead for large operations
- Thread-safe with mutex protection

## Future Enhancements

### Planned Features

1. **Checksum Verification**
   - Add SHA256 checksums to releases
   - Verify before extraction

2. **Progress Callbacks**
   - Show download progress
   - User feedback during download

3. **Automatic Updates**
   - Check for library updates
   - Optional auto-update

4. **Multi-Architecture Support**
   - ARM64 Linux
   - Apple Silicon native
   - ARM Windows

5. **CDN Distribution**
   - Faster downloads
   - Geographic distribution
   - Fallback mirrors

### Community Contributions

Contributions welcome for:
- Additional platform support
- Performance improvements
- Security enhancements
- Documentation improvements

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Go CGO Documentation](https://pkg.go.dev/cmd/cgo)
- [Semantic Versioning](https://semver.org/)
