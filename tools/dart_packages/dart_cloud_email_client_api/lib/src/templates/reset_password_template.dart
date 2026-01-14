import 'email_template.dart';

class ResetPasswordTemplate extends EmailTemplate {
  final TemplateData data;
  final String resetUrl;
  final String? userName;
  final int? expiryMinutes;

  ResetPasswordTemplate({
    required this.data,
    required this.resetUrl,
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
<h2>Reset Your Password</h2>
${userName != null ? '<p>Hi $userName,</p>' : '<p>Hi,</p>'}
<p>We received a request to reset your password. Click the button below to create a new password:</p>
<p style="text-align: center;">
  <a href="$resetUrl" class="button">Reset Password</a>
</p>
${expiryMinutes != null ? '<p><strong>This link will expire in $expiryMinutes minutes.</strong></p>' : ''}
<p>If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
<p style="font-size: 12px; color: #6b7280;">If the button doesn't work, copy and paste this link into your browser:<br>
<a href="$resetUrl" style="color: #4F46E5; word-break: break-all;">$resetUrl</a></p>
''';
    return wrapInLayout(content);
  }

  @override
  String buildText() {
    final buffer = StringBuffer();
    buffer.writeln('Reset Your Password');
    buffer.writeln('');
    if (userName != null) {
      buffer.writeln('Hi $userName,');
    } else {
      buffer.writeln('Hi,');
    }
    buffer.writeln('');
    buffer.writeln(
      'We received a request to reset your password. Use the link below to create a new password:',
    );
    buffer.writeln('');
    buffer.writeln(resetUrl);
    buffer.writeln('');
    if (expiryMinutes != null) {
      buffer.writeln('This link will expire in $expiryMinutes minutes.');
      buffer.writeln('');
    }
    buffer.writeln(
      'If you didn\'t request a password reset, you can safely ignore this email. Your password will remain unchanged.',
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
