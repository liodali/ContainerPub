# Database Relationship Manager Usage Guide

Comprehensive guide for using the relationship managers to handle complex queries with joins between users, user information, organizations, and teams.

## 📋 Overview

The relationship manager system provides:

- **User Relationships** - Link users with their information and organizations
- **Organization Relationships** - Manage organizations, teams, and team members
- **Complex Queries** - Execute multi-table joins efficiently
- **Type-Safe Results** - Strongly typed result objects

## 🏗️ Architecture

```
Users
  ├─ UserInformation (one-to-one)
  └─ Organization (one-to-one)
       └─ OrganizationTeams (one-to-many)
            └─ TeamMembers (many-to-many via junction table)
```

## 🚀 User Relationships

### Get User with Complete Information

```dart
import 'package:database/database.dart';

// Get user with information and organization
final userComplete = await UserRelationshipManager.getUserComplete(
  userId: 'user-uuid-here',
);

if (userComplete != null) {
  print('User: ${userComplete.user.email}');
  print('Name: ${userComplete.userInformation.firstName} ${userComplete.userInformation.lastName}');
  print('Role: ${userComplete.userInformation.role.value}');
  print('Organization: ${userComplete.organization.name}');
}
```

### Get User with Information Only

```dart
final userWithInfo = await UserRelationshipManager.getUserWithInformation(
  userId: 'user-uuid-here',
);

if (userWithInfo != null) {
  print('Email: ${userWithInfo.user.email}');
  print('Full Name: ${userWithInfo.information.firstName} ${userWithInfo.information.lastName}');
  print('Phone: ${userWithInfo.information.phoneNumber}');
  print('Country: ${userWithInfo.information.country}');
}
```

### Get User with Organization Only

```dart
final userWithOrg = await UserRelationshipManager.getUserWithOrganization(
  userId: 'user-uuid-here',
);

if (userWithOrg != null) {
  print('User: ${userWithOrg.user.email}');
  print('Organization: ${userWithOrg.organization.name}');
}
```

### Get All Users by Role

```dart
// Get all developers
final developers = await UserRelationshipManager.getDevelopers(
  limit: 10,
  offset: 0,
);

for (final dev in developers) {
  print('Developer: ${dev.information.firstName} ${dev.information.lastName}');
  print('Email: ${dev.user.email}');
}

// Get all team members
final teamMembers = await UserRelationshipManager.getTeamMembers(
  limit: 10,
  offset: 0,
);
```

### Get Users by Organization

```dart
final orgUsers = await UserRelationshipManager.getUsersByOrganization(
  organizationId: 'org-uuid-here',
  limit: 20,
  offset: 0,
);

print('Organization has ${orgUsers.length} users');
for (final user in orgUsers) {
  print('- ${user.information.firstName} ${user.information.lastName} (${user.information.role.value})');
}
```

## 🏢 Organization Relationships

### Get Organization with Teams

```dart
final orgWithTeams = await OrganizationRelationshipManager.getOrganizationWithTeams(
  organizationId: 'org-uuid-here',
);

if (orgWithTeams != null) {
  print('Organization: ${orgWithTeams.organization.name}');
  print('Teams: ${orgWithTeams.teams.length}');
  
  for (final team in orgWithTeams.teams) {
    print('  - ${team.name}: ${team.description}');
  }
}
```

### Get Team with Members

```dart
final teamWithMembers = await OrganizationRelationshipManager.getTeamWithMembers(
  teamId: 'team-uuid-here',
);

if (teamWithMembers != null) {
  print('Team: ${teamWithMembers.team.name}');
  print('Members: ${teamWithMembers.members.length}');
  
  for (final member in teamWithMembers.members) {
    print('  - ${member.user.email}');
    if (member.information != null) {
      print('    Name: ${member.information!.firstName} ${member.information!.lastName}');
      print('    Role: ${member.information!.role.value}');
    }
    if (member.joinedAt != null) {
      print('    Joined: ${member.joinedAt}');
    }
  }
}
```

### Get Complete Organization (with teams and members)

```dart
final orgComplete = await OrganizationRelationshipManager.getOrganizationComplete(
  organizationId: 'org-uuid-here',
);

if (orgComplete != null) {
  print('Organization: ${orgComplete.organization.name}');
  print('Total Teams: ${orgComplete.teams.length}');
  print('Total Members: ${orgComplete.totalMembers}');
  
  for (final team in orgComplete.teams) {
    print('\nTeam: ${team.team.name}');
    print('Members: ${team.members.length}');
    
    for (final member in team.members) {
      final name = member.information != null
          ? '${member.information!.firstName} ${member.information!.lastName}'
          : member.user.email;
      print('  - $name');
    }
  }
  
  // Convert to JSON
  final json = orgComplete.toJson();
  print(json);
}
```

## 👥 Team Management

### Add User to Team

```dart
final success = await OrganizationRelationshipManager.addUserToTeam(
  teamId: 'team-uuid-here',
  userId: 'user-uuid-here',
);

if (success) {
  print('User added to team successfully');
} else {
  print('Failed to add user to team');
}
```

### Remove User from Team

```dart
final removed = await OrganizationRelationshipManager.removeUserFromTeam(
  teamId: 'team-uuid-here',
  userId: 'user-uuid-here',
);

if (removed) {
  print('User removed from team');
} else {
  print('User was not in team or removal failed');
}
```

### Get User's Teams

```dart
final userTeams = await OrganizationRelationshipManager.getUserTeams(
  userId: 'user-uuid-here',
);

print('User is member of ${userTeams.length} teams:');
for (final team in userTeams) {
  print('  - ${team.name}');
}
```

### Check Team Membership

```dart
final isMember = await OrganizationRelationshipManager.isUserInTeam(
  teamId: 'team-uuid-here',
  userId: 'user-uuid-here',
);

if (isMember) {
  print('User is a team member');
} else {
  print('User is not a team member');
}
```

### Get Team Member Count

```dart
final memberCount = await OrganizationRelationshipManager.getTeamMemberCount(
  teamId: 'team-uuid-here',
);

print('Team has $memberCount members');
```

## 🔧 Direct Database Managers

### User Information Manager

```dart
// Create user information
final userInfo = await DatabaseManagers.userInformation.insert({
  'user_id': 'user-uuid-here',
  'first_name': 'John',
  'last_name': 'Doe',
  'phone_number': '+1234567890',
  'country': 'USA',
  'city': 'New York',
  'address': '123 Main St',
  'zip_code': '10001',
  'avatar': 'https://example.com/avatar.jpg',
  'role': 'developer',
});

// Find by user ID
final info = await DatabaseManagers.userInformation.findOne(
  where: {'user_id': 'user-uuid-here'},
);

// Update user information
await DatabaseManagers.userInformation.update(
  {'phone_number': '+0987654321'},
  where: {'user_id': 'user-uuid-here'},
);
```

### Organization Manager

```dart
// Create organization
final org = await DatabaseManagers.organizations.insert({
  'name': 'Acme Corporation',
  'user_id': 'owner-user-uuid',
});

// Find by UUID
final organization = await DatabaseManagers.organizations.findByUuid('org-uuid-here');

// Find all organizations for a user
final userOrgs = await DatabaseManagers.organizations.findAll(
  where: {'user_id': 'user-uuid-here'},
);
```

### Organization Team Manager

```dart
// Create team
final team = await DatabaseManagers.organizationTeams.insert({
  'name': 'Engineering Team',
  'description': 'Core engineering team',
  'organization_id': 'org-uuid-here',
});

// Find teams by organization
final teams = await DatabaseManagers.organizationTeams.findAll(
  where: {'organization_id': 'org-uuid-here'},
  orderBy: 'created_at',
  orderDirection: 'DESC',
);

// Update team
await DatabaseManagers.organizationTeams.updateById(
  'team-uuid-here',
  {'description': 'Updated description'},
);

// Delete team
await DatabaseManagers.organizationTeams.deleteById('team-uuid-here');
```

### Organization Team Member Manager

```dart
// Add member to team
final member = await DatabaseManagers.organizationTeamMembers.insert({
  'team_id': 'team-uuid-here',
  'user_id': 'user-uuid-here',
  'joined_at': DateTime.now().toIso8601String(),
});

// Find all members of a team
final members = await DatabaseManagers.organizationTeamMembers.findAll(
  where: {'team_id': 'team-uuid-here'},
);

// Remove member from team
await DatabaseManagers.organizationTeamMembers.delete(
  where: {
    'team_id': 'team-uuid-here',
    'user_id': 'user-uuid-here',
  },
);
```

## 🔍 Custom Relationship Queries

### Execute Custom Join Query

```dart
import 'package:database/database.dart';

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
  select: [
    'users.*',
    'user_information.first_name',
    'user_information.last_name',
    'user_information.role',
    'organizations.name as org_name',
  ],
  where: {'user_information.role': 'developer'},
  orderBy: 'users.created_at',
  orderDirection: 'DESC',
  limit: 10,
);

for (final row in results) {
  print('User: ${row['email']}');
  print('Name: ${row['first_name']} ${row['last_name']}');
  print('Organization: ${row['org_name']}');
}
```

### One-to-One Relationship

```dart
final result = await RelationshipManager.getOneToOne(
  baseTable: 'users',
  relatedTable: 'user_information',
  baseKey: 'uuid',
  relatedKey: 'user_id',
  keyValue: 'user-uuid-here',
);
```

### One-to-Many Relationship

```dart
final results = await RelationshipManager.getOneToMany(
  baseTable: 'organizations',
  relatedTable: 'organization_teams',
  foreignKey: 'organization_id',
  parentId: 'org-uuid-here',
  orderBy: 'created_at',
  orderDirection: 'DESC',
);
```

### Many-to-Many Relationship

```dart
final results = await RelationshipManager.getManyToMany(
  baseTable: 'organization_teams',
  relatedTable: 'users',
  pivotTable: 'organization_team_members',
  baseForeignKey: 'team_id',
  relatedForeignKey: 'user_id',
  baseId: 'team-uuid-here',
);
```

## 📊 Result Objects

### UserWithInformationAndOrganization

```dart
class UserWithInformationAndOrganization {
  final UserEntity user;
  final UserInformation userInformation;
  final Organization organization;
  
  // Usage
  print(userComplete.user.email);
  print(userComplete.userInformation.firstName);
  print(userComplete.organization.name);
}
```

### OrganizationComplete

```dart
class OrganizationComplete {
  final Organization organization;
  final List<TeamWithMembers> teams;
  
  int get totalMembers; // Computed property
  Map<String, dynamic> toJson(); // JSON serialization
}
```

### TeamWithMembers

```dart
class TeamWithMembers {
  final OrganizationTeam team;
  final List<TeamMemberWithInfo> members;
  
  Map<String, dynamic> toJson();
}
```

## 🎯 Best Practices

### 1. Use Relationship Managers for Complex Queries

```dart
// ✅ Good - Use relationship manager
final user = await UserRelationshipManager.getUserComplete(userId: id);

// ❌ Avoid - Multiple separate queries
final user = await DatabaseManagers.users.findByUuid(id);
final info = await DatabaseManagers.userInformation.findOne(where: {'user_id': id});
final org = await DatabaseManagers.organizations.findOne(where: {'user_id': id});
```

### 2. Leverage Pagination

```dart
// Always use limit and offset for large datasets
final users = await UserRelationshipManager.getAllUsersWithInformation(
  limit: 20,
  offset: page * 20,
);
```

### 3. Handle Null Results

```dart
final user = await UserRelationshipManager.getUserComplete(userId: id);
if (user == null) {
  // Handle not found
  return Response.notFound(body: 'User not found');
}
```

### 4. Use Transactions for Multiple Operations

```dart
await DatabaseManagerQuery.transaction((connection) async {
  // Create organization
  final org = await DatabaseManagers.organizations.insert({...});
  
  // Create team
  final team = await DatabaseManagers.organizationTeams.insert({...});
  
  // Add members
  await DatabaseManagers.organizationTeamMembers.insert({...});
});
```

## 🔗 Related Documentation

- [Database System](../../../docs_site/dev_docs/content/docs/database-system.md)
- [Database Quick Reference](../../../docs_site/dev_docs/content/docs/database-quick-reference.md)
- [Entity Models](./lib/src/entities/)
- [Query Builder](./lib/src/query_builder.dart)

---

**Last Updated:** November 2025  
**Version:** 1.0.0
