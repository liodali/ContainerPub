import 'dart:convert';

import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:shelf/shelf.dart';
import 'package:database/database.dart';

import '../services/statistics_service.dart';
import 'function_handler/auth_utils.dart';

/// Handler for function statistics endpoints
///
/// Provides endpoints for:
/// - GET /api/functions/:uuid/stats - Get function statistics
/// - GET /api/functions/:uuid/stats/hourly - Get hourly chart data
/// - GET /api/functions/:uuid/stats/daily - Get daily chart data
class StatisticsHandler {
  /// Get function statistics for a given period
  ///
  /// Query params:
  /// - period: '1h', '24h', '7d', '30d' (default: '24h')
  ///
  /// Response:
  /// ```json
  /// {
  ///   "invocations_count": 1250,
  ///   "success_count": 1245,
  ///   "error_count": 5,
  ///   "average_latency_ms": 120,
  ///   "period": "24h"
  /// }
  /// ```
  static Future<Response> getStats(Request request, String functionUuid) async {
    try {
      // Verify user owns this function
      final function = await _verifyFunctionOwnership(request, functionUuid);
      if (function == null) {
        return Response.notFound(
          json.encode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get period from query params
      final period = request.url.queryParameters['period'] ?? '24h';

      // Validate period
      if (!['1h', '24h', '7d', '30d'].contains(period)) {
        return Response(
          400,
          body: json.encode({
            'error': 'Invalid period. Must be one of: 1h, 24h, 7d, 30d',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final stats = await StatisticsService.instance.getFunctionStats(
        functionId: function.id!,
        period: period,
      );

      return Response.ok(
        json.encode(stats.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getStats',
        {
          'functionUuid': functionUuid,
          'period': request.url.queryParameters['period'],
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get hourly statistics for chart visualization
  ///
  /// Query params:
  /// - hours: Number of hours to retrieve (default: 24, max: 168)
  ///
  /// Response:
  /// ```json
  /// {
  ///   "data": [
  ///     {
  ///       "hour": "2024-01-15T10:00:00Z",
  ///       "total_requests": 50,
  ///       "success_count": 48,
  ///       "error_count": 2,
  ///       "average_latency_ms": 120
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<Response> getHourlyStats(Request request, String functionUuid) async {
    try {
      // Verify user owns this function
      final function = await _verifyFunctionOwnership(request, functionUuid);
      if (function == null) {
        return Response.notFound(
          json.encode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get hours from query params
      final hoursParam = request.url.queryParameters['hours'];
      var hours = 24;

      if (hoursParam != null) {
        hours = int.tryParse(hoursParam) ?? 24;
        if (hours < 1 || hours > 168) {
          return Response(
            400,
            body: json.encode({
              'error': 'Invalid hours. Must be between 1 and 168',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final stats = await StatisticsService.instance.getHourlyStats(
        functionId: function.id!,
        hours: hours,
      );

      return Response.ok(
        json.encode({
          'data': stats.map((s) => s.toJson()).toList(),
          'hours': hours,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getHourlyStats',
        {
          'functionUuid': functionUuid,
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get hourly statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get daily statistics for chart visualization
  ///
  /// Query params:
  /// - days: Number of days to retrieve (default: 30, max: 90)
  ///
  /// Response:
  /// ```json
  /// {
  ///   "data": [
  ///     {
  ///       "day": "2024-01-15T00:00:00Z",
  ///       "total_requests": 500,
  ///       "success_count": 495,
  ///       "error_count": 5,
  ///       "average_latency_ms": 115
  ///     }
  ///   ]
  /// }
  /// ```
  static Future<Response> getDailyStats(
    Request request,
    String functionUuid,
  ) async {
    try {
      // Verify user owns this function
      final function = await _verifyFunctionOwnership(request, functionUuid);
      if (function == null) {
        return Response.notFound(
          json.encode({'error': 'Function not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get days from query params
      final daysParam = request.url.queryParameters['days'];
      var days = 30;

      if (daysParam != null) {
        days = int.tryParse(daysParam) ?? 30;
        if (days < 1 || days > 90) {
          return Response(
            400,
            body: json.encode({
              'error': 'Invalid days. Must be between 1 and 90',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final stats = await StatisticsService.instance.getDailyStats(
        functionId: function.id!,
        days: days,
      );

      return Response.ok(
        json.encode({
          'data': stats.map((s) => s.toJson()).toList(),
          'days': days,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getDailyStats',
        {
          'functionUuid': functionUuid,
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get daily statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Verify user owns the function and return the function entity
  static Future<FunctionEntity?> _verifyFunctionOwnership(
    Request request,
    String functionUuid,
  ) async {
    final authUser = await AuthUtils.getAuthenticatedUser(request);
    if (authUser == null) return null;

    // Get function by UUID
    final functions = await DatabaseManagers.functions.findAll(
      where: {'uuid': functionUuid},
    );

    if (functions.isEmpty) return null;

    final function = functions.first;

    // Verify ownership
    if (function.userId != authUser.id) return null;

    return function;
  }

  // ============================================================================
  // USER OVERVIEW STATISTICS (All functions for a user)
  // ============================================================================

  /// Get overview statistics for all user's functions
  ///
  /// Query params:
  /// - period: '1h', '24h', '7d', '30d' (default: '24h')
  ///
  /// Response:
  /// ```json
  /// {
  ///   "total_functions": 5,
  ///   "invocations_count": 1250,
  ///   "success_count": 1245,
  ///   "error_count": 5,
  ///   "average_latency_ms": 120,
  ///   "period": "24h"
  /// }
  /// ```
  static Future<Response> getOverviewStats(Request request) async {
    try {
      final authUser = await AuthUtils.getAuthenticatedUser(request);
      if (authUser == null) {
        return Response.forbidden(
          json.encode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get period from query params
      final period = request.url.queryParameters['period'] ?? '24h';

      // Validate period
      if (!['1h', '24h', '7d', '30d'].contains(period)) {
        return Response(
          400,
          body: json.encode({
            'error': 'Invalid period. Must be one of: 1h, 24h, 7d, 30d',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final stats = await StatisticsService.instance.getUserOverviewStats(
        userId: authUser.id,
        period: period,
      );

      return Response.ok(
        json.encode(stats.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getOverviewStats',
        {
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get overview statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get hourly statistics for all user's functions (for chart visualization)
  ///
  /// Query params:
  /// - hours: Number of hours to retrieve (default: 24, max: 168)
  static Future<Response> getOverviewHourlyStats(Request request) async {
    try {
      final authUser = await AuthUtils.getAuthenticatedUser(request);
      if (authUser == null) {
        return Response.forbidden(
          json.encode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get hours from query params
      final hoursParam = request.url.queryParameters['hours'];
      var hours = 24;

      if (hoursParam != null) {
        hours = int.tryParse(hoursParam) ?? 24;
        if (hours < 1 || hours > 168) {
          return Response(
            400,
            body: json.encode({
              'error': 'Invalid hours. Must be between 1 and 168',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final stats = await StatisticsService.instance.getUserHourlyStats(
        userId: authUser.id,
        hours: hours,
      );

      return Response.ok(
        json.encode({
          'data': stats.map((s) => s.toJson()).toList(),
          'hours': hours,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getOverviewHourlyStats',
        {
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get hourly statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get daily statistics for all user's functions (for chart visualization)
  ///
  /// Query params:
  /// - days: Number of days to retrieve (default: 30, max: 90)
  static Future<Response> getOverviewDailyStats(Request request) async {
    try {
      final authUser = await AuthUtils.getAuthenticatedUser(request);
      if (authUser == null) {
        return Response.forbidden(
          json.encode({'error': 'Unauthorized'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get days from query params
      final daysParam = request.url.queryParameters['days'];
      var days = 30;

      if (daysParam != null) {
        days = int.tryParse(daysParam) ?? 30;
        if (days < 1 || days > 90) {
          return Response(
            400,
            body: json.encode({
              'error': 'Invalid days. Must be between 1 and 90',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final stats = await StatisticsService.instance.getUserDailyStats(
        userId: authUser.id,
        days: days,
      );

      return Response.ok(
        json.encode({
          'data': stats.map((s) => s.toJson()).toList(),
          'days': days,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, trace) {
      LogsUtils.log(
        LogLevels.error.name,
        'getOverviewDailyStats',
        {
          'error': e.toString(),
          'trace': trace.toString(),
        },
      );
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get daily statistics'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
