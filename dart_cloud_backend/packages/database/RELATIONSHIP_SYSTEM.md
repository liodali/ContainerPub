# Database Relationship System

Complete documentation for the enhanced database manager query system with relationship support.

## 📋 Overview

The relationship system extends the database package with powerful relationship management capabilities, supporting complex queries across multiple tables with type-safe results.

## 🏗️ Architecture

### Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     User Entity System                       │
└─────────────────────────────────────────────────────────────┘

UserEntity (users table)
    │
    ├─── UserInformation (user_information table)
    │    └─ One-to-One relationship via user_id
    │    └─ Fields: firstName, lastName, phoneNumber, country,
    │               city, address, zipCode, avatar, role
    │
    └─── Organization (organizations table)
         └─ One-to-One relationship via user_id
         └─ Fields: name, userId
              │
              └─── OrganizationTeam (organization_teams table)
                   └─ One-to-Many relationship via organization_id
                   └─ Fields: name, description, organizationId
                        │
                        └─── OrganizationTeamMember (organization_team_members table)
                             └─ Many-to-Many relationship (junction table)
                             └─ Links: teamId ↔ userId
```

### Role System

```dart
enum Role {
  developer,        // Individual developer
  team,            // Team lead/manager
  subTeamDeveloper // Developer within a team
}
```

## 📦 Components

### 1. Core Entities

**Created Files:**
- `lib/src/entities/user_information.dart` - User profile information
- `lib/src/entities/organization.dart` - Organization entity
- `lib/src/entities/organization_team.dart` - Team entity
- `lib/src/entities/organization_team_member.dart` - Team membership junction

### 2. Relationship Managers

**Created Files:**
- `lib/src/relationship_manager.dart` - Core relationship query engine
- `lib/src/managers/user_relationship_manager.dart` - User-specific relationships
- `lib/src/managers/organization_relationship_manager.dart` - Organization-specific relationships

### 3. Database Managers

**Updated File:**
- `lib/src/managers.dart` - Added managers for new entities:
  - `DatabaseManagers.userInformation`
  - `DatabaseManagers.organizations`
  - `DatabaseManagers.organizationTeams`
  - `DatabaseManagers.organizationTeamMembers`

## 🎯 Key Features

### 1. Type-Safe Relationship Queries

```dart
// Get user with all related data
final user = await UserRelationshipManager.getUserComplete(
  userId: 'uuid',
);

// Result is strongly typed
UserWithInformationAndOrganization {
  user: UserEntity,
  userInformation: UserInformation,
  organization: Organization,
}
```

### 2. Flexible Join Configurations

```dart
final results = await RelationshipManager.executeJoinQuery(
  baseTable: 'users',
  joins: [
    JoinConfig(
      table: 'user_information',
      on: 'users.uuid = user_information.user_id',
      type: JoinType.inner,
    ),
    JoinConfig(
      table: 'organizations',
      on: 'users.uuid = organizations.user_id',
      type: JoinType.left,
    ),
  ],
  where: {'users.email': 'user@example.com'},
);
```

### 3. Composite Result Objects

**UserWithInformationAndOrganization:**
- Complete user profile with organization

**UserWithInformation:**
- User with profile information only

**UserWithOrganization:**
- User with organization only

**OrganizationWithTeams:**
- Organization with all its teams

**TeamWithMembers:**
- Team with all member details

**OrganizationComplete:**
- Organization with teams and all members
- Includes `totalMembers` computed property
- JSON serialization support

### 4. Team Management Operations

```dart
// Add user to team
await OrganizationRelationshipManager.addUserToTeam(
  teamId: 'team-uuid',
  userId: 'user-uuid',
);

// Remove user from team
await OrganizationRelationshipManager.removeUserFromTeam(
  teamId: 'team-uuid',
  userId: 'user-uuid',
);

// Check membership
final isMember = await OrganizationRelationshipManager.isUserInTeam(
  teamId: 'team-uuid',
  userId: 'user-uuid',
);

// Get user's teams
final teams = await OrganizationRelationshipManager.getUserTeams(
  userId: 'user-uuid',
);
```

## 🔧 Implementation Details

### Join Types

```dart
enum JoinType {
  inner,  // INNER JOIN - only matching rows
  left,   // LEFT JOIN - all from left, matching from right
  right,  // RIGHT JOIN - all from right, matching from left
  full,   // FULL JOIN - all rows from both tables
}
```

### Query Execution Flow

```
1. Build JoinConfig objects
   ↓
2. Generate SQL with joins
   ↓
3. Apply WHERE conditions
   ↓
4. Execute query
   ↓
5. Map results to entities
   ↓
6. Return type-safe objects
```

### Result Mapping

```dart
// Raw database row
Map<String, dynamic> row = {
  'id': 1,
  'uuid': 'user-uuid',
  'email': 'user@example.com',
  'first_name': 'John',
  'last_name': 'Doe',
  'role': 'developer',
  'name': 'Acme Corp',
  // ... more fields
};

// Mapped to composite object
UserWithInformationAndOrganization(
  user: UserEntity.fromMap(row),
  userInformation: UserInformation.fromMap(row),
  organization: Organization.fromMap(row),
);
```

## 📊 Database Schema

### Tables Created

1. **user_information**
   - Primary Key: `id` (SERIAL)
   - Unique Key: `uuid` (UUID)
   - Foreign Key: `user_id` → `users.uuid`
   - Unique Constraint: `user_id` (one-to-one)

2. **organizations**
   - Primary Key: `id` (SERIAL)
   - Unique Key: `uuid` (UUID)
   - Foreign Key: `user_id` → `users.uuid`
   - Unique Constraint: `user_id` (one-to-one)

3. **organization_teams**
   - Primary Key: `id` (SERIAL)
   - Unique Key: `uuid` (UUID)
   - Foreign Key: `organization_id` → `organizations.uuid`

4. **organization_team_members**
   - Primary Key: `id` (SERIAL)
   - Foreign Keys:
     - `team_id` → `organization_teams.uuid`
     - `user_id` → `users.uuid`
   - Unique Constraint: `(team_id, user_id)`

### Indexes

```sql
-- User Information
CREATE INDEX idx_user_information_user_id ON user_information(user_id);
CREATE INDEX idx_user_information_role ON user_information(role);

-- Organizations
CREATE INDEX idx_organizations_user_id ON organizations(user_id);
CREATE INDEX idx_organizations_name ON organizations(name);

-- Organization Teams
CREATE INDEX idx_organization_teams_org_id ON organization_teams(organization_id);
CREATE INDEX idx_organization_teams_name ON organization_teams(name);

-- Team Members
CREATE INDEX idx_org_team_members_team_id ON organization_team_members(team_id);
CREATE INDEX idx_org_team_members_user_id ON organization_team_members(user_id);
```

## 🚀 Usage Examples

### Complete User Onboarding Flow

```dart
// 1. Create user
final user = await DatabaseManagers.users.insert({
  'email': 'user@example.com',
  'password_hash': hashedPassword,
});

// 2. Create user information
await DatabaseManagers.userInformation.insert({
  'user_id': user.uuid,
  'first_name': 'John',
  'last_name': 'Doe',
  'phone_number': '+1234567890',
  'country': 'USA',
  'city': 'New York',
  'role': 'developer',
});

// 3. Create organization
final org = await DatabaseManagers.organizations.insert({
  'name': 'Acme Corporation',
  'user_id': user.uuid,
});

// 4. Get complete user profile
final userComplete = await UserRelationshipManager.getUserComplete(
  userId: user.uuid!,
);
```

### Organization and Team Setup

```dart
// 1. Create organization
final org = await DatabaseManagers.organizations.insert({
  'name': 'Tech Startup',
  'user_id': ownerUserId,
});

// 2. Create teams
final engineeringTeam = await DatabaseManagers.organizationTeams.insert({
  'name': 'Engineering',
  'description': 'Core engineering team',
  'organization_id': org.uuid,
});

final designTeam = await DatabaseManagers.organizationTeams.insert({
  'name': 'Design',
  'description': 'Product design team',
  'organization_id': org.uuid,
});

// 3. Add members to teams
await OrganizationRelationshipManager.addUserToTeam(
  teamId: engineeringTeam.uuid!,
  userId: developer1UserId,
);

await OrganizationRelationshipManager.addUserToTeam(
  teamId: engineeringTeam.uuid!,
  userId: developer2UserId,
);

// 4. Get complete organization structure
final orgComplete = await OrganizationRelationshipManager.getOrganizationComplete(
  organizationId: org.uuid!,
);

print('Total teams: ${orgComplete.teams.length}');
print('Total members: ${orgComplete.totalMembers}');
```

### Query Users by Role

```dart
// Get all developers
final developers = await UserRelationshipManager.getDevelopers(
  limit: 20,
  offset: 0,
);

// Get team leads
final teamLeads = await UserRelationshipManager.getTeamMembers(
  limit: 20,
  offset: 0,
);

// Get users by specific role
final allUsers = await UserRelationshipManager.getAllUsersWithInformation(
  role: Role.subTeamDeveloper,
  limit: 50,
);
```

## 🔍 Advanced Queries

### Custom Multi-Table Join

```dart
final results = await RelationshipManager.executeJoinQuery(
  baseTable: 'users',
  joins: [
    JoinConfig(
      table: 'user_information',
      on: 'users.uuid = user_information.user_id',
      type: JoinType.inner,
    ),
    JoinConfig(
      table: 'organizations',
      on: 'users.uuid = organizations.user_id',
      type: JoinType.left,
    ),
    JoinConfig(
      table: 'organization_teams',
      on: 'organizations.uuid = organization_teams.organization_id',
      type: JoinType.left,
    ),
  ],
  select: [
    'users.email',
    'user_information.first_name',
    'user_information.last_name',
    'user_information.role',
    'organizations.name as org_name',
    'COUNT(organization_teams.id) as team_count',
  ],
  where: {'user_information.country': 'USA'},
  orderBy: 'users.created_at',
  orderDirection: 'DESC',
  limit: 100,
);
```

### Relationship Helpers

```dart
// One-to-One
final userInfo = await RelationshipManager.getOneToOne(
  baseTable: 'users',
  relatedTable: 'user_information',
  baseKey: 'uuid',
  relatedKey: 'user_id',
  keyValue: userId,
);

// One-to-Many
final teams = await RelationshipManager.getOneToMany(
  baseTable: 'organizations',
  relatedTable: 'organization_teams',
  foreignKey: 'organization_id',
  parentId: orgId,
);

// Many-to-Many
final teamMembers = await RelationshipManager.getManyToMany(
  baseTable: 'organization_teams',
  relatedTable: 'users',
  pivotTable: 'organization_team_members',
  baseForeignKey: 'team_id',
  relatedForeignKey: 'user_id',
  baseId: teamId,
);
```

## 📝 Migration

Run the migration to create all necessary tables:

```bash
psql -U dart_cloud -d dart_cloud -f migrations/003_add_user_relationships.sql
```

Or use your migration tool of choice.

## 🎯 Best Practices

1. **Use Relationship Managers** for complex queries instead of manual joins
2. **Leverage Pagination** with `limit` and `offset` for large datasets
3. **Handle Null Results** appropriately
4. **Use Transactions** for multi-step operations
5. **Index Foreign Keys** for better query performance
6. **Validate Role Values** before inserting
7. **Use UUID** for all entity references
8. **Cache Frequently Accessed** relationships

## 🔗 Files Created/Modified

### New Files
- `lib/src/entities/user_information.dart`
- `lib/src/entities/organization.dart`
- `lib/src/entities/organization_team.dart`
- `lib/src/entities/organization_team_member.dart`
- `lib/src/relationship_manager.dart`
- `lib/src/managers/user_relationship_manager.dart`
- `lib/src/managers/organization_relationship_manager.dart`
- `migrations/003_add_user_relationships.sql`
- `RELATIONSHIP_USAGE.md`
- `RELATIONSHIP_SYSTEM.md`

### Modified Files
- `lib/database.dart` - Added exports
- `lib/src/managers.dart` - Added new managers
- `lib/src/entities/user_entity.dart` - Added composite classes

## 📚 Documentation

- [Usage Guide](./RELATIONSHIP_USAGE.md) - Comprehensive usage examples
- [Database System](../../../docs_site/dev_docs/content/docs/database-system.md) - Overall database documentation
- [Database Quick Reference](../../../docs_site/dev_docs/content/docs/database-quick-reference.md) - Quick reference guide

---

**Last Updated:** November 2025  
**Version:** 1.0.0
