import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateData', () {
    test('creates template data with all fields', () {
      final data = TemplateData(
        logo: 'https://example.com/logo.png',
        companyName: 'Test Company',
        year: '2025',
        supportEmail: 'support@example.com',
        extra: {'key': 'value'},
      );

      expect(data.logo, equals('https://example.com/logo.png'));
      expect(data.companyName, equals('Test Company'));
      expect(data.year, equals('2025'));
      expect(data.supportEmail, equals('support@example.com'));
      expect(data.extra['key'], equals('value'));
    });

    test('creates template data with null fields', () {
      final data = TemplateData();

      expect(data.logo, isNull);
      expect(data.companyName, isNull);
      expect(data.year, isNull);
      expect(data.supportEmail, isNull);
      expect(data.extra, isEmpty);
    });
  });

  group('PasswordCodeTemplate', () {
    test('builds HTML with all fields', () {
      final data = TemplateData(
        logo: 'https://example.com/logo.png',
        companyName: 'Test Company',
        year: '2025',
        supportEmail: 'support@example.com',
      );

      final template = PasswordCodeTemplate(
        data: data,
        code: '123456',
        userName: 'John Doe',
        expiryMinutes: 10,
      );

      final html = template.buildHtml();

      expect(html, contains('123456'));
      expect(html, contains('John Doe'));
      expect(html, contains('10 minutes'));
      expect(html, contains('Test Company'));
      expect(html, contains('https://example.com/logo.png'));
      expect(html, contains('support@example.com'));
      expect(html, contains('<!DOCTYPE html>'));
    });

    test('builds HTML without optional fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = PasswordCodeTemplate(
        data: data,
        code: '654321',
      );

      final html = template.buildHtml();

      expect(html, contains('654321'));
      expect(html, contains('Test Company'));
      expect(html, isNot(contains('John Doe')));
      expect(html, isNot(contains('minutes')));
    });

    test('builds text with all fields', () {
      final data = TemplateData(
        companyName: 'Test Company',
        supportEmail: 'support@example.com',
      );

      final template = PasswordCodeTemplate(
        data: data,
        code: '123456',
        userName: 'John Doe',
        expiryMinutes: 10,
      );

      final text = template.buildText();

      expect(text, contains('123456'));
      expect(text, contains('John Doe'));
      expect(text, contains('10 minutes'));
      expect(text, contains('Test Company'));
      expect(text, contains('support@example.com'));
    });

    test('builds text without optional fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = PasswordCodeTemplate(
        data: data,
        code: '654321',
      );

      final text = template.buildText();

      expect(text, contains('654321'));
      expect(text, contains('Test Company'));
      expect(text, isNot(contains('John Doe')));
    });
  });

  group('WelcomeTemplate', () {
    test('builds HTML with all fields', () {
      final data = TemplateData(
        companyName: 'Test Company',
        logo: 'https://example.com/logo.png',
      );

      final template = WelcomeTemplate(
        data: data,
        userName: 'Jane Smith',
        actionUrl: 'https://example.com/dashboard',
        actionText: 'Go to Dashboard',
      );

      final html = template.buildHtml();

      expect(html, contains('Jane Smith'));
      expect(html, contains('Test Company'));
      expect(html, contains('https://example.com/dashboard'));
      expect(html, contains('Go to Dashboard'));
    });

    test('builds HTML without optional fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = WelcomeTemplate(data: data);

      final html = template.buildHtml();

      expect(html, contains('Welcome'));
      expect(html, contains('Test Company'));
      expect(html, isNot(contains('Jane Smith')));
    });

    test('builds text with all fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = WelcomeTemplate(
        data: data,
        userName: 'Jane Smith',
        actionUrl: 'https://example.com/dashboard',
        actionText: 'Get Started',
      );

      final text = template.buildText();

      expect(text, contains('Jane Smith'));
      expect(text, contains('Test Company'));
      expect(text, contains('https://example.com/dashboard'));
      expect(text, contains('Get Started'));
    });
  });

  group('ResetPasswordTemplate', () {
    test('builds HTML with all fields', () {
      final data = TemplateData(
        companyName: 'Test Company',
        supportEmail: 'support@example.com',
      );

      final template = ResetPasswordTemplate(
        data: data,
        resetUrl: 'https://example.com/reset?token=abc123',
        userName: 'Bob Johnson',
        expiryMinutes: 30,
      );

      final html = template.buildHtml();

      expect(html, contains('Bob Johnson'));
      expect(html, contains('https://example.com/reset?token=abc123'));
      expect(html, contains('30 minutes'));
      expect(html, contains('Test Company'));
      expect(html, contains('support@example.com'));
    });

    test('builds HTML without optional fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = ResetPasswordTemplate(
        data: data,
        resetUrl: 'https://example.com/reset?token=xyz789',
      );

      final html = template.buildHtml();

      expect(html, contains('https://example.com/reset?token=xyz789'));
      expect(html, contains('Test Company'));
      expect(html, isNot(contains('Bob Johnson')));
      expect(html, isNot(contains('minutes')));
    });

    test('builds text with all fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = ResetPasswordTemplate(
        data: data,
        resetUrl: 'https://example.com/reset?token=abc123',
        userName: 'Bob Johnson',
        expiryMinutes: 30,
      );

      final text = template.buildText();

      expect(text, contains('Bob Johnson'));
      expect(text, contains('https://example.com/reset?token=abc123'));
      expect(text, contains('30 minutes'));
      expect(text, contains('Test Company'));
    });

    test('builds text without optional fields', () {
      final data = TemplateData(companyName: 'Test Company');

      final template = ResetPasswordTemplate(
        data: data,
        resetUrl: 'https://example.com/reset?token=xyz789',
      );

      final text = template.buildText();

      expect(text, contains('https://example.com/reset?token=xyz789'));
      expect(text, contains('Test Company'));
    });
  });
}
