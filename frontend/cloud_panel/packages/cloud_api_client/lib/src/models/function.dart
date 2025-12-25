import 'package:equatable/equatable.dart';

class CloudFunction extends Equatable {
  final String uuid;
  final String name;
  final String status;
  final DateTime createdAt;
  final bool skipSigning;

  const CloudFunction({
    required this.uuid,
    required this.name,
    required this.status,
    required this.createdAt,
    this.skipSigning = false,
  });

  factory CloudFunction.fromJson(Map<String, dynamic> json) {
    return CloudFunction(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      skipSigning: json['skipSigning'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        uuid,
        name,
        status,
        createdAt,
        skipSigning,
      ];
}
