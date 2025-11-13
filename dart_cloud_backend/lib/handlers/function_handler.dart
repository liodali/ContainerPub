/// Function Handler - Main entry point for all function-related operations
/// 
/// This module provides a unified interface for managing serverless functions
/// in the ContainerPub platform. It handles the complete lifecycle of functions:
/// 
/// **Deployment Operations** (deployment_handler.dart):
/// - Creating new functions
/// - Updating existing functions with versioning
/// - Uploading archives to S3
/// - Building Docker images
/// - Managing deployment history
/// 
/// **CRUD Operations** (crud_handler.dart):
/// - Listing all functions for a user
/// - Getting function details
/// - Deleting functions and resources
/// 
/// **Execution Operations** (execution_handler.dart):
/// - Invoking functions with input data
/// - Validating request size limits
/// - Tracking execution metrics
/// - Logging invocation results
/// 
/// **Logging Operations** (logs_handler.dart):
/// - Retrieving function logs
/// - Monitoring deployment and execution events
/// - Debugging function issues
/// 
/// **Versioning Operations** (versioning_handler.dart):
/// - Viewing deployment history
/// - Rolling back to previous versions
/// - Managing version lifecycle
/// 
/// ## Architecture
/// 
/// The handler is split into specialized modules for better organization:
/// - Each handler focuses on a specific domain
/// - Shared utilities are in utils.dart
/// - All handlers follow consistent patterns
/// - Comprehensive comments explain each operation
/// 
/// ## Usage
/// 
/// Import this file to access all function handlers:
/// ```dart
/// import 'package:dart_cloud_backend/handlers/function_handler.dart';
/// 
/// // Use handlers in routes
/// router.post('/api/functions/deploy', FunctionHandler.deploy);
/// router.get('/api/functions', FunctionHandler.list);
/// router.post('/api/functions/:id/invoke', FunctionHandler.invoke);
/// ```
/// 
/// ## Security
/// 
/// All handlers verify:
/// - User authentication (via middleware)
/// - Function ownership (user can only access their own functions)
/// - Request size limits (prevent DoS attacks)
/// - Input validation (prevent injection attacks)

library;

// Export all handler classes
export 'function_handler/deployment_handler.dart';
export 'function_handler/crud_handler.dart';
export 'function_handler/execution_handler.dart';
export 'function_handler/logs_handler.dart';
export 'function_handler/versioning_handler.dart';
export 'function_handler/utils.dart';

import 'package:shelf/shelf.dart';
import 'function_handler/deployment_handler.dart';
import 'function_handler/crud_handler.dart';
import 'function_handler/execution_handler.dart';
import 'function_handler/logs_handler.dart';
import 'function_handler/versioning_handler.dart';

/// Main FunctionHandler class that delegates to specialized handlers
/// 
/// This class provides a unified API for all function operations while
/// delegating the actual work to specialized handler classes. This keeps
/// the routing layer simple while maintaining good code organization.
class FunctionHandler {
  // === S3 INITIALIZATION ===
  /// Initialize S3 client for deployment operations
  /// Should be called once at application startup
  static void initializeS3() {
    DeploymentHandler.initializeS3();
  }

  // === DEPLOYMENT OPERATIONS ===
  /// Deploy a new function or update an existing one
  /// Delegates to: DeploymentHandler.deploy()
  static Future<Response> deploy(Request request) {
    return DeploymentHandler.deploy(request);
  }

  // === CRUD OPERATIONS ===
  /// List all functions for the authenticated user
  /// Delegates to: CrudHandler.list()
  static Future<Response> list(Request request) {
    return CrudHandler.list(request);
  }

  /// Get details of a specific function
  /// Delegates to: CrudHandler.get()
  static Future<Response> get(Request request, String id) {
    return CrudHandler.get(request, id);
  }

  /// Delete a function and all associated resources
  /// Delegates to: CrudHandler.delete()
  static Future<Response> delete(Request request, String id) {
    return CrudHandler.delete(request, id);
  }

  // === EXECUTION OPERATIONS ===
  /// Invoke a function with provided input
  /// Delegates to: ExecutionHandler.invoke()
  static Future<Response> invoke(Request request, String id) {
    return ExecutionHandler.invoke(request, id);
  }

  // === LOGGING OPERATIONS ===
  /// Retrieve logs for a specific function
  /// Delegates to: LogsHandler.getLogs()
  static Future<Response> getLogs(Request request, String id) {
    return LogsHandler.getLogs(request, id);
  }

  // === VERSIONING OPERATIONS ===
  /// Get deployment history for a function
  /// Delegates to: VersioningHandler.getDeployments()
  static Future<Response> getDeployments(Request request, String id) {
    return VersioningHandler.getDeployments(request, id);
  }

  /// Rollback function to a specific version
  /// Delegates to: VersioningHandler.rollback()
  static Future<Response> rollback(Request request, String id) {
    return VersioningHandler.rollback(request, id);
  }
}
