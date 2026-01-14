import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ForwardEmailClient client;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    client = ForwardEmailClient(
      apiKey: 'test-api-key',
      dio: dio,
    );
  });

  tearDown(() {
    client.close();
  });

  group('ForwardEmailClient', () {
    test('constructor sets correct base URL', () {
      expect(dio.options.baseUrl, equals('https://api.forwardemail.net'));
    });

    test('constructor sets Authorization header with Basic Auth', () {
      final authHeader = dio.options.headers['Authorization'] as String;
      expect(authHeader, startsWith('Basic '));
    });

    test('constructor accepts custom base URL', () {
      final customDio = Dio();
      final customClient = ForwardEmailClient(
        apiKey: 'test-key',
        baseUrl: 'https://custom.api.com',
        dio: customDio,
      );

      expect(customDio.options.baseUrl, equals('https://custom.api.com'));
      customClient.close();
    });

    group('listEmails', () {
      test('returns list of emails on success', () async {
        final mockResponse = [
          {
            'id': 'email1',
            'object': 'email',
            'status': 'sent',
            'alias': 'alias1',
            'domain': 'domain1',
            'user': 'user1',
            'subject': 'Test Email 1',
          },
          {
            'id': 'email2',
            'object': 'email',
            'status': 'sent',
            'alias': 'alias2',
            'domain': 'domain2',
            'user': 'user2',
            'subject': 'Test Email 2',
          },
        ];

        dioAdapter.onGet(
          '/v1/emails',
          (server) => server.reply(200, mockResponse),
        );

        final emails = await client.listEmails();

        expect(emails, hasLength(2));
        expect(emails[0].id, equals('email1'));
        expect(emails[0].subject, equals('Test Email 1'));
        expect(emails[1].id, equals('email2'));
        expect(emails[1].subject, equals('Test Email 2'));
      });

      test('returns empty list when response data is null', () async {
        dioAdapter.onGet(
          '/v1/emails',
          (server) => server.reply(200, null),
        );

        final emails = await client.listEmails();

        expect(emails, isEmpty);
      });

      test('sends query parameters when provided', () async {
        dioAdapter.onGet(
          '/v1/emails',
          (server) => server.reply(200, []),
          queryParameters: {
            'q': 'test query',
            'domain': 'example.com',
            'sort': '-created_at',
            'page': '1',
            'limit': '10',
          },
        );

        final params = ListEmailsParams(
          query: 'test query',
          domain: 'example.com',
          sort: '-created_at',
          page: '1',
          limit: '10',
        );

        await client.listEmails(params);
      });

      test('throws ForwardEmailException on 401 error', () async {
        dioAdapter.onGet(
          '/v1/emails',
          (server) => server.reply(
            401,
            {'message': 'Unauthorized'},
          ),
        );

        expect(
          () => client.listEmails(),
          throwsA(
            isA<ForwardEmailException>().having(
              (e) => e.statusCode,
              'statusCode',
              equals(401),
            ),
          ),
        );
      });

      test('throws ForwardEmailException with message from response', () async {
        dioAdapter.onGet(
          '/v1/emails',
          (server) => server.reply(
            400,
            {'message': 'Bad Request: Invalid parameters'},
          ),
        );

        expect(
          () => client.listEmails(),
          throwsA(
            isA<ForwardEmailException>()
                .having(
                  (e) => e.message,
                  'message',
                  equals('Bad Request: Invalid parameters'),
                )
                .having(
                  (e) => e.statusCode,
                  'statusCode',
                  equals(400),
                ),
          ),
        );
      });
    });

    group('createEmail', () {
      test('creates email successfully', () async {
        final mockResponse = {
          'message': 'Email sent successfully',
        };

        dioAdapter.onPost(
          '/v1/emails',
          (server) => server.reply(200, mockResponse),
          data: {
            'from': 'sender@example.com',
            'to': ['recipient@example.com'],
            'subject': 'Test Subject',
            'text': 'Test body',
          },
        );

        final request = CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
          subject: 'Test Subject',
          bodyTxt: 'Test body',
        );

        final response = await client.createEmail(request);

        expect(response.message, equals('Email sent successfully'));
      });

      test('sends all request fields in JSON', () async {
        dioAdapter.onPost(
          '/v1/emails',
          (server) => server.reply(200, {'message': 'Success'}),
          data: {
            'from': 'sender@example.com',
            'to': ['recipient@example.com'],
            'cc': ['cc@example.com'],
            'subject': 'Test',
            'text': 'Text body',
            'html': '<p>HTML body</p>',
            'messageId': 'msg-123',
            'priority': 'high',
            'requireTLS': true,
          },
        );

        final request = CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
          cc: ['cc@example.com'],
          subject: 'Test',
          bodyTxt: 'Text body',
          bodyHtml: '<p>HTML body</p>',
          messageId: 'msg-123',
          priority: EmailPriority.high,
          requireTLS: true,
        );

        await client.createEmail(request);
      });

      test('throws ForwardEmailException when response is null', () async {
        dioAdapter.onPost(
          '/v1/emails',
          (server) => server.reply(200, null),
        );

        final request = CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
        );

        expect(
          () => client.createEmail(request),
          throwsA(
            isA<ForwardEmailException>().having(
              (e) => e.message,
              'message',
              equals('Empty response from server'),
            ),
          ),
        );
      });

      test('throws ForwardEmailException on 403 error', () async {
        dioAdapter.onPost(
          '/v1/emails',
          (server) => server.reply(
            403,
            {'message': 'Forbidden: Insufficient permissions'},
          ),
        );

        final request = CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
        );

        expect(
          () => client.createEmail(request),
          throwsA(
            isA<ForwardEmailException>()
                .having(
                  (e) => e.message,
                  'message',
                  equals('Forbidden: Insufficient permissions'),
                )
                .having(
                  (e) => e.statusCode,
                  'statusCode',
                  equals(403),
                ),
          ),
        );
      });

      test('handles network errors gracefully', () async {
        dioAdapter.onPost(
          '/v1/emails',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/v1/emails'),
              message: 'Network error',
            ),
          ),
        );

        final request = CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
        );

        expect(
          () => client.createEmail(request),
          throwsA(isA<ForwardEmailException>()),
        );
      });
    });
  });

  group('ForwardEmailException', () {
    test('toString returns formatted message', () {
      final exception = ForwardEmailException(
        message: 'Test error',
        statusCode: 400,
      );

      expect(
        exception.toString(),
        equals('ForwardEmailException: Test error (statusCode: 400)'),
      );
    });

    test('toString handles null statusCode', () {
      final exception = ForwardEmailException(
        message: 'Test error',
      );

      expect(
        exception.toString(),
        equals('ForwardEmailException: Test error (statusCode: null)'),
      );
    });
  });
}
