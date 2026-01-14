import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:test/test.dart';

void main() {
  group('CreateEmailRequest', () {
    test('creates request with bodyTxt', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        bodyTxt: 'Plain text body',
      );

      expect(request.from, equals('sender@example.com'));
      expect(request.to, hasLength(1));
      expect(request.bodyTxt, equals('Plain text body'));
      expect(request.bodyHtml, isNull);
    });

    test('creates request with bodyHtml', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        bodyHtml: '<p>HTML body</p>',
      );

      expect(request.from, equals('sender@example.com'));
      expect(request.to, hasLength(1));
      expect(request.bodyHtml, equals('<p>HTML body</p>'));
      expect(request.bodyTxt, isNull);
    });

    test('creates request with raw', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        raw: 'raw email content',
      );

      expect(request.from, equals('sender@example.com'));
      expect(request.raw, equals('raw email content'));
    });

    test('throws ArgumentError when both bodyTxt and bodyHtml provided', () {
      expect(
        () => CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
          bodyTxt: 'Plain text body',
          bodyHtml: '<p>HTML body</p>',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Cannot specify both bodyTxt and bodyHtml'),
          ),
        ),
      );
    });

    test('throws ArgumentError when no body content provided', () {
      expect(
        () => CreateEmailRequest(
          from: 'sender@example.com',
          to: ['recipient@example.com'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains(
              'At least one of bodyTxt, bodyHtml, or raw must be provided',
            ),
          ),
        ),
      );
    });

    test('creates request with all fields using bodyTxt', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        cc: ['cc@example.com'],
        bcc: ['bcc@example.com'],
        subject: 'Test Subject',
        bodyTxt: 'Plain text body',
        sender: 'actual-sender@example.com',
        replyTo: 'reply@example.com',
        inReplyTo: 'msg-id-123',
        references: ['ref1', 'ref2'],
        attachDataUrls: true,
        watchHtml: '<p>Watch HTML</p>',
        amp: '<amp>AMP content</amp>',
        encoding: 'utf-8',
        textEncoding: 'base64',
        priority: EmailPriority.high,
        messageId: 'custom-msg-id',
        date: DateTime(2025, 1, 14),
        requireTLS: true,
      );

      expect(request.from, equals('sender@example.com'));
      expect(request.to, hasLength(1));
      expect(request.cc, hasLength(1));
      expect(request.bcc, hasLength(1));
      expect(request.subject, equals('Test Subject'));
      expect(request.bodyTxt, equals('Plain text body'));
      expect(request.bodyHtml, isNull);
      expect(request.sender, equals('actual-sender@example.com'));
      expect(request.replyTo, equals('reply@example.com'));
      expect(request.inReplyTo, equals('msg-id-123'));
      expect(request.references, hasLength(2));
      expect(request.attachDataUrls, isTrue);
      expect(request.watchHtml, equals('<p>Watch HTML</p>'));
      expect(request.amp, equals('<amp>AMP content</amp>'));
      expect(request.encoding, equals('utf-8'));
      expect(request.textEncoding, equals('base64'));
      expect(request.priority, equals(EmailPriority.high));
      expect(request.messageId, equals('custom-msg-id'));
      expect(request.date, isNotNull);
      expect(request.requireTLS, isTrue);
    });

    test('toJson converts request to JSON with bodyTxt', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        subject: 'Test',
        bodyTxt: 'Text',
        messageId: 'msg-123',
        priority: EmailPriority.low,
        requireTLS: false,
      );

      final json = request.toJson();

      expect(json['from'], equals('sender@example.com'));
      expect(json['to'], contains('recipient@example.com'));
      expect(json['subject'], equals('Test'));
      expect(json['text'], equals('Text'));
      expect(json.containsKey('html'), isFalse);
      expect(json['messageId'], equals('msg-123'));
      expect(json['priority'], equals('low'));
      expect(json['requireTLS'], isFalse);
    });

    test('toJson converts request to JSON with bodyHtml', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        subject: 'Test',
        bodyHtml: '<p>HTML</p>',
        messageId: 'msg-456',
        priority: EmailPriority.high,
      );

      final json = request.toJson();

      expect(json['from'], equals('sender@example.com'));
      expect(json['to'], contains('recipient@example.com'));
      expect(json['subject'], equals('Test'));
      expect(json.containsKey('text'), isFalse);
      expect(json['html'], equals('<p>HTML</p>'));
      expect(json['messageId'], equals('msg-456'));
      expect(json['priority'], equals('high'));
    });

    test('toJson excludes null values', () {
      final request = CreateEmailRequest(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
        bodyTxt: 'Text',
      );

      final json = request.toJson();

      expect(json.containsKey('cc'), isFalse);
      expect(json.containsKey('bcc'), isFalse);
      expect(json.containsKey('subject'), isFalse);
      expect(json.containsKey('html'), isFalse);
      expect(json.containsKey('messageId'), isFalse);
    });

    test(
      'fromTemplate creates request with both bodyTxt and bodyHtml from template',
      () {
        final templateData = TemplateData(
          companyName: 'Test Company',
          logo: 'https://example.com/logo.png',
        );

        final template = PasswordCodeTemplate(
          data: templateData,
          code: '123456',
          userName: 'John Doe',
        );

        final request = CreateEmailRequest.fromTemplate(
          from: 'noreply@example.com',
          to: ['user@example.com'],
          subject: 'Your Code',
          template: template,
          messageId: 'msg-123',
          priority: EmailPriority.high,
        );

        expect(request.from, equals('noreply@example.com'));
        expect(request.to, contains('user@example.com'));
        expect(request.subject, equals('Your Code'));
        expect(request.bodyTxt, isNotNull);
        expect(request.bodyTxt, contains('123456'));
        expect(request.bodyHtml, isNotNull);
        expect(request.bodyHtml, contains('123456'));
        expect(request.messageId, equals('msg-123'));
        expect(request.priority, equals(EmailPriority.high));
      },
    );
  });

  group('EmailPriority', () {
    test('enum values are correct', () {
      expect(EmailPriority.high.name, equals('high'));
      expect(EmailPriority.normal.name, equals('normal'));
      expect(EmailPriority.low.name, equals('low'));
    });
  });
}
