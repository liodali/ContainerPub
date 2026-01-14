abstract class EmailTemplate {
  String? get logo;
  String? get companyName;
  String? get year;
  String? get supportEmail;

  String buildHtml();
  String buildText();

  String wrapInLayout(String content) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${companyName ?? 'Email'}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .email-wrapper {
      background-color: #ffffff;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }
    .header {
      background-color: #4F46E5;
      padding: 30px 20px;
      text-align: center;
    }
    .header img {
      max-height: 50px;
      width: auto;
    }
    .header h1 {
      color: #ffffff;
      margin: 10px 0 0 0;
      font-size: 24px;
    }
    .content {
      padding: 40px 30px;
    }
    .footer {
      background-color: #f9fafb;
      padding: 20px 30px;
      text-align: center;
      font-size: 12px;
      color: #6b7280;
    }
    .button {
      display: inline-block;
      background-color: #4F46E5;
      color: #ffffff;
      padding: 14px 28px;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      margin: 20px 0;
    }
    .code-box {
      background-color: #f3f4f6;
      border: 2px dashed #d1d5db;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 20px 0;
    }
    .code {
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 8px;
      color: #4F46E5;
      font-family: monospace;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="email-wrapper">
      <div class="header">
        ${logo != null ? '<img src="$logo" alt="${companyName ?? 'Logo'}">' : ''}
        <h1>${companyName ?? ''}</h1>
      </div>
      <div class="content">
        $content
      </div>
      <div class="footer">
        <p>&copy; ${year ?? DateTime.now().year} ${companyName ?? 'Company'}. All rights reserved.</p>
        ${supportEmail != null ? '<p>Need help? Contact us at <a href="mailto:$supportEmail">$supportEmail</a></p>' : ''}
      </div>
    </div>
  </div>
</body>
</html>
''';
  }
}

class TemplateData {
  final String? logo;
  final String? companyName;
  final String? year;
  final String? supportEmail;
  final Map<String, dynamic> extra;

  TemplateData({
    this.logo,
    this.companyName,
    this.year,
    this.supportEmail,
    this.extra = const {},
  });
}
