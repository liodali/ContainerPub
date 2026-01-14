class EmailEnvelope {
  final String? from;
  final List<String>? to;

  EmailEnvelope({this.from, this.to});

  factory EmailEnvelope.fromJson(Map<String, dynamic> json) {
    return EmailEnvelope(
      from: json['from'] as String?,
      to: (json['to'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {if (from != null) 'from': from, if (to != null) 'to': to};
  }
}

class Email {
  final String id;
  final String object;
  final String status;
  final String alias;
  final String domain;
  final String user;
  final bool? isRedacted;
  final List<String>? hardBounces;
  final List<String>? softBounces;
  final bool? isBounce;
  final bool? isLocked;
  final EmailEnvelope? envelope;
  final String? messageId;
  final DateTime? date;
  final String? subject;
  final List<String>? accepted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? link;
  final bool? requireTLS;

  Email({
    required this.id,
    required this.object,
    required this.status,
    required this.alias,
    required this.domain,
    required this.user,
    this.isRedacted,
    this.hardBounces,
    this.softBounces,
    this.isBounce,
    this.isLocked,
    this.envelope,
    this.messageId,
    this.date,
    this.subject,
    this.accepted,
    this.createdAt,
    this.updatedAt,
    this.link,
    this.requireTLS,
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'] as String,
      object: json['object'] as String,
      status: json['status'] as String,
      alias: json['alias'] as String,
      domain: json['domain'] as String,
      user: json['user'] as String,
      isRedacted: json['is_redacted'] as bool?,
      hardBounces: (json['hard_bounces'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      softBounces: (json['soft_bounces'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isBounce: json['is_bounce'] as bool?,
      isLocked: json['is_locked'] as bool?,
      envelope: json['envelope'] != null
          ? EmailEnvelope.fromJson(json['envelope'] as Map<String, dynamic>)
          : null,
      messageId: json['messageId'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      subject: json['subject'] as String?,
      accepted: (json['accepted'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      link: json['link'] as String?,
      requireTLS: json['requireTLS'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'status': status,
      'alias': alias,
      'domain': domain,
      'user': user,
      if (isRedacted != null) 'is_redacted': isRedacted,
      if (hardBounces != null) 'hard_bounces': hardBounces,
      if (softBounces != null) 'soft_bounces': softBounces,
      if (isBounce != null) 'is_bounce': isBounce,
      if (isLocked != null) 'is_locked': isLocked,
      if (envelope != null) 'envelope': envelope!.toJson(),
      if (messageId != null) 'messageId': messageId,
      if (date != null) 'date': date!.toIso8601String(),
      if (subject != null) 'subject': subject,
      if (accepted != null) 'accepted': accepted,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (link != null) 'link': link,
      if (requireTLS != null) 'requireTLS': requireTLS,
    };
  }
}
