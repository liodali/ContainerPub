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
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
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
