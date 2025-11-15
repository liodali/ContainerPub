# Build Instructions

This document provides detailed instructions for building the Go shared library for different platforms.

## Prerequisites

- **Go 1.25.4 or later** - [Download Go](https://golang.org/dl/)
- **CGO enabled** - Required for building C-shared libraries
- **GCC/Clang** - C compiler for your platform

## Quick Build

The easiest way to build is using the provided script:

```bash
cd go_ffi

# For macOS (creates .dylib)
./deploy.sh dylib

# For Linux (creates .so)
./deploy.sh so
```

## Manual Build

### macOS (Darwin)

```bash
cd go_ffi

# For Apple Silicon (ARM64)
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o darwin/s3_client_dart_dylib \
  main.go

# For Intel Macs (AMD64)
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o darwin/s3_client_dart_dylib \
  main.go
```

### Linux

```bash
cd go_ffi

# For x86_64
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o linux/s3_client_dart_so \
  main.go

# For ARM64
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o linux/s3_client_dart_so \
  main.go
```

### Windows (Experimental)

```bash
cd go_ffi

GOOS=windows GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o windows/s3_client_dart.dll \
  main.go
```

**Note**: Windows support requires MinGW-w64 or similar toolchain.

## Build Flags Explained

- `-buildmode=c-shared` - Build as a C shared library
- `-ldflags="-s -w"` - Strip debug info to reduce binary size
  - `-s` - Omit symbol table
  - `-w` - Omit DWARF debug info
- `CGO_ENABLED=1` - Enable CGO (required for C exports)

## Output Files

After building, you'll have:

### macOS
```
go_ffi/darwin/
├── s3_client_dart_dylib       # Shared library
└── s3_client_dart_dylib.h     # C header file
```

### Linux
```
go_ffi/linux/
├── s3_client_dart_so          # Shared library
└── s3_client_dart_so.h        # C header file
```

## Verifying the Build

### Check exported symbols (macOS)

```bash
nm -gU go_ffi/darwin/s3_client_dart_dylib | grep -E "(initBucket|upload|list|delete|download|getPresignedUrl)"
```

### Check exported symbols (Linux)

```bash
nm -D go_ffi/linux/s3_client_dart_so | grep -E "(initBucket|upload|list|delete|download|getPresignedUrl)"
```

You should see output like:
```
0000000000123456 T initBucket
0000000000234567 T upload
0000000000345678 T list
...
```

## Cross-Compilation

### From macOS to Linux

```bash
# Install cross-compilation tools
brew install FiloSottile/musl-cross/musl-cross

# Build for Linux
CC=x86_64-linux-musl-gcc \
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -o linux/s3_client_dart_so \
  main.go
```

### From Linux to macOS

Cross-compiling to macOS from Linux is complex and not recommended. Build on the target platform instead.

## Troubleshooting

### "CGO not enabled" error

Ensure `CGO_ENABLED=1` is set:
```bash
export CGO_ENABLED=1
go build -buildmode=c-shared ...
```

### "C compiler not found" error

Install a C compiler:
- **macOS**: `xcode-select --install`
- **Linux**: `sudo apt install build-essential` (Debian/Ubuntu) or `sudo yum groupinstall "Development Tools"` (RHEL/CentOS)
- **Windows**: Install MinGW-w64

### "undefined reference" errors

Make sure all Go dependencies are downloaded:
```bash
go mod download
go mod tidy
```

### Binary size too large

The `-ldflags="-s -w"` flags should reduce size significantly. For even smaller binaries:

```bash
go build -buildmode=c-shared \
  -ldflags="-s -w" \
  -trimpath \
  -o output_file \
  main.go

# Then compress
upx --best --lzma output_file
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build Go FFI

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [macos-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.25'
      
      - name: Build
        run: |
          cd go_ffi
          if [ "$RUNNER_OS" == "macOS" ]; then
            ./deploy.sh dylib
          else
            ./deploy.sh so
          fi
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: go-ffi-${{ matrix.os }}
          path: go_ffi/*/s3_client_dart_*
```

## Development Tips

### Faster builds during development

Remove the strip flags for faster compilation:

```bash
go build -buildmode=c-shared -o output_file main.go
```

### Enable verbose output

```bash
go build -v -buildmode=c-shared -o output_file main.go
```

### Check dependencies

```bash
go list -m all
```

## Next Steps

After building:
1. Verify the library loads correctly in Dart
2. Run the example: `dart run example/s3_client_dart_example.dart`
3. Run tests: `dart test`

## Need Help?

- Check Go's [CGO documentation](https://pkg.go.dev/cmd/cgo)
- Review the [Go build documentation](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)
- Open an issue on GitHub
