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
      // Insert user

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
}
