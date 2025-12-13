package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var (
	s3Bucket *S3Bucket
	s3Mu     sync.Mutex
)

// S3Bucket holds the S3 client and bucket name.
type S3Bucket struct {
	BucketName string
	client     *s3.Client
}

//export initBucket
func initBucket(endpoint *C.char, bucketName *C.char, keyId *C.char, secretAccessKey *C.char, sessionToken *C.char, region *C.char, accountId *C.char) {
	ctx := context.TODO()

	// Convert C strings to Go strings and trim whitespace
	endpointStr := C.GoString(endpoint)
	regionStr := C.GoString(region)
	accessKeyID := C.GoString(keyId)
	secretKey := C.GoString(secretAccessKey)
	sessionTokenStr := C.GoString(sessionToken)
	accountIDStr := C.GoString(accountId)

	// Debug logging (remove in production)
	fmt.Printf("Initializing S3 client:\n")
	fmt.Printf("  Endpoint: %s\n", endpointStr)
	fmt.Printf("  Region: %s\n", regionStr)
	fmt.Printf("  Access Key ID length: %d\n", len(accessKeyID))
	fmt.Printf("  Secret Key length: %d\n", len(secretKey))
	fmt.Printf("  Session Token length: %d\n", len(sessionTokenStr))
	fmt.Printf("  Account ID: %s\n", accountIDStr)

	// Load default config with region
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(regionStr))
	if err != nil {
		log.Fatal(err)
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		// Set custom endpoint (for Cloudflare R2, MinIO, etc.)
		if endpointStr != "" {
			o.BaseEndpoint = aws.String(endpointStr)
		}

		// Use path-style addressing (required for R2 and some S3-compatible services)
		o.UsePathStyle = true

		// Set credentials
		o.Credentials = aws.NewCredentialsCache(aws.CredentialsProviderFunc(func(ctx context.Context) (aws.Credentials, error) {
			creds := aws.Credentials{
				AccessKeyID:     accessKeyID,
				SecretAccessKey: secretKey,
				Source:          "static",
			}

			// Only set session token if provided
			if sessionTokenStr != "" {
				creds.SessionToken = sessionTokenStr
			}

			// Only set account ID if provided
			if accountIDStr != "" {
				creds.AccountID = accountIDStr
			}

			return creds, nil
		}))
	})

	s3Bucket = &S3Bucket{
		BucketName: C.GoString(bucketName),
		client:     client,
	}
	fmt.Println("S3 Bucket initialized successfully")
}

//export upload
func upload(filePath *C.char, objectKey *C.char) *C.char {
	file, err := os.Open(C.GoString(filePath))
	if err != nil {
		log.Printf("Couldn't open file %v to upload. Here's why: %v\n", C.GoString(filePath), err)
		return C.CString("")
	}
	defer file.Close()

	s3Mu.Lock()
	// Read the contents of the file into a buffer
	var buf bytes.Buffer
	if _, err := io.Copy(&buf, file); err != nil {
		fmt.Fprintln(os.Stderr, "Error reading file:", err)
		return C.CString("Error")
	}

	_, err = s3Bucket.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
		Body:   bytes.NewReader(buf.Bytes()),
	})
	if err != nil {
		log.Printf("Couldn't upload file %v to %v:%v. Here's why: %v\n",
			C.GoString(filePath), s3Bucket.BucketName, C.GoString(objectKey), err)
		return C.CString("")
	}
	defer s3Mu.Unlock()
	return C.CString(C.GoString(objectKey))
}

//export checkKeyBucketExist
func checkKeyBucketExist(objectKey *C.char) C.int {

	s3Mu.Lock()
	_, err := s3Bucket.client.HeadObject(context.TODO(), &s3.HeadObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
	})
	defer s3Mu.Unlock()
	if err == nil {
		// No error means the HeadObject call succeeded, and the object exists.
		return C.int(1)
	}

	if err != nil {
		// The specific error for a non-existent object is "NotFound" (HTTP 404).
		return C.int(0)
	}
	return C.int(0)
}

//export list
func list() *C.char {
	output, err := s3Bucket.client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
		Bucket: aws.String(s3Bucket.BucketName),
	})
	if err != nil {
		log.Fatal(err)
	}

	var objectKeys []string
	for _, object := range output.Contents {
		objectKeys = append(objectKeys, aws.ToString(object.Key))
	}

	jsonResult, err := json.Marshal(objectKeys)
	if err != nil {
		log.Fatal(err)
	}

	return C.CString(string(jsonResult))
}

//export delete
func delete(objectKey *C.char) *C.char {
	_, err := s3Bucket.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
	})
	if err != nil {
		errMsg := fmt.Sprintf("Error deleting object: %v", err)
		log.Println(errMsg)
		return C.CString(errMsg)
	}
	return C.CString("")
}

//export download
func download(objectKey *C.char, destinationPath *C.char) *C.char {
	s3Mu.Lock()
	defer s3Mu.Unlock()

	result, err := s3Bucket.client.GetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
	})
	if err != nil {
		errMsg := fmt.Sprintf("Error downloading object: %v", err)
		log.Println(errMsg)
		return C.CString(errMsg)
	}
	defer result.Body.Close()

	file, err := os.Create(C.GoString(destinationPath))
	if err != nil {
		errMsg := fmt.Sprintf("Error creating file: %v", err)
		log.Println(errMsg)
		return C.CString(errMsg)
	}
	defer file.Close()

	_, err = io.Copy(file, result.Body)
	if err != nil {
		errMsg := fmt.Sprintf("Error writing file: %v", err)
		log.Println(errMsg)
		return C.CString(errMsg)
	}

	return C.CString("")
}

//export getPresignedUrl
func getPresignedUrl(objectKey *C.char, expirationSeconds int) *C.char {
	presignClient := s3.NewPresignClient(s3Bucket.client)

	request, err := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
	}, func(opts *s3.PresignOptions) {
		opts.Expires = time.Duration(expirationSeconds) * time.Second
	})

	if err != nil {
		errMsg := fmt.Sprintf("Error generating presigned URL: %v", err)
		log.Println(errMsg)
		return C.CString("")
	}

	return C.CString(request.URL)
}

func main() {
	// // Load the Shared AWS Configuration (~/.aws/config)
	// cfg, err := config.LoadDefaultConfig(context.TODO())
	// if err != nil {
	// 	log.Fatal(err)
	// }

	// // Create an Amazon S3 service client
	// client := s3.NewFromConfig(cfg)

	// // Get the first page of results for ListObjectsV2 for a bucket
	// output, err := client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
	// 	Bucket: aws.String("amzn-s3-demo-bucket"),
	// })
	// if err != nil {
	// 	log.Fatal(err)
	// }

	// log.Println("first page results")
	// for _, object := range output.Contents {
	// 	log.Printf("key=%s size=%d", aws.ToString(object.Key), *object.Size)
	// }
}
