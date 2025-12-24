class S3RequestConfiguration {
  final String accessKey;
  final String secretKey;
  final String endpoint; // e.g., 'https://<id>.r2.cloudflarestorage.com'
  final String region; // R2 uses 'auto', AWS uses 'us-east-1', etc.
  final String bucket;

  S3RequestConfiguration({
    required this.accessKey,
    required this.secretKey,
    required this.endpoint,
    required this.region,
    required this.bucket,
  });
  String get uri => '$endpoint/$bucket';
  @override
  int get hashCode =>
      accessKey.hashCode ^
      secretKey.hashCode ^
      endpoint.hashCode ^
      region.hashCode ^
      bucket.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is S3RequestConfiguration &&
        accessKey == other.accessKey &&
        secretKey == other.secretKey &&
        endpoint == other.endpoint &&
        region == other.region &&
        bucket == other.bucket;
  }
}
