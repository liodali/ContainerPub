import 'package:database/database.dart';

/// DTO for user information returned to frontend
class UserDto {
  final String uuid;
  final String email;
  final DateTime? createdAt;

  UserDto({
    required this.uuid,
    required this.email,
    this.createdAt,
  });

  factory UserDto.fromEntity(UserEntity entity) {
    return UserDto(
      uuid: entity.uuid!,
      email: entity.email,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

/// DTO for user information details
class UserInformationDto {
  final String uuid;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? address;
  final String? zipCode;
  final String? avatar;
  final String role;

  UserInformationDto({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.country,
    this.city,
    this.address,
    this.zipCode,
    this.avatar,
    required this.role,
  });

  factory UserInformationDto.fromEntity(UserInformation entity) {
    return UserInformationDto(
      uuid: entity.uuid!,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phoneNumber: entity.phoneNumber,
      country: entity.country,
      city: entity.city,
      address: entity.address,
      zipCode: entity.zipCode,
      avatar: entity.avatar,
      role: entity.role.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'first_name': firstName,
      'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      if (zipCode != null) 'zip_code': zipCode,
      if (avatar != null) 'avatar': avatar,
      'role': role,
    };
  }
}

/// DTO for complete user profile (user + information)
class UserProfileDto {
  final String uuid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? address;
  final String? zipCode;
  final String? avatar;
  final String role;
  final DateTime? createdAt;

  UserProfileDto({
    required this.uuid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.country,
    this.city,
    this.address,
    this.zipCode,
    this.avatar,
    required this.role,
    this.createdAt,
  });

  factory UserProfileDto.fromEntities({
    required UserEntity user,
    required UserInformation information,
  }) {
    return UserProfileDto(
      uuid: user.uuid!,
      email: user.email,
      firstName: information.firstName,
      lastName: information.lastName,
      phoneNumber: information.phoneNumber,
      country: information.country,
      city: information.city,
      address: information.address,
      zipCode: information.zipCode,
      avatar: information.avatar,
      role: information.role.value,
      createdAt: user.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      if (zipCode != null) 'zip_code': zipCode,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
