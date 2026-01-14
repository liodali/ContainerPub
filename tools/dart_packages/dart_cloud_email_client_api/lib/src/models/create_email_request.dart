import '../templates/email_template.dart';

enum EmailPriority { high, normal, low }

class CreateEmailRequest {
  final String from;
  final List<String> to;
  final List<String>? cc;
  final List<String>? bcc;
  final String? subject;
  final String? bodyTxt;
  final String? bodyHtml;
  final String? sender;
  final String? replyTo;
  final String? inReplyTo;
  final List<String>? references;
  final bool? attachDataUrls;
  final String? watchHtml;
  final String? amp;
  final String? encoding;
  final String? raw;
  final String? textEncoding;
  final EmailPriority? priority;
  final String? messageId;
  final DateTime? date;
  final bool? requireTLS;

  CreateEmailRequest({
    required this.from,
    required this.to,
    this.cc,
    this.bcc,
    this.subject,
    this.bodyTxt,
    this.bodyHtml,
    this.sender,
    this.replyTo,
    this.inReplyTo,
    this.references,
    this.attachDataUrls,
    this.watchHtml,
    this.amp,
    this.encoding,
    this.raw,
    this.textEncoding,
    this.priority,
    this.messageId,
    this.date,
    this.requireTLS,
  }) {
    if (bodyTxt != null && bodyHtml != null) {
      throw ArgumentError(
        'Cannot specify both bodyTxt and bodyHtml. Provide either bodyTxt (plain text) or bodyHtml (HTML), not both.',
      );
    }
    if (bodyTxt == null && bodyHtml == null && raw == null) {
      throw ArgumentError(
        'At least one of bodyTxt, bodyHtml, or raw must be provided.',
      );
    }
  }

  factory CreateEmailRequest.fromTemplate({
    required String from,
    required List<String> to,
    required String subject,
    required EmailTemplate template,
    String? messageId,
    List<String>? cc,
    List<String>? bcc,
    String? sender,
    String? replyTo,
    EmailPriority? priority,
    bool? requireTLS,
  }) {
    return CreateEmailRequest(
      from: from,
      to: to,
      subject: subject,
      bodyTxt: template.buildText(),
      bodyHtml: template.buildHtml(),
      messageId: messageId,
      cc: cc,
      bcc: bcc,
      sender: sender,
      replyTo: replyTo,
      priority: priority,
      requireTLS: requireTLS,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
      if (subject != null) 'subject': subject,
      if (bodyTxt != null) 'text': bodyTxt,
      if (bodyHtml != null) 'html': bodyHtml,
      if (sender != null) 'sender': sender,
      if (replyTo != null) 'replyTo': replyTo,
      if (inReplyTo != null) 'inReplyTo': inReplyTo,
      if (references != null) 'references': references,
      if (attachDataUrls != null) 'attachDataUrls': attachDataUrls,
      if (watchHtml != null) 'watchHtml': watchHtml,
      if (amp != null) 'amp': amp,
      if (encoding != null) 'encoding': encoding,
      if (raw != null) 'raw': raw,
      if (textEncoding != null) 'textEncoding': textEncoding,
      if (priority != null) 'priority': priority!.name,
      if (messageId != null) 'messageId': messageId,
      if (date != null) 'date': date!.toIso8601String(),
      if (requireTLS != null) 'requireTLS': requireTLS,
    };
  }
}
