import 'package:test/test.dart';
import 'package:database/database.dart';

void main() {
  group('UserDto', () {
    test('fromEntity creates DTO from UserEntity', () {
      final user = UserEntity(
        id: 1,
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        passwordHash: 'hashed',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final dto = UserDto.fromEntity(user);

      expect(dto.uuid, 'user-uuid-123');
      expect(dto.email, 'test@example.com');
      expect(dto.createdAt, DateTime(2024, 1, 1));
    });

    test('toJson returns correct map', () {
      final dto = UserDto(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = dto.toJson();

      expect(json['uuid'], 'user-uuid-123');
      expect(json['email'], 'test@example.com');
      expect(json['created_at'], '2024-01-01T00:00:00.000');
    });

    test('toJson handles null createdAt', () {
      final dto = UserDto(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
      );

      final json = dto.toJson();

      expect(json.containsKey('created_at'), false);
    });

    test('does not expose password hash', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        passwordHash: 'super-secret-hash',
      );

      final dto = UserDto.fromEntity(user);
      final json = dto.toJson();

      expect(json.containsKey('password_hash'), false);
      expect(json.containsKey('passwordHash'), false);
    });

    test('does not expose internal id', () {
      final user = UserEntity(
        id: 12345,
        uuid: 'user-uuid-123',
        email: 'test@example.com',
      );

      final dto = UserDto.fromEntity(user);
      final json = dto.toJson();

      expect(json.containsKey('id'), false);
    });
  });

  group('UserInformationDto', () {
    test('fromEntity creates DTO from UserInformation', () {
      final info = UserInformation(
        id: 1,
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        country: 'USA',
        city: 'New York',
        address: '123 Main St',
        zipCode: '10001',
        avatar: 'https://example.com/avatar.jpg',
        role: Role.developer,
      );

      final dto = UserInformationDto.fromEntity(info);

      expect(dto.uuid, 'info-uuid-123');
      expect(dto.firstName, 'John');
      expect(dto.lastName, 'Doe');
      expect(dto.phoneNumber, '+1234567890');
      expect(dto.country, 'USA');
      expect(dto.city, 'New York');
      expect(dto.address, '123 Main St');
      expect(dto.zipCode, '10001');
      expect(dto.avatar, 'https://example.com/avatar.jpg');
      expect(dto.role, 'developer');
    });

    test('toJson returns correct map with all fields', () {
      final dto = UserInformationDto(
        uuid: 'info-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        country: 'USA',
        city: 'New York',
        address: '123 Main St',
        zipCode: '10001',
        avatar: 'https://example.com/avatar.jpg',
        role: 'developer',
      );

      final json = dto.toJson();

      expect(json['uuid'], 'info-uuid-123');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['phone_number'], '+1234567890');
      expect(json['country'], 'USA');
      expect(json['city'], 'New York');
      expect(json['address'], '123 Main St');
      expect(json['zip_code'], '10001');
      expect(json['avatar'], 'https://example.com/avatar.jpg');
      expect(json['role'], 'developer');
    });

    test('toJson omits null optional fields', () {
      final dto = UserInformationDto(
        uuid: 'info-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        role: 'developer',
      );

      final json = dto.toJson();

      expect(json.containsKey('phone_number'), false);
      expect(json.containsKey('country'), false);
      expect(json.containsKey('city'), false);
      expect(json.containsKey('address'), false);
      expect(json.containsKey('zip_code'), false);
      expect(json.containsKey('avatar'), false);
    });

    test('handles all role types', () {
      final roles = [Role.developer, Role.team, Role.subTeamDeveloper];
      final expectedValues = ['developer', 'team', 'sub_team_developer'];

      for (var i = 0; i < roles.length; i++) {
        final info = UserInformation(
          uuid: 'info-uuid',
          userId: 'user-uuid',
          firstName: 'John',
          lastName: 'Doe',
          avatar: '',
          role: roles[i],
        );

        final dto = UserInformationDto.fromEntity(info);
        expect(dto.role, expectedValues[i]);
      }
    });
  });

  group('UserProfileDto', () {
    test('fromEntities creates DTO from user and information', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        avatar: '',
        role: Role.developer,
      );

      final dto = UserProfileDto.fromEntities(user: user, information: info);

      expect(dto.uuid, 'user-uuid-123');
      expect(dto.email, 'test@example.com');
      expect(dto.firstName, 'John');
      expect(dto.lastName, 'Doe');
      expect(dto.phoneNumber, '+1234567890');
      expect(dto.role, 'developer');
      expect(dto.createdAt, DateTime(2024, 1, 1));
    });

    test('toJson returns complete profile', () {
      final dto = UserProfileDto(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        country: 'USA',
        city: 'New York',
        address: '123 Main St',
        zipCode: '10001',
        avatar: 'https://example.com/avatar.jpg',
        role: 'developer',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = dto.toJson();

      expect(json['uuid'], 'user-uuid-123');
      expect(json['email'], 'test@example.com');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['phone_number'], '+1234567890');
      expect(json['country'], 'USA');
      expect(json['city'], 'New York');
      expect(json['address'], '123 Main St');
      expect(json['zip_code'], '10001');
      expect(json['avatar'], 'https://example.com/avatar.jpg');
      expect(json['role'], 'developer');
      expect(json['created_at'], '2024-01-01T00:00:00.000');
    });

    test('handles null information gracefully', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
      );

      final info = UserInformation(
        userId: 'user-uuid-123',
        firstName: '',
        lastName: '',
        avatar: '',
        role: Role.developer,
      );

      final dto = UserProfileDto.fromEntities(user: user, information: info);

      expect(dto.uuid, 'user-uuid-123');
      expect(dto.email, 'test@example.com');
      expect(dto.firstName, '');
      expect(dto.lastName, '');
      expect(dto.role, 'developer');
    });
  });

  group('OrganizationDto', () {
    test('fromEntity creates DTO from Organization', () {
      final org = Organization(
        id: 1,
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final dto = OrganizationDto.fromEntity(org);

      expect(dto.uuid, 'org-uuid-123');
      expect(dto.name, 'Acme Corp');
      expect(dto.ownerId, 'owner-uuid-123');
      expect(dto.createdAt, DateTime(2024, 1, 1));
      expect(dto.updatedAt, DateTime(2024, 1, 2));
    });

    test('toJson returns correct map', () {
      final dto = OrganizationDto(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = dto.toJson();

      expect(json['uuid'], 'org-uuid-123');
      expect(json['name'], 'Acme Corp');
      expect(json['owner_id'], 'owner-uuid-123');
      expect(json['created_at'], '2024-01-01T00:00:00.000');
      expect(json['updated_at'], '2024-01-02T00:00:00.000');
    });

    test('toJson omits null timestamps', () {
      final dto = OrganizationDto(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final json = dto.toJson();

      expect(json.containsKey('created_at'), false);
      expect(json.containsKey('updated_at'), false);
    });

    test('does not expose internal id', () {
      final org = Organization(
        id: 12345,
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final dto = OrganizationDto.fromEntity(org);
      final json = dto.toJson();

      expect(json.containsKey('id'), false);
    });
  });

  group('OrganizationMemberDto', () {
    test('fromEntities creates DTO with UUID when includeUuid is true', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'member@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'Jane',
        lastName: 'Smith',
        phoneNumber: '+1234567890',
        avatar: 'https://example.com/avatar.jpg',
        role: Role.developer,
      );

      final dto = OrganizationMemberDto.fromEntities(
        user: user,
        information: info,
        joinedAt: DateTime(2024, 1, 1),
        includeUuid: true,
      );

      expect(dto.uuid, 'user-uuid-123');
      expect(dto.email, 'member@example.com');
      expect(dto.firstName, 'Jane');
      expect(dto.lastName, 'Smith');
      expect(dto.phoneNumber, '+1234567890');
      expect(dto.avatar, 'https://example.com/avatar.jpg');
      expect(dto.role, 'developer');
      expect(dto.joinedAt, DateTime(2024, 1, 1));
    });

    test('fromEntities creates DTO without UUID when includeUuid is false', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'member@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: '',
        role: Role.developer,
      );

      final dto = OrganizationMemberDto.fromEntities(
        user: user,
        information: info,
        includeUuid: false,
      );

      expect(dto.uuid, null);
      expect(dto.email, 'member@example.com');
      expect(dto.firstName, 'Jane');
      expect(dto.lastName, 'Smith');
    });

    test('toJson includes UUID when not null', () {
      final dto = OrganizationMemberDto(
        uuid: 'user-uuid-123',
        email: 'member@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        role: 'developer',
      );

      final json = dto.toJson();

      expect(json['uuid'], 'user-uuid-123');
      expect(json['email'], 'member@example.com');
      expect(json['first_name'], 'Jane');
      expect(json['last_name'], 'Smith');
      expect(json['role'], 'developer');
    });

    test('toJson omits UUID when null (privacy protection)', () {
      final dto = OrganizationMemberDto(
        uuid: null,
        email: 'member@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        role: 'developer',
      );

      final json = dto.toJson();

      expect(json.containsKey('uuid'), false);
      expect(json['email'], 'member@example.com');
    });

    test('toJson omits null optional fields', () {
      final dto = OrganizationMemberDto(
        email: 'member@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        role: 'developer',
      );

      final json = dto.toJson();

      expect(json.containsKey('uuid'), false);
      expect(json.containsKey('phone_number'), false);
      expect(json.containsKey('avatar'), false);
      expect(json.containsKey('joined_at'), false);
    });

    test('handles null information gracefully', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'member@example.com',
      );

      final dto = OrganizationMemberDto.fromEntities(
        user: user,
        information: null,
      );

      expect(dto.email, 'member@example.com');
      expect(dto.firstName, '');
      expect(dto.lastName, '');
      expect(dto.role, 'developer');
    });
  });

  group('OrganizationWithMembersDto', () {
    test('fromEntities creates DTO with member UUIDs for owner', () {
      final org = Organization(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final user = UserEntity(
        uuid: 'member-uuid-123',
        email: 'member@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'member-uuid-123',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: '',
        role: Role.developer,
      );

      final member = OrganizationMemberWithInfo(
        user: user,
        information: info,
        joinedAt: DateTime(2024, 1, 1),
      );

      final dto = OrganizationWithMembersDto.fromEntities(
        organization: org,
        members: [member],
        requesterId: 'owner-uuid-123', // Owner
      );

      expect(dto.uuid, 'org-uuid-123');
      expect(dto.name, 'Acme Corp');
      expect(dto.ownerId, 'owner-uuid-123');
      expect(dto.members.length, 1);
      expect(dto.members[0].uuid, 'member-uuid-123'); // UUID visible
      expect(dto.memberCount, 1);
    });

    test('fromEntities creates DTO without member UUIDs for non-owner', () {
      final org = Organization(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final user = UserEntity(
        uuid: 'member-uuid-123',
        email: 'member@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'member-uuid-123',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: '',
        role: Role.developer,
      );

      final member = OrganizationMemberWithInfo(
        user: user,
        information: info,
      );

      final dto = OrganizationWithMembersDto.fromEntities(
        organization: org,
        members: [member],
        requesterId: 'other-user-uuid', // Not owner
      );

      expect(dto.members[0].uuid, null); // UUID hidden
    });

    test('fromEntities hides UUIDs when requesterId is null', () {
      final org = Organization(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final user = UserEntity(
        uuid: 'member-uuid-123',
        email: 'member@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'member-uuid-123',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: '',
        role: Role.developer,
      );

      final member = OrganizationMemberWithInfo(
        user: user,
        information: info,
      );

      final dto = OrganizationWithMembersDto.fromEntities(
        organization: org,
        members: [member],
        requesterId: null, // No requester
      );

      expect(dto.members[0].uuid, null); // UUID hidden
    });

    test('toJson returns complete organization with members', () {
      final dto = OrganizationWithMembersDto(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        members: [
          OrganizationMemberDto(
            uuid: 'member-uuid-123',
            email: 'member@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            role: 'developer',
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = dto.toJson();

      expect(json['uuid'], 'org-uuid-123');
      expect(json['name'], 'Acme Corp');
      expect(json['owner_id'], 'owner-uuid-123');
      expect(json['members'], isA<List>());
      expect(json['members'].length, 1);
      expect(json['member_count'], 1);
      expect(json['created_at'], '2024-01-01T00:00:00.000');
      expect(json['updated_at'], '2024-01-02T00:00:00.000');
    });

    test('memberCount is automatically calculated', () {
      final dto = OrganizationWithMembersDto(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        members: [
          OrganizationMemberDto(
            email: 'member1@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            role: 'developer',
          ),
          OrganizationMemberDto(
            email: 'member2@example.com',
            firstName: 'John',
            lastName: 'Doe',
            role: 'team',
          ),
        ],
      );

      expect(dto.memberCount, 2);
      expect(dto.toJson()['member_count'], 2);
    });

    test('handles empty members list', () {
      final dto = OrganizationWithMembersDto(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
        members: [],
      );

      expect(dto.memberCount, 0);
      expect(dto.toJson()['member_count'], 0);
      expect(dto.toJson()['members'], isEmpty);
    });
  });

  group('UserWithOrganizationDto', () {
    test('fromEntities creates DTO from user, info, and organization', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        avatar: 'https://example.com/avatar.jpg',
        role: Role.developer,
      );

      final org = Organization(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final dto = UserWithOrganizationDto.fromEntities(
        user: user,
        information: info,
        organization: org,
      );

      expect(dto.uuid, 'user-uuid-123');
      expect(dto.email, 'test@example.com');
      expect(dto.firstName, 'John');
      expect(dto.lastName, 'Doe');
      expect(dto.phoneNumber, '+1234567890');
      expect(dto.avatar, 'https://example.com/avatar.jpg');
      expect(dto.role, 'developer');
      expect(dto.organization, isNotNull);
      expect(dto.organization!.uuid, 'org-uuid-123');
      expect(dto.organization!.name, 'Acme Corp');
      expect(dto.createdAt, DateTime(2024, 1, 1));
    });

    test('toJson returns complete user with organization', () {
      final dto = UserWithOrganizationDto(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        avatar: 'https://example.com/avatar.jpg',
        role: 'developer',
        organization: OrganizationDto(
          uuid: 'org-uuid-123',
          name: 'Acme Corp',
          ownerId: 'owner-uuid-123',
        ),
        createdAt: DateTime(2024, 1, 1),
      );

      final json = dto.toJson();

      expect(json['uuid'], 'user-uuid-123');
      expect(json['email'], 'test@example.com');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['phone_number'], '+1234567890');
      expect(json['avatar'], 'https://example.com/avatar.jpg');
      expect(json['role'], 'developer');
      expect(json['organization'], isA<Map>());
      expect(json['organization']['uuid'], 'org-uuid-123');
      expect(json['organization']['name'], 'Acme Corp');
      expect(json['created_at'], '2024-01-01T00:00:00.000');
    });

    test('handles null organization', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
      );

      final info = UserInformation(
        uuid: 'info-uuid-123',
        userId: 'user-uuid-123',
        firstName: 'John',
        lastName: 'Doe',
        avatar: '',
        role: Role.developer,
      );

      final dto = UserWithOrganizationDto.fromEntities(
        user: user,
        information: info,
        organization: null,
      );

      expect(dto.organization, null);

      final json = dto.toJson();
      expect(json.containsKey('organization'), false);
    });

    test('handles null information', () {
      final user = UserEntity(
        uuid: 'user-uuid-123',
        email: 'test@example.com',
      );

      final org = Organization(
        uuid: 'org-uuid-123',
        name: 'Acme Corp',
        ownerId: 'owner-uuid-123',
      );

      final dto = UserWithOrganizationDto.fromEntities(
        user: user,
        information: null,
        organization: org,
      );

      expect(dto.firstName, '');
      expect(dto.lastName, '');
      expect(dto.role, 'developer');
    });
  });

  group('DTO Privacy and Security', () {
    test('no DTO exposes internal SERIAL id', () {
      final user = UserEntity(
        id: 12345,
        uuid: 'uuid',
        email: 'test@example.com',
      );
      final userDto = UserDto.fromEntity(user);
      expect(userDto.toJson().containsKey('id'), false);

      final info = UserInformation(
        id: 67890,
        uuid: 'uuid',
        userId: 'user-uuid',
        firstName: 'John',
        lastName: 'Doe',
        avatar: '',
        role: Role.developer,
      );
      final infoDto = UserInformationDto.fromEntity(info);
      expect(infoDto.toJson().containsKey('id'), false);

      final org = Organization(
        id: 11111,
        uuid: 'uuid',
        name: 'Acme',
        ownerId: 'owner-uuid',
      );
      final orgDto = OrganizationDto.fromEntity(org);
      expect(orgDto.toJson().containsKey('id'), false);
    });

    test('no DTO exposes password hash', () {
      final user = UserEntity(
        uuid: 'uuid',
        email: 'test@example.com',
        passwordHash: 'super-secret',
      );

      final userDto = UserDto.fromEntity(user);
      final json = userDto.toJson();

      expect(json.containsKey('password_hash'), false);
      expect(json.containsKey('passwordHash'), false);
    });

    test('member UUID visibility is controlled by ownership', () {
      final org = Organization(
        uuid: 'org-uuid',
        name: 'Acme',
        ownerId: 'owner-uuid',
      );

      final user = UserEntity(uuid: 'member-uuid', email: 'member@example.com');
      final info = UserInformation(
        uuid: 'info-uuid',
        userId: 'member-uuid',
        firstName: 'Jane',
        lastName: 'Smith',
        avatar: '',
        role: Role.developer,
      );
      final member = OrganizationMemberWithInfo(user: user, information: info);

      // Owner can see UUIDs
      final ownerDto = OrganizationWithMembersDto.fromEntities(
        organization: org,
        members: [member],
        requesterId: 'owner-uuid',
      );
      expect(ownerDto.members[0].uuid, 'member-uuid');

      // Non-owner cannot see UUIDs
      final nonOwnerDto = OrganizationWithMembersDto.fromEntities(
        organization: org,
        members: [member],
        requesterId: 'other-uuid',
      );
      expect(nonOwnerDto.members[0].uuid, null);
    });

    test('all DTOs use snake_case for JSON keys', () {
      final userProfile = UserProfileDto(
        uuid: 'uuid',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+123',
        zipCode: '10001',
        role: 'developer',
      );

      final json = userProfile.toJson();

      expect(json.containsKey('firstName'), false);
      expect(json.containsKey('lastName'), false);
      expect(json.containsKey('phoneNumber'), false);
      expect(json.containsKey('zipCode'), false);

      expect(json.containsKey('first_name'), true);
      expect(json.containsKey('last_name'), true);
      expect(json.containsKey('phone_number'), true);
      expect(json.containsKey('zip_code'), true);
    });
  });
}
