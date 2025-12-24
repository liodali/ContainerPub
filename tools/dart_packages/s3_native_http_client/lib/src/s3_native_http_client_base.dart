import 'dart:io';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;
import 'package:s3_native_http_client/src/s3_configuration.dart';
import 'package:xml/xml.dart';

class S3Service {
  final S3RequestConfiguration configuration;

  S3Service({required this.configuration});

  // 1. Check if Object Exists (HEAD Request)
  Future<bool> exists(String objectKey) async {
    final request = AWSHttpRequest(
      method: AWSHttpMethod.head,
      uri: Uri.parse('${configuration.uri}/$objectKey'),
    );

    final signedRequest = await _sign(request);
    final response = await http.head(
      signedRequest.uri,
      headers: signedRequest.headers,
    );

    return response.statusCode == 200;
  }

  // 2. Upload Object (PUT Request)
  Future<bool> upload(String objectKey, File file) async {
    final bytes = await file.readAsBytes();
    final request = AWSHttpRequest.put(
      Uri.parse('${configuration.uri}/$objectKey'),
      body: bytes,
      headers: {
        'Content-Type': 'application/octet-stream', // Change based on file type
      },
    );

    final signedRequest = await _sign(request);
    final response = await http.put(
      signedRequest.uri,
      headers: signedRequest.headers,
      body: bytes,
    );
    print(response.body);
    return response.statusCode == 200;
  }

  // 3. Download Object (GET Request)
  Future<List<int>?> download(String objectKey) async {
    final request = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: Uri.parse('${configuration.uri}/$objectKey'),
    );

    final signedRequest = await _sign(request);
    final response = await http.get(
      signedRequest.uri,
      headers: signedRequest.headers,
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  // 4. Delete Object (DELETE Request)
  Future<bool> delete(String objectKey) async {
    final request = AWSHttpRequest(
      method: AWSHttpMethod.delete,
      uri: Uri.parse('${configuration.uri}/$objectKey'),
    );

    final signedRequest = await _sign(request);
    final response = await http.delete(
      signedRequest.uri,
      headers: signedRequest.headers,
    );

    // S3 usually returns 204 No Content for successful deletes
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // 5. List Objects (GET Request with List-Type-2)
  Future<List<String>> listObjects({String prefix = ''}) async {
    // S3 ListObjectsV2 uses query parameters
    final uri = Uri.parse('${configuration.uri}/').replace(
      queryParameters: {
        'list-type': '2',
        if (prefix.isNotEmpty) 'prefix': prefix,
      },
    );

    final request = AWSHttpRequest(method: AWSHttpMethod.get, uri: uri);

    final signedRequest = await _sign(request);
    final response = await http.get(
      signedRequest.uri,
      headers: signedRequest.headers,
    );

    if (response.statusCode == 200) {
      return _parseListBucketXml(response.body);
    }
    return [];
  }

  // Helper to extract keys from S3 XML response
  List<String> _parseListBucketXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final keys = document
        .findAllElements('Key')
        .map((node) => node.innerText)
        .toList();
    return keys;
  }

  // Internal Helper: Signs the request using SigV4
  Future<AWSBaseHttpRequest> _sign(AWSHttpRequest request) async {
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(configuration.accessKey, configuration.secretKey),
      ),
    );

    final scope = AWSCredentialScope(
      region: configuration.region,
      service: AWSService.s3,
    );

    return await signer.sign(request, credentialScope: scope);
  }
}
