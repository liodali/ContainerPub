# Database Managers with Relationship Mixins - Usage Guide

Complete guide for using the integrated DatabaseManagers with relationship support through mixins.

## 🎯 Overview

The `DatabaseManagers` class now includes relationship management capabilities through mixins:
- **RelationshipManager** - Core join query functionality
- **UserRelationships** - User-specific relationship queries
- **OrganizationRelationships** - Organization and team management

## 🏗️ Architecture

```dart
class DatabaseManagers 
  with RelationshipManager, 
       UserRelationships, 
       OrganizationRelationships {
  
  // Static entity managers
  static final users = DatabaseManagerQuery<UserEntity>(...);
  static final userInformation = DatabaseManagerQuery<UserInformation>(...);
  static final organizations = DatabaseManagerQuery<Organization>(...);
  static final organizationTeams = DatabaseManagerQuery<OrganizationTeam>(...);
  static final organizationTeamMembers = DatabaseManagerQuery<OrganizationTeamMember>(...);
  
  // Singleton instance for relationship methods
  static DatabaseManagers get instance => _instance;
}
```

## 🚀 Usage Patterns

### Pattern 1: Static Entity Managers (CRUD Operations)

Use static managers for basic CRUD operations:

```dart
// Create user
final user = await DatabaseManagers.users.insert({
  'email': 'user@example.com',
  'password_hash': hashedPassword,
});

// Find user by UUID
final user = await DatabaseManagers.users.findByUuid('user-uuid');

// Update user
await DatabaseManagers.users.updateById('user-uuid', {
  'email': 'newemail@example.com',
});

// Delete user
await DatabaseManagers.users.deleteById('user-uuid');

// Query users
final users = await DatabaseManagers.users.findAll(
  where: {'email': 'user@example.com'},
  limit: 10,
);
```

### Pattern 2: Instance Relationship Methods

Use the singleton instance for relationship queries:

```dart
// Get user with complete information
final userComplete = await DatabaseManagers.instance.getUserComplete(
  userId: 'user-uuid',
);

// Get organization with all teams and members
final orgComplete = await DatabaseManagers.instance.getOrganizationComplete(
  organizationId: 'org-uuid',
);

// Execute custom join query
final results = await DatabaseManagers.instance.executeJoinQuery(
  baseTable: 'users',
  joins: [
    JoinConfig(
      table: 'user_information',
      on: 'users.uuid = user_information.user_id',
      type: JoinType.inner,
    ),
  ],
  where: {'users.email': 'user@example.com'},
);
```

## 📋 Complete Examples

### Example 1: User Onboarding with Relationships

```dart
import 'package:database/database.dart';

Future<void> onboardUser({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String organizationName,
}) async {
  // 1. Create user (static manager)
  final user = await DatabaseManagers.users.insert({
    'email': email,
    'password_hash': hashPassword(password),
  });

  // 2. Create user information (static manager)
  await DatabaseManagers.userInformation.insert({
    'user_id': user.uuid,
    'first_name': firstName,
    'last_name': lastName,
    'role': 'developer',
  });

  // 3. Create organization (static manager)
  await DatabaseManagers.organizations.insert({
    'name': organizationName,
    'user_id': user.uuid,
  });

  // 4. Get complete user profile (instance relationship method)
  final userComplete = await DatabaseManagers.instance.getUserComplete(
    userId: user.uuid!,
  );

  print('User onboarded: ${userComplete?.user.email}');
  print('Name: ${userComplete?.userInformation.firstName} ${userComplete?.userInformation.lastName}');
  print('Organization: ${userComplete?.organization.name}');
}
```

### Example 2: Organization and Team Management

```dart
import 'package:database/database.dart';

Future<void> setupOrganizationTeams({
  required String organizationId,
  required List<String> teamNames,
  required Map<String, List<String>> teamMembers, // teamName -> userIds
}) async {
  // 1. Create teams (static manager)
  final teams = <OrganizationTeam>[];
  for (final teamName in teamNames) {
    final team = await DatabaseManagers.organizationTeams.insert({
      'name': teamName,
      'description': 'Team for $teamName',
      'organization_id': organizationId,
    });
    teams.add(team);
  }

  // 2. Add members to teams (instance relationship method)
  for (final team in teams) {
    final memberIds = teamMembers[team.name] ?? [];
    for (final userId in memberIds) {
      await DatabaseManagers.instance.addUserToTeam(
        teamId: team.uuid!,
        userId: userId,
      );
    }
  }

  // 3. Get complete organization structure (instance relationship method)
  final orgComplete = await DatabaseManagers.instance.getOrganizationComplete(
    organizationId: organizationId,
  );

  print('Organization setup complete');
  print('Total teams: ${orgComplete?.teams.length}');
  print('Total members: ${orgComplete?.totalMembers}');
  
  // Print team details
  for (final team in orgComplete!.teams) {
    print('\nTeam: ${team.team.name}');
    print('Members: ${team.members.length}');
    for (final member in team.members) {
      final name = member.information != null
          ? '${member.information!.firstName} ${member.information!.lastName}'
          : member.user.email;
      print('  - $name');
    }
  }
}
```

### Example 3: Query Users by Role and Organization

```dart
import 'package:database/database.dart';

Future<void> listDevelopersInOrganization(String organizationId) async {
  // Get all users in organization (instance relationship method)
  final orgUsers = await DatabaseManagers.instance.getUsersByOrganization(
    organizationId: organizationId,
    limit: 100,
  );

  // Filter developers
  final developers = orgUsers.where(
    (user) => user.information.role == Role.developer,
  ).toList();

  print('Developers in organization: ${developers.length}');
  for (final dev in developers) {
    print('- ${dev.information.firstName} ${dev.information.lastName}');
    print('  Email: ${dev.user.email}');
    print('  Country: ${dev.information.country}');
  }
}

// Or use the convenience method
Future<void> listAllDevelopers() async {
  final developers = await DatabaseManagers.instance.getDevelopers(
    limit: 50,
    offset: 0,
  );

  print('Total developers: ${developers.length}');
  for (final dev in developers) {
    print('${dev.information.firstName} ${dev.information.lastName} - ${dev.user.email}');
  }
}
```

### Example 4: Team Membership Management

```dart
import 'package:database/database.dart';

class TeamManager {
  final dbInstance = DatabaseManagers.instance;

  Future<void> addMemberToTeam(String teamId, String userId) async {
    final success = await dbInstance.addUserToTeam(
      teamId: teamId,
      userId: userId,
    );

    if (success) {
      print('User added to team successfully');
    } else {
      print('Failed to add user to team');
    }
  }

  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    final removed = await dbInstance.removeUserFromTeam(
      teamId: teamId,
      userId: userId,
    );

    if (removed) {
      print('User removed from team');
    } else {
      print('User was not in team');
    }
  }

  Future<bool> checkMembership(String teamId, String userId) async {
    return await dbInstance.isUserInTeam(
      teamId: teamId,
      userId: userId,
    );
  }

  Future<List<OrganizationTeam>> getUserTeams(String userId) async {
    return await dbInstance.getUserTeams(userId: userId);
  }

  Future<int> getTeamSize(String teamId) async {
    return await dbInstance.getTeamMemberCount(teamId: teamId);
  }

  Future<TeamWithMembers?> getTeamDetails(String teamId) async {
    return await dbInstance.getTeamWithMembers(teamId: teamId);
  }
}
```

### Example 5: Custom Join Queries

```dart
import 'package:database/database.dart';

Future<void> customQueries() async {
  final db = DatabaseManagers.instance;

  // Complex multi-table join
  final results = await db.executeJoinQuery(
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
    where: {
      'user_information.country': 'USA',
      'user_information.role': 'developer',
    },
    orderBy: 'users.created_at',
    orderDirection: 'DESC',
    limit: 20,
  );

  for (final row in results) {
    print('${row['first_name']} ${row['last_name']}');
    print('  Email: ${row['email']}');
    print('  Organization: ${row['org_name']}');
    print('  Teams: ${row['team_count']}');
  }
}
```

## 🎨 Best Practices

### 1. Use Static Managers for Simple CRUD

```dart
// ✅ Good - Direct CRUD operation
final user = await DatabaseManagers.users.findByUuid(userId);

// ❌ Avoid - Unnecessary complexity
final db = DatabaseManagers.instance;
// ... then use static manager anyway
```

### 2. Use Instance for Relationships

```dart
// ✅ Good - Relationship query
final userComplete = await DatabaseManagers.instance.getUserComplete(
  userId: userId,
);

// ❌ Avoid - Multiple separate queries
final user = await DatabaseManagers.users.findByUuid(userId);
final info = await DatabaseManagers.userInformation.findOne(
  where: {'user_id': userId},
);
final org = await DatabaseManagers.organizations.findOne(
  where: {'user_id': userId},
);
```

### 3. Cache the Instance Reference

```dart
// ✅ Good - Cache instance in class
class UserService {
  final db = DatabaseManagers.instance;
  
  Future<UserWithInformation?> getUser(String id) {
    return db.getUserWithInformation(userId: id);
  }
}

// ❌ Avoid - Repeated instance access
Future<void> multipleOperations() async {
  await DatabaseManagers.instance.getUserComplete(userId: id1);
  await DatabaseManagers.instance.getUserComplete(userId: id2);
  await DatabaseManagers.instance.getUserComplete(userId: id3);
}
```

### 4. Use Transactions for Multi-Step Operations

```dart
// ✅ Good - Atomic operation
await Database.transaction((conn) async {
  final user = await DatabaseManagers.users.insert({...});
  await DatabaseManagers.userInformation.insert({...});
  await DatabaseManagers.organizations.insert({...});
});
```

## 📊 API Reference

### Static Entity Managers

- `DatabaseManagers.users` - User CRUD operations
- `DatabaseManagers.userInformation` - User information CRUD
- `DatabaseManagers.organizations` - Organization CRUD
- `DatabaseManagers.organizationTeams` - Team CRUD
- `DatabaseManagers.organizationTeamMembers` - Team membership CRUD

### Instance Relationship Methods

**User Relationships:**
- `getUserComplete(userId)` - User + Information + Organization
- `getUserWithInformation(userId)` - User + Information
- `getUserWithOrganization(userId)` - User + Organization
- `getAllUsersWithInformation({role, limit, offset})` - List users with info
- `getUsersByOrganization(organizationId, {limit, offset})` - Org users
- `getDevelopers({limit, offset})` - Developer users
- `getTeamMembers({limit, offset})` - Team users

**Organization Relationships:**
- `getOrganizationWithTeams(organizationId)` - Org + Teams
- `getTeamWithMembers(teamId)` - Team + Members
- `getOrganizationComplete(organizationId)` - Org + Teams + Members
- `addUserToTeam(teamId, userId)` - Add member
- `removeUserFromTeam(teamId, userId)` - Remove member
- `getUserTeams(userId)` - User's teams
- `isUserInTeam(teamId, userId)` - Check membership
- `getTeamMemberCount(teamId)` - Count members

**Core Relationship Methods:**
- `executeJoinQuery({...})` - Custom join queries
- `getOneToOne({...})` - One-to-one relationship
- `getOneToMany({...})` - One-to-many relationship
- `getManyToMany({...})` - Many-to-many relationship

## 🔗 Related Documentation

- [RELATIONSHIP_SYSTEM.md](./RELATIONSHIP_SYSTEM.md) - System architecture
- [RELATIONSHIP_USAGE.md](./RELATIONSHIP_USAGE.md) - Detailed usage examples
- [Database System Docs](../../../docs_site/dev_docs/content/docs/database-system.md)

---

**Last Updated:** November 2025  
**Version:** 2.0.0 (Mixin Architecture)
