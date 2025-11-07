import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_cloud_backend/config/config.dart';
import 'package:dart_cloud_backend/database/database.dart';

class AuthHandler {
  static Future<Response> register(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
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
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
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
}
