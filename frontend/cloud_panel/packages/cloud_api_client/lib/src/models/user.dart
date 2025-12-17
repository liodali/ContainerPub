import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uuid;
  final String email;

  const User({
    required this.uuid,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String,
    );
  }

  @override
  List<Object?> get props => [uuid, email];
}
