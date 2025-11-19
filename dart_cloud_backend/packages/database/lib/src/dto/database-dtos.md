# Data Transfer Objects (DTOs)

This directory contains DTO (Data Transfer Object) models that separate internal database logic from frontend API responses.

## Architecture Principles

### Internal vs External Separation

1. **Internal (Database Layer)**

   - Uses `id` (integer) for database operations and foreign key relationships
   - Entity classes (`UserEntity`, `Organization`, etc.) represent database tables
   - Relationship classes (`UserWithInformation`, `OrganizationWithMembers`) for complex queries
   - Never exposed directly to frontend

2. **External (API Layer)**
   - Uses `uuid` (string) for all frontend communication
   - DTO classes transform entities into frontend-safe objects
   - Removes sensitive data (password_hash, internal IDs)
   - Provides clean, consistent JSON structure

## DTO Models

### User DTOs

#### `UserDto`

Basic user information for API responses.

```dart
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

#### `UserInformationDto`

User profile details.

```dart
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "country": "USA",
  "city": "New York",
  "address": "123 Main St",
  "zip_code": "10001",
  "avatar": "https://example.com/avatar.jpg",
  "role": "developer"
}
```

#### `UserProfileDto`

Complete user profile (user + information).

```dart
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "country": "USA",
  "city": "New York",
  "address": "123 Main St",
  "zip_code": "10001",
  "avatar": "https://example.com/avatar.jpg",
  "role": "developer",
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### Organization DTOs

#### `OrganizationDto`

Basic organization information.

```dart
{
  "uuid": "660e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corp",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

#### `OrganizationMemberDto`

Organization member with user profile.

**Note**: The `uuid` field is only included if the requester is the organization owner. For non-owners, member UUIDs are hidden for privacy.

**Owner view**:

```dart
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "member@example.com",
  "first_name": "Jane",
  "last_name": "Smith",
  "phone_number": "+1234567890",
  "avatar": "https://example.com/avatar.jpg",
  "role": "developer",
  "joined_at": "2024-01-01T00:00:00.000Z"
}
```

**Non-owner view**:

```dart
{
  "email": "member@example.com",
  "first_name": "Jane",
  "last_name": "Smith",
  "phone_number": "+1234567890",
  "avatar": "https://example.com/avatar.jpg",
  "role": "developer",
  "joined_at": "2024-01-01T00:00:00.000Z"
}
```

#### `OrganizationWithMembersDto`

Organization with all members.

```dart
{
  "uuid": "660e8400-e29b-41d4-a716-446655440000",
  "name": "Acme Corp",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "members": [
    {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "email": "member@example.com",
      "first_name": "Jane",
      "last_name": "Smith",
      "role": "developer",
      "joined_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "member_count": 1,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

#### `UserWithOrganizationDto`

User with their organization.

```dart
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "developer",
  "organization": {
    "uuid": "660e8400-e29b-41d4-a716-446655440000",
    "name": "Acme Corp",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

## Usage in Handlers

### Converting Entities to DTOs

```dart
// Single organization
final org = await DatabaseManagers.organizations.findByUuid(orgId);
final dto = OrganizationDto.fromEntity(org);
return Response.ok(jsonEncode(dto.toJson()));

// Organization with members (with ownership check)
final orgWithMembers = await DatabaseManagers.instance.getOrganizationWithMembers(
  organizationId: orgId,
);
final dto = OrganizationWithMembersDto.fromEntities(
  organization: orgWithMembers.organization,
  members: orgWithMembers.members,
  requesterId: userId, // Pass requester ID to control UUID visibility
);
return Response.ok(jsonEncode(dto.toJson()));

// User profile
final user = await DatabaseManagers.users.findByUuid(userId);
final info = await DatabaseManagers.userInformation.findOne(
  where: {'user_id': userId},
);
final dto = UserProfileDto.fromEntities(
  user: user,
  information: info,
);
return Response.ok(jsonEncode(dto.toJson()));
```

## Privacy Features

### Conditional UUID Exposure

The `OrganizationWithMembersDto` implements privacy controls based on requester ownership:

- **Owner**: Can see all member UUIDs (for management purposes)
- **Non-owner**: Member UUIDs are hidden (privacy protection)

This prevents non-owners from accessing member identifiers while still showing organization membership information.

```dart
// Owner request (userId matches organization.ownerId)
final dto = OrganizationWithMembersDto.fromEntities(
  organization: org,
  members: members,
  requesterId: ownerId, // isOwner = true
);
// Result: members[].uuid = "550e8400-..."

// Non-owner request
final dto = OrganizationWithMembersDto.fromEntities(
  organization: org,
  members: members,
  requesterId: nonOwnerId, // isOwner = false
);
// Result: members[].uuid = null (field omitted from JSON)
```

## Benefits

1. **Security**: Sensitive data (IDs, password hashes) never exposed to frontend
2. **Privacy**: Member UUIDs only visible to organization owners
3. **Consistency**: All API responses use UUIDs, not internal IDs
4. **Flexibility**: Easy to change internal structure without breaking API
5. **Type Safety**: Compile-time checks for all transformations
6. **Maintainability**: Clear separation between database and API layers
7. **Documentation**: DTOs serve as API contract documentation

## Best Practices

1. **Never expose entities directly** - Always use DTOs for API responses
2. **Use UUIDs in frontend** - All client-side references use UUIDs
3. **Use IDs internally** - Database operations use integer IDs for efficiency
4. **Keep DTOs simple** - Only include data needed by frontend
5. **Document changes** - Update this README when adding new DTOs
6. **Validate at boundaries** - DTOs are the validation point for outgoing data

## Migration Guide

### Before (Direct Entity Exposure)

```dart
final org = await DatabaseManagers.organizations.findByUuid(orgId);
return Response.ok(jsonEncode(org.toMap())); // ❌ Exposes internal structure
```

### After (Using DTOs)

```dart
final org = await DatabaseManagers.organizations.findByUuid(orgId);
final dto = OrganizationDto.fromEntity(org);
return Response.ok(jsonEncode(dto.toJson())); // ✅ Clean API response
```

## Testing DTOs

```dart
test('OrganizationDto serialization', () {
  final org = Organization(
    uuid: 'test-uuid',
    name: 'Test Org',
    ownerId: 'owner-uuid',
  );

  final dto = OrganizationDto.fromEntity(org);
  final json = dto.toJson();

  expect(json['uuid'], 'test-uuid');
  expect(json['name'], 'Test Org');
  expect(json['owner_id'], 'owner-uuid');
  expect(json.containsKey('id'), false); // Internal ID not exposed
});
```
