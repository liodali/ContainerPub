package main

import "C"
import (
	"context"
	"encoding/json"
	"log"
	"os"

	"sync"

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
func initBucket(bucketName *C.char, keyId *C.char, secretAccessKey *C.char, bucketToken *C.char) {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.Credentials = aws.NewCredentialsCache(aws.CredentialsProviderFunc(func(ctx context.Context) (aws.Credentials, error) {
			return aws.Credentials{
				AccessKeyID:     C.GoString(keyId),
				SecretAccessKey: C.GoString(secretAccessKey),
				SessionToken:    C.GoString(bucketToken),
				Source:          "static",
			}, nil
		}))
	})

	s3Bucket = &S3Bucket{
		BucketName: C.GoString(bucketName),
		client:     client,
	}
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

	_, err = s3Bucket.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
		Body:   file,
	})
	if err != nil {
		log.Printf("Couldn't upload file %v to %v:%v. Here's why: %v\n",
			C.GoString(filePath), s3Bucket.BucketName, C.GoString(objectKey), err)
		return C.CString("")
	}
    defer s3Mu.Unlock()		
	return C.CString(C.GoString(objectKey))
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
func delete(objectKey *C.char) {
	_, err := s3Bucket.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(s3Bucket.BucketName),
		Key:    aws.String(C.GoString(objectKey)),
	})
	if err != nil {
		log.Printf("Couldn't delete object %v. Here's why: %v\n", C.GoString(objectKey), err)
	}
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
