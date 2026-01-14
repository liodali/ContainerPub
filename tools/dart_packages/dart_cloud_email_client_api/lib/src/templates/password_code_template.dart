import 'email_template.dart';

class PasswordCodeTemplate extends EmailTemplate {
  final TemplateData data;
  final String code;
  final String? userName;
  final int? expiryMinutes;

  PasswordCodeTemplate({
    required this.data,
    required this.code,
    this.userName,
    this.expiryMinutes,
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
<h2>Your Verification Code</h2>
${userName != null ? '<p>Hi $userName,</p>' : '<p>Hi,</p>'}
<p>Use the following code to verify your identity:</p>
<div class="code-box">
  <span class="code">$code</span>
</div>
${expiryMinutes != null ? '<p><strong>This code will expire in $expiryMinutes minutes.</strong></p>' : ''}
<p>If you didn't request this code, please ignore this email or contact support if you have concerns.</p>
''';
    return wrapInLayout(content);
  }

  @override
  String buildText() {
    final buffer = StringBuffer();
    buffer.writeln('Your Verification Code');
    buffer.writeln('');
    if (userName != null) {
      buffer.writeln('Hi $userName,');
    } else {
      buffer.writeln('Hi,');
    }
    buffer.writeln('');
    buffer.writeln('Use the following code to verify your identity:');
    buffer.writeln('');
    buffer.writeln('    $code');
    buffer.writeln('');
    if (expiryMinutes != null) {
      buffer.writeln('This code will expire in $expiryMinutes minutes.');
      buffer.writeln('');
    }
    buffer.writeln(
      'If you didn\'t request this code, please ignore this email or contact support if you have concerns.',
    );
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
