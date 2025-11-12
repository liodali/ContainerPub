class S3Configuration {
  final String bucketName;
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;

  S3Configuration({
    required this.bucketName,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
  });
}