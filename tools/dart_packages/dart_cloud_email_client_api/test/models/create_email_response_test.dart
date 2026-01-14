import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:test/test.dart';

void main() {
  group('CreateEmailResponse', () {
    test('fromJson creates response from valid JSON', () {
      final json = {
        'message': 'Email sent successfully',
      };

      final response = CreateEmailResponse.fromJson(json);

      expect(response.message, equals('Email sent successfully'));
    });

    test('toJson converts response to JSON', () {
      final response = CreateEmailResponse(
        message: 'Email sent successfully',
      );

      final json = response.toJson();

      expect(json['message'], equals('Email sent successfully'));
    });
  });
}
