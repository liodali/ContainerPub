import 'package:database/database.dart';
import 'package:shelf/shelf.dart';

/// Result of authenticated user validation
/// Contains only the internal user ID, not sensitive data
class AuthenticatedUser {
  final int id;
  AuthenticatedUser(this.id);
}

/// Utility for extracting and validating authenticated user from request
class AuthUtils {
  /// Extract and validate authenticated user from request context
  ///
  /// Returns [AuthenticatedUser] with internal ID if valid,
  /// or null if user not found (invalid token or deleted user)
  ///
  /// Usage:
  /// ```dart
  /// final authUser = await AuthUtils.getAuthenticatedUser(request);
  /// if (authUser == null) {
  ///   return Response.notFound(jsonEncode({'error': 'Unauthorized'}));
  /// }
  /// // Use authUser.id for database queries
  /// ```
  static Future<AuthenticatedUser?> getAuthenticatedUser(Request request) async {
    final userUUID = request.context['userUUID'] as String?;
    if (userUUID == null) return null;

    final userEntity = await DatabaseManagers.users.findByUuid(userUUID);
    if (userEntity == null || userEntity.id == null) return null;

    return AuthenticatedUser(userEntity.id!);
  }

  static Future<AuthenticatedUser?> getAuthenticatedUserFromJWT(String uuid) async {
    final userEntity = await DatabaseManagers.users.findByUuid(uuid);
    if (userEntity == null || userEntity.id == null) return null;

    return AuthenticatedUser(userEntity.id!);
  }
}


