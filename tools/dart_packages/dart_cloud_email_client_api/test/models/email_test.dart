import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:test/test.dart';

void main() {
  group('EmailEnvelope', () {
    test('fromJson creates EmailEnvelope from valid JSON', () {
      final json = {
        'from': 'sender@example.com',
        'to': ['recipient1@example.com', 'recipient2@example.com'],
      };

      final envelope = EmailEnvelope.fromJson(json);

      expect(envelope.from, equals('sender@example.com'));
      expect(envelope.to, hasLength(2));
      expect(envelope.to, contains('recipient1@example.com'));
      expect(envelope.to, contains('recipient2@example.com'));
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{};

      final envelope = EmailEnvelope.fromJson(json);

      expect(envelope.from, isNull);
      expect(envelope.to, isNull);
    });

    test('toJson converts EmailEnvelope to JSON', () {
      final envelope = EmailEnvelope(
        from: 'sender@example.com',
        to: ['recipient@example.com'],
      );

      final json = envelope.toJson();

      expect(json['from'], equals('sender@example.com'));
      expect(json['to'], hasLength(1));
      expect(json['to'], contains('recipient@example.com'));
    });

    test('toJson excludes null values', () {
      final envelope = EmailEnvelope();

      final json = envelope.toJson();

      expect(json.containsKey('from'), isFalse);
      expect(json.containsKey('to'), isFalse);
    });
  });

  group('Email', () {
    test('fromJson creates Email from valid JSON', () {
      final json = {
        'id': 'email123',
        'object': 'email',
        'status': 'sent',
        'alias': 'alias123',
        'domain': 'domain123',
        'user': 'user123',
        'is_redacted': true,
        'hard_bounces': ['bounce1@example.com'],
        'soft_bounces': ['bounce2@example.com'],
        'is_bounce': false,
        'is_locked': false,
        'envelope': {
          'from': 'sender@example.com',
          'to': ['recipient@example.com'],
        },
        'messageId': 'msg-id-123',
        'date': '2025-01-14T12:00:00.000Z',
        'subject': 'Test Email',
        'accepted': ['recipient@example.com'],
        'created_at': '2025-01-14T12:00:00.000Z',
        'updated_at': '2025-01-14T12:30:00.000Z',
        'link': 'https://example.com/email/123',
        'requireTLS': true,
      };

      final email = Email.fromJson(json);

      expect(email.id, equals('email123'));
      expect(email.object, equals('email'));
      expect(email.status, equals('sent'));
      expect(email.alias, equals('alias123'));
      expect(email.domain, equals('domain123'));
      expect(email.user, equals('user123'));
      expect(email.isRedacted, isTrue);
      expect(email.hardBounces, hasLength(1));
      expect(email.softBounces, hasLength(1));
      expect(email.isBounce, isFalse);
      expect(email.isLocked, isFalse);
      expect(email.envelope, isNotNull);
      expect(email.envelope!.from, equals('sender@example.com'));
      expect(email.messageId, equals('msg-id-123'));
      expect(email.date, isNotNull);
      expect(email.subject, equals('Test Email'));
      expect(email.accepted, hasLength(1));
      expect(email.createdAt, isNotNull);
      expect(email.updatedAt, isNotNull);
      expect(email.link, equals('https://example.com/email/123'));
      expect(email.requireTLS, isTrue);
    });

    test('fromJson handles minimal required fields', () {
      final json = {
        'id': 'email123',
        'object': 'email',
        'status': 'sent',
        'alias': 'alias123',
        'domain': 'domain123',
        'user': 'user123',
      };

      final email = Email.fromJson(json);

      expect(email.id, equals('email123'));
      expect(email.object, equals('email'));
      expect(email.status, equals('sent'));
      expect(email.isRedacted, isNull);
      expect(email.envelope, isNull);
      expect(email.messageId, isNull);
    });

    test('toJson converts Email to JSON', () {
      final email = Email(
        id: 'email123',
        object: 'email',
        status: 'sent',
        alias: 'alias123',
        domain: 'domain123',
        user: 'user123',
        subject: 'Test',
        isRedacted: true,
        requireTLS: false,
      );

      final json = email.toJson();

      expect(json['id'], equals('email123'));
      expect(json['object'], equals('email'));
      expect(json['status'], equals('sent'));
      expect(json['alias'], equals('alias123'));
      expect(json['domain'], equals('domain123'));
      expect(json['user'], equals('user123'));
      expect(json['subject'], equals('Test'));
      expect(json['is_redacted'], isTrue);
      expect(json['requireTLS'], isFalse);
    });

    test('toJson excludes null values', () {
      final email = Email(
        id: 'email123',
        object: 'email',
        status: 'sent',
        alias: 'alias123',
        domain: 'domain123',
        user: 'user123',
      );

      final json = email.toJson();

      expect(json.containsKey('is_redacted'), isFalse);
      expect(json.containsKey('envelope'), isFalse);
      expect(json.containsKey('messageId'), isFalse);
    });
  });
}
