import 'package:database/src/entities/organization.dart';
import 'package:database/src/entities/user_information.dart';

import '../entity.dart';

/// User entity representing the users table
class UserEntity extends Entity {
  final int? id;
  final String? uuid;
  final String email;
  final String? passwordHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  UserEntity({
    this.id,
    this.uuid,
    required this.email,
    this.passwordHash,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String get tableName => 'users';

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'email': email,
    };
  }

  static UserEntity fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString(),
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String?,
      createdAt: map['created_at'] as DateTime?,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  UserEntity copyWith({
    int? id,
    String? uuid,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserWithInformationAndOrganization {
  final UserEntity user;
  final UserInformation userInformation;
  final Organization organization;
  UserWithInformationAndOrganization({
    required this.user,
    required this.userInformation,
    required this.organization,
  });

  factory UserWithInformationAndOrganization.fromMap(Map<String, dynamic> map) {
    return UserWithInformationAndOrganization(
      user: UserEntity.fromMap(map),
      userInformation: UserInformation.fromMap(map),
      organization: Organization.fromMap(map),
    );
  }
}
