# Go FFI for S3 Client

This package provides a Go FFI (Foreign Function Interface) for interacting with AWS S3. It exports C-compatible functions that can be called from Dart using FFI.

## Architecture

The Go code uses:
- **AWS SDK for Go v2** - Official AWS SDK with robust S3 support
- **CGO** - To export C-compatible functions
- **Mutex synchronization** - Thread-safe operations

## Exported Functions

All functions are exported with C bindings and can be called from Dart FFI.

### `initBucket(bucketName *C.char, keyId *C.char, secretAccessKey *C.char, bucketToken *C.char)`

Initializes the S3 client with AWS credentials. Must be called before any other operations.

**Arguments:**
- `bucketName`: The name of the S3 bucket
- `keyId`: AWS access key ID
- `secretAccessKey`: AWS secret access key
- `bucketToken`: AWS session token (optional, use empty string if not needed)

**Returns:** void

### `upload(filePath *C.char, objectKey *C.char) *C.char`

Uploads a file to the S3 bucket.

**Arguments:**
- `filePath`: Local path to the file to upload
- `objectKey`: The key (path) for the object in S3

**Returns:** The object key on success, empty string on failure

### `list() *C.char`

Lists all objects in the S3 bucket.

**Returns:** JSON string containing an array of object keys

**Example output:** `["file1.txt", "folder/file2.pdf", "image.png"]`

### `delete(objectKey *C.char) *C.char`

Deletes an object from the S3 bucket.

**Arguments:**
- `objectKey`: The key of the object to delete

**Returns:** Empty string on success, error message on failure

### `download(objectKey *C.char, destinationPath *C.char) *C.char`

Downloads an object from S3 to a local file.

**Arguments:**
- `objectKey`: The key of the object to download
- `destinationPath`: Local path where the file will be saved

**Returns:** Empty string on success, error message on failure

### `getPresignedUrl(objectKey *C.char, expirationSeconds int) *C.char`

Generates a presigned URL for temporary access to an object.

**Arguments:**
- `objectKey`: The key of the object
- `expirationSeconds`: How long the URL should be valid (in seconds)

**Returns:** The presigned URL, or empty string on failure

## Building

### Using the deploy script (recommended)

```bash
# For macOS (produces .dylib)
./deploy.sh dylib

# For Linux (produces .so)
./deploy.sh so
```

### Manual build

```bash
# macOS
go build -buildmode=c-shared -ldflags="-s -w" -o darwin/s3_client_dart_dylib main.go

# Linux
go build -buildmode=c-shared -ldflags="-s -w" -o linux/s3_client_dart_so main.go
```

The `-ldflags="-s -w"` flags strip debug information to reduce binary size.

## Dependencies

The Go module requires:
- Go 1.25.4 or later
- AWS SDK for Go v2
  - `github.com/aws/aws-sdk-go-v2/config`
  - `github.com/aws/aws-sdk-go-v2/service/s3`

Dependencies are managed in `go.mod` and will be automatically downloaded during build.

## Thread Safety

The implementation uses a mutex (`sync.Mutex`) to ensure thread-safe access to the S3 client, making it safe to call from multiple Dart isolates.

## Error Handling

Errors are logged to stdout and returned as C strings where applicable. The Dart layer should check return values:
- Empty string typically indicates success
- Non-empty string contains error message

## Memory Management

C strings returned by Go functions are allocated with `C.CString()`. The Dart FFI layer is responsible for freeing this memory using `malloc.free()` after converting to Dart strings.