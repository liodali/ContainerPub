import 'email_template.dart';

class WelcomeTemplate extends EmailTemplate {
  final TemplateData data;
  final String? userName;
  final String? actionUrl;
  final String? actionText;

  WelcomeTemplate({
    required this.data,
    this.userName,
    this.actionUrl,
    this.actionText,
  });

  @override
  String? get logo => data.logo;

  @override
  String? get companyName => data.companyName;

  @override
  String? get year => data.year;

  @override
  String? get supportEmail => data.supportEmail;

  @override
  String buildHtml() {
    final content =
        '''
<h2>Welcome${userName != null ? ', $userName' : ''}!</h2>
<p>Thank you for joining ${companyName ?? 'us'}. We're excited to have you on board!</p>
<p>Your account has been successfully created and you're ready to get started.</p>
${actionUrl != null ? '''
<p style="text-align: center;">
  <a href="$actionUrl" class="button">${actionText ?? 'Get Started'}</a>
</p>
''' : ''}
<p>If you have any questions, feel free to reach out to our support team.</p>
<p>Best regards,<br>The ${companyName ?? 'Team'}</p>
''';
    return wrapInLayout(content);
  }

  @override
  String buildText() {
    final buffer = StringBuffer();
    buffer.writeln('Welcome${userName != null ? ', $userName' : ''}!');
    buffer.writeln('');
    buffer.writeln(
      'Thank you for joining ${companyName ?? 'us'}. We\'re excited to have you on board!',
    );
    buffer.writeln('');
    buffer.writeln(
      'Your account has been successfully created and you\'re ready to get started.',
    );
    buffer.writeln('');
    if (actionUrl != null) {
      buffer.writeln('${actionText ?? 'Get Started'}: $actionUrl');
      buffer.writeln('');
    }
    buffer.writeln(
      'If you have any questions, feel free to reach out to our support team.',
    );
    buffer.writeln('');
    buffer.writeln('Best regards,');
    buffer.writeln('The ${companyName ?? 'Team'}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln(
      '© ${year ?? DateTime.now().year} ${companyName ?? 'Company'}',
    );
    if (supportEmail != null) {
      buffer.writeln('Support: $supportEmail');
    }
    return buffer.toString();
  }
}
