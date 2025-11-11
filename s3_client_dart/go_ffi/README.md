# Go FFI for S3 Client

This package provides a Go FFI for interacting with an S3 bucket. It can be used to upload, list, and delete objects in an S3 bucket from a Dart client.

## API

The following functions are exported from the Go package:

### `initBucket(bucketName *C.char, bucketToken *C.char)`

Initializes the S3 client. This function must be called before any other functions in this package.

**Arguments**

* `bucketName`: The name of the S3 bucket.
* `bucketToken`: The AWS access token.

### `upload(filePath *C.char, objectKey *C.char) *C.char`

Uploads a file to the S3 bucket.

**Arguments**

* `filePath`: The path to the file to upload.
* `objectKey`: The key of the object in the S3 bucket.

**Returns**

The key of the uploaded object.

### `list() *C.char`

Lists the objects in the S3 bucket.

**Returns**

A JSON string containing a list of the object keys.

### `delete(objectKey *C.char)`

Deletes an object from the S3 bucket.

**Arguments**

* `objectKey`: The key of the object to delete.

## Building

To build the shared library, run the following command:

```bash
go build -o s3_client.so -buildmode=c-shared main.go
```