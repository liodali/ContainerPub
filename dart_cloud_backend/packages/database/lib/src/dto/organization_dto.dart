import 'package:database/database.dart';

/// DTO for organization returned to frontend
class OrganizationDto {
  final String uuid;
  final String name;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationDto({
    required this.uuid,
    required this.name,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory OrganizationDto.fromEntity(Organization entity) {
    return OrganizationDto(
      uuid: entity.uuid!,
      name: entity.name,
      ownerId: entity.ownerId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'owner_id': ownerId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// DTO for organization member with user profile
class OrganizationMemberDto {
  final String? uuid; // Null if requester is not owner
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatar;
  final String role;
  final DateTime? joinedAt;

  OrganizationMemberDto({
    this.uuid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatar,
    required this.role,
    this.joinedAt,
  });

  factory OrganizationMemberDto.fromEntities({
    required UserEntity user,
    required UserInformation? information,
    DateTime? joinedAt,
    bool includeUuid = true,
  }) {
    return OrganizationMemberDto(
      uuid: includeUuid ? user.uuid : null,
      email: user.email,
      firstName: information?.firstName ?? '',
      lastName: information?.lastName ?? '',
      phoneNumber: information?.phoneNumber,
      avatar: information?.avatar,
      role: information?.role.value ?? 'developer',
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (uuid != null) 'uuid': uuid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}

/// DTO for organization with all members
class OrganizationWithMembersDto {
  final String uuid;
  final String name;
  final String ownerId;
  final List<OrganizationMemberDto> members;
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationWithMembersDto({
    required this.uuid,
    required this.name,
    required this.ownerId,
    required this.members,
    this.createdAt,
    this.updatedAt,
  }) : memberCount = members.length;

  factory OrganizationWithMembersDto.fromEntities({
    required Organization organization,
    required List<OrganizationMemberWithInfo> members,
    String? requesterId,
  }) {
    // Check if requester is the owner
    final isOwner = requesterId != null && requesterId == organization.ownerId;

    return OrganizationWithMembersDto(
      uuid: organization.uuid!,
      name: organization.name,
      ownerId: organization.ownerId,
      members: members
          .map(
            (m) => OrganizationMemberDto.fromEntities(
              user: m.user,
              information: m.information,
              joinedAt: m.joinedAt,
              includeUuid: isOwner,
            ),
          )
          .toList(),
      createdAt: organization.createdAt,
      updatedAt: organization.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'owner_id': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// DTO for user with their organization
class UserWithOrganizationDto {
  final String uuid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatar;
  final String role;
  final OrganizationDto? organization;
  final DateTime? createdAt;

  UserWithOrganizationDto({
    required this.uuid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatar,
    required this.role,
    this.organization,
    this.createdAt,
  });

  factory UserWithOrganizationDto.fromEntities({
    required UserEntity user,
    required UserInformation? information,
    Organization? organization,
  }) {
    return UserWithOrganizationDto(
      uuid: user.uuid!,
      email: user.email,
      firstName: information?.firstName ?? '',
      lastName: information?.lastName ?? '',
      phoneNumber: information?.phoneNumber,
      avatar: information?.avatar,
      role: information?.role.value ?? 'developer',
      organization: organization != null
          ? OrganizationDto.fromEntity(organization)
          : null,
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
      if (avatar != null) 'avatar': avatar,
      'role': role,
      if (organization != null) 'organization': organization!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
