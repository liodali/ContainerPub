import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_cloud_backend/config/config.dart';
import 'package:database/database.dart';

class AuthHandler {
  static Future<Response> register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Hash password
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      // Insert user
      final result = await Database.connection.execute(
        'INSERT INTO users (email, password_hash) VALUES (\$1, \$2) RETURNING id',
        parameters: [email, passwordHash],
      );

      final userId = result.first[0] as String;

      // Generate JWT
      final jwt = JWT({'userId': userId, 'email': email});
      final token = jwt.sign(SecretKey(Config.jwtSecret));

      return Response.ok(
        jsonEncode({'token': token, 'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Registration failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Email and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find user
      final result = await Database.connection.execute(
        'SELECT id, password_hash FROM users WHERE email = \$1',
        parameters: [email],
      );

      if (result.isEmpty) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid credentials'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userId = result.first[0] as String;
      final passwordHash = result.first[1] as String;

      // Verify password
      if (!BCrypt.checkpw(password, passwordHash)) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid credentials'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Generate JWT
      final jwt = JWT({'userId': userId, 'email': email});
      final token = jwt.sign(SecretKey(Config.jwtSecret));

      return Response.ok(
        jsonEncode({'token': token, 'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Login failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> onboarding(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final userId = body['userId'] as String?;
      final name = body['name'] as String?;
      final lastName = body['lastName'] as String?;
      final phoneNumber = body['phoneNumber'] as String?;
      final country = body['country'] as String?;
      final city = body['city'] as String?;
      final address = body['address'] as String?;
      final zipCode = body['zipCode'] as String?;
      final avatar = body['avatar'] as String?;
      final role = body['role'] as String?;

      if (userId == null ||
          name == null ||
          lastName == null ||
          phoneNumber == null ||
          country == null ||
          city == null ||
          address == null ||
          zipCode == null ||
          avatar == null ||
          role == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error':
                'User ID, name, last name, phone number, country, city, address, zip code, avatar, and role are required',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      await DatabaseManagers.userInformation.insert(
        UserInformation(
          userId: userId,
          firstName: name,
          lastName: lastName,
          phoneNumber: phoneNumber,
          country: country,
          city: city,
          address: address,
          zipCode: zipCode,
          avatar: avatar,
          role: Role.fromString(role),
        ).toMap(),
      );

      return Response.ok(
        jsonEncode({'message': 'User onboarding successful'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Onboarding failed: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/user/<id>/organization/ - Get organization by user ID
  static Future<Response> getOrganizationbyUser(Request request, String userId) async {
    try {
      // Get user's organization
      final org = await DatabaseManagers.instance.getUserOrganization(
        userId: userId,
      );

      if (org == null) {
        return Response.notFound(
          jsonEncode({'error': 'Organization not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get organization with members
      final orgWithMembers = await DatabaseManagers.instance.getOrganizationWithMembers(
        organizationId: org.uuid!,
      );

      if (orgWithMembers == null) {
        return Response.ok(
          jsonEncode(OrganizationDto.fromEntity(org).toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Convert to DTO (pass userId to check ownership)
      final dto = OrganizationWithMembersDto.fromEntities(
        organization: orgWithMembers.organization,
        members: orgWithMembers.members,
        requesterId: userId,
      );

      return Response.ok(
        jsonEncode(dto.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to retrieve organization: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// PATCH /api/user/<id>/organization/ - Update organization by user ID
  static Future<Response> patchOrganizationbyUser(Request request, String userId) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Organization name is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find organization by owner ID
      final org = await DatabaseManagers.organizations.findOne(
        where: {'owner_id': userId},
      );

      if (org == null) {
        return Response.notFound(
          jsonEncode({'error': 'Organization not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if new name conflicts with existing organization (excluding current org)
      final existingOrg = await DatabaseManagers.organizations.findOne(
        where: {'name': name},
      );

      if (existingOrg != null && existingOrg.uuid != org.uuid) {
        return Response(
          409,
          body: jsonEncode({'error': 'Organization with this name already exists'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Update organization
      await DatabaseManagers.organizations.update(
        {'name': name},
        where: {'uuid': org.uuid},
      );

      // Fetch updated organization
      final updatedOrg = await DatabaseManagers.organizations.findByUuid(org.uuid!);

      if (updatedOrg == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch updated organization'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Convert to DTO
      final dto = OrganizationDto.fromEntity(updatedOrg);

      return Response.ok(
        jsonEncode({
          'message': 'Organization updated successfully',
          'organization': dto.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update organization: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/user/organization - Create new organization
  static Future<Response> createOrganization(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final userId = body['userId'] as String?;
      final name = body['name'] as String?;

      if (userId == null || name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User ID and organization name are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if organization name already exists
      final existingOrg = await DatabaseManagers.organizations.findOne(
        where: {'name': name},
      );

      if (existingOrg != null) {
        return Response(
          409,
          body: jsonEncode({'error': 'Organization with this name already exists'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if user is already in an organization
      final isInOrg = await DatabaseManagers.instance.isUserInOrganization(
        userId: userId,
      );

      if (isInOrg) {
        return Response(
          409,
          body: jsonEncode({'error': 'User already belongs to an organization'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create organization
      final org = await DatabaseManagers.organizations.insert(
        Organization(
          name: name,
          ownerId: userId,
        ).toMap(),
      );

      if (org == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to create organization'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add owner as member
      await DatabaseManagers.instance.addUserToOrganization(
        organizationId: org.uuid!,
        userId: userId,
      );

      // Convert to DTO
      final dto = OrganizationDto.fromEntity(org);

      return Response.ok(
        jsonEncode({
          'message': 'Organization created successfully',
          'organization': dto.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create organization: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/user/upgrade - Upgrade user role
  static Future<Response> upgrade(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final userId = body['userId'] as String?;
      final newRole = body['role'] as String?;

      if (userId == null || newRole == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User ID and role are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate role
      Role role;
      try {
        role = Role.fromString(newRole);
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Invalid role. Must be one of: developer, team, sub_team_developer',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Update user information role
      final results = await DatabaseManagers.userInformation.update(
        {'role': role.value},
        where: {'user_id': userId},
      );
      final updated = results.length;

      if (updated == 0) {
        return Response.notFound(
          jsonEncode({'error': 'User information not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Fetch updated user information
      final userInfo = await DatabaseManagers.userInformation.findOne(
        where: {'user_id': userId},
      );

      if (userInfo == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch updated user information'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Convert to DTO
      final dto = UserInformationDto.fromEntity(userInfo);

      return Response.ok(
        jsonEncode({
          'message': 'User role upgraded successfully',
          'user_information': dto.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to upgrade user: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/user/add-member - Add member to organization
  static Future<Response> addMember(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final organizationId = body['organizationId'] as String?;
      final userId = body['userId'] as String?;

      if (organizationId == null || userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Organization ID and User ID are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if organization exists
      final org = await DatabaseManagers.organizations.findByUuid(organizationId);
      if (org == null) {
        return Response.notFound(
          jsonEncode({'error': 'Organization not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if user exists
      final user = await DatabaseManagers.users.findByUuid(userId);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if user is already in an organization
      final isAlreadyMember = await DatabaseManagers.instance.isUserInOrganization(
        userId: userId,
      );

      if (isAlreadyMember) {
        return Response(
          409,
          body: jsonEncode({'error': 'User already belongs to an organization'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add user to organization
      final success = await DatabaseManagers.instance.addUserToOrganization(
        organizationId: organizationId,
        userId: userId,
      );

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to add user to organization'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'message': 'User added to organization successfully',
          'organizationId': organizationId,
          'userId': userId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to add member: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
