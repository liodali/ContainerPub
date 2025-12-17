import 'package:database/database.dart';

/// Service for computing function statistics from invocation data
///
/// Provides aggregated metrics for:
/// - Total invocations count
/// - Success/error counts
/// - Average latency
/// - Hourly request distribution (for charts)
class StatisticsService {
  static final StatisticsService _instance = StatisticsService._();
  static StatisticsService get instance => _instance;

  StatisticsService._();

  /// Get function statistics for a given period
  ///
  /// [functionId] - The internal function ID (not UUID)
  /// [period] - Time period: '1h', '24h', '7d', '30d'
  Future<FunctionStats> getFunctionStats({
    required int functionId,
    String period = '24h',
  }) async {
    final interval = _periodToInterval(period);

    final result = await Database.rawQuerySingle(
      '''
      SELECT 
        COUNT(*) as total_invocations,
        COUNT(*) FILTER (WHERE success = true) as success_count,
        COUNT(*) FILTER (WHERE success = false OR success IS NULL) as error_count,
        COALESCE(AVG(duration_ms) FILTER (WHERE duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations
      WHERE function_id = @function_id
        AND timestamp >= NOW() - INTERVAL '$interval'
    ''',
      parameters: {'function_id': functionId},
    );

    if (result == null) {
      return FunctionStats.empty(period);
    }

    return FunctionStats(
      invocationsCount: (result['total_invocations'] as int?) ?? 0,
      successCount: (result['success_count'] as int?) ?? 0,
      errorCount: (result['error_count'] as int?) ?? 0,
      averageLatencyMs: (result['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      period: period,
    );
  }

  /// Get hourly request distribution for charts
  ///
  /// Returns request counts grouped by hour for the last [hours] hours
  /// Default is 24 hours for a daily chart
  Future<List<HourlyStats>> getHourlyStats({
    required int functionId,
    int hours = 24,
  }) async {
    final results = await Database.rawQueryAll(
      '''
      SELECT 
        DATE_TRUNC('hour', timestamp) as hour,
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE success = true) as success_count,
        COUNT(*) FILTER (WHERE success = false OR success IS NULL) as error_count,
        COALESCE(AVG(duration_ms) FILTER (WHERE duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations
      WHERE function_id = @function_id
        AND timestamp >= NOW() - INTERVAL '$hours hours'
      GROUP BY DATE_TRUNC('hour', timestamp)
      ORDER BY hour ASC
    ''',
      parameters: {'function_id': functionId},
    );

    // Fill in missing hours with zero values
    final now = DateTime.now();
    final startHour = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).subtract(Duration(hours: hours - 1));

    final hourlyMap = <DateTime, HourlyStats>{};

    // Initialize all hours with zero values
    for (var i = 0; i < hours; i++) {
      final hour = startHour.add(Duration(hours: i));
      hourlyMap[hour] = HourlyStats(
        hour: hour,
        totalRequests: 0,
        successCount: 0,
        errorCount: 0,
        averageLatencyMs: 0.0,
      );
    }

    // Fill in actual data
    for (final row in results) {
      final hour = row['hour'] as DateTime;
      final normalizedHour = DateTime(hour.year, hour.month, hour.day, hour.hour);

      hourlyMap[normalizedHour] = HourlyStats(
        hour: normalizedHour,
        totalRequests: (row['total_requests'] as int?) ?? 0,
        successCount: (row['success_count'] as int?) ?? 0,
        errorCount: (row['error_count'] as int?) ?? 0,
        averageLatencyMs: (row['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return hourlyMap.values.toList()..sort((a, b) => a.hour.compareTo(b.hour));
  }

  /// Get daily request distribution for charts
  ///
  /// Returns request counts grouped by day for the last [days] days
  Future<List<DailyStats>> getDailyStats({
    required int functionId,
    int days = 30,
  }) async {
    final results = await Database.rawQueryAll(
      '''
      SELECT 
        DATE_TRUNC('day', timestamp) as day,
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE success = true) as success_count,
        COUNT(*) FILTER (WHERE success = false OR success IS NULL) as error_count,
        COALESCE(AVG(duration_ms) FILTER (WHERE duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations
      WHERE function_id = @function_id
        AND timestamp >= NOW() - INTERVAL '$days days'
      GROUP BY DATE_TRUNC('day', timestamp)
      ORDER BY day ASC
    ''',
      parameters: {'function_id': functionId},
    );

    // Fill in missing days with zero values
    final now = DateTime.now();
    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final dailyMap = <DateTime, DailyStats>{};

    // Initialize all days with zero values
    for (var i = 0; i < days; i++) {
      final day = startDay.add(Duration(days: i));
      dailyMap[day] = DailyStats(
        day: day,
        totalRequests: 0,
        successCount: 0,
        errorCount: 0,
        averageLatencyMs: 0.0,
      );
    }

    // Fill in actual data
    for (final row in results) {
      final day = row['day'] as DateTime;
      final normalizedDay = DateTime(day.year, day.month, day.day);

      dailyMap[normalizedDay] = DailyStats(
        day: normalizedDay,
        totalRequests: (row['total_requests'] as int?) ?? 0,
        successCount: (row['success_count'] as int?) ?? 0,
        errorCount: (row['error_count'] as int?) ?? 0,
        averageLatencyMs: (row['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return dailyMap.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  }

  /// Convert period string to PostgreSQL interval
  String _periodToInterval(String period) {
    switch (period) {
      case '1h':
        return '1 hour';
      case '24h':
        return '24 hours';
      case '7d':
        return '7 days';
      case '30d':
        return '30 days';
      default:
        return '24 hours';
    }
  }

  // ============================================================================
  // USER OVERVIEW STATISTICS (All functions for a user)
  // ============================================================================

  /// Get overview statistics for all functions owned by a user
  ///
  /// [userId] - The internal user ID
  /// [period] - Time period: '1h', '24h', '7d', '30d'
  Future<UserOverviewStats> getUserOverviewStats({
    required int userId,
    String period = '24h',
  }) async {
    final interval = _periodToInterval(period);

    // Get total functions count
    final functionsResult = await Database.rawQuerySingle(
      '''
      SELECT COUNT(*) as total_functions
      FROM functions
      WHERE user_id = @user_id
    ''',
      parameters: {'user_id': userId},
    );

    final totalFunctions = (functionsResult?['total_functions'] as int?) ?? 0;

    // Get aggregated invocation stats across all user's functions
    final statsResult = await Database.rawQuerySingle(
      '''
      SELECT 
        COUNT(*) as total_invocations,
        COUNT(*) FILTER (WHERE fi.success = true) as success_count,
        COUNT(*) FILTER (WHERE fi.success = false OR fi.success IS NULL) as error_count,
        COALESCE(AVG(fi.duration_ms) FILTER (WHERE fi.duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations fi
      INNER JOIN functions f ON fi.function_id = f.id
      WHERE f.user_id = @user_id
        AND fi.timestamp >= NOW() - INTERVAL '$interval'
    ''',
      parameters: {'user_id': userId},
    );

    return UserOverviewStats(
      totalFunctions: totalFunctions,
      invocationsCount: (statsResult?['total_invocations'] as int?) ?? 0,
      successCount: (statsResult?['success_count'] as int?) ?? 0,
      errorCount: (statsResult?['error_count'] as int?) ?? 0,
      averageLatencyMs: (statsResult?['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      period: period,
    );
  }

  /// Get hourly request distribution for all user's functions (for charts)
  ///
  /// Returns request counts grouped by hour for the last [hours] hours
  Future<List<HourlyStats>> getUserHourlyStats({
    required int userId,
    int hours = 24,
  }) async {
    final results = await Database.rawQueryAll(
      '''
      SELECT 
        DATE_TRUNC('hour', fi.timestamp) as hour,
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE fi.success = true) as success_count,
        COUNT(*) FILTER (WHERE fi.success = false OR fi.success IS NULL) as error_count,
        COALESCE(AVG(fi.duration_ms) FILTER (WHERE fi.duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations fi
      INNER JOIN functions f ON fi.function_id = f.id
      WHERE f.user_id = @user_id
        AND fi.timestamp >= NOW() - INTERVAL '$hours hours'
      GROUP BY DATE_TRUNC('hour', fi.timestamp)
      ORDER BY hour ASC
    ''',
      parameters: {'user_id': userId},
    );

    // Fill in missing hours with zero values
    final now = DateTime.now();
    final startHour = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).subtract(Duration(hours: hours - 1));

    final hourlyMap = <DateTime, HourlyStats>{};

    // Initialize all hours with zero values
    for (var i = 0; i < hours; i++) {
      final hour = startHour.add(Duration(hours: i));
      hourlyMap[hour] = HourlyStats(
        hour: hour,
        totalRequests: 0,
        successCount: 0,
        errorCount: 0,
        averageLatencyMs: 0.0,
      );
    }

    // Fill in actual data
    for (final row in results) {
      final hour = row['hour'] as DateTime;
      final normalizedHour = DateTime(hour.year, hour.month, hour.day, hour.hour);

      hourlyMap[normalizedHour] = HourlyStats(
        hour: normalizedHour,
        totalRequests: (row['total_requests'] as int?) ?? 0,
        successCount: (row['success_count'] as int?) ?? 0,
        errorCount: (row['error_count'] as int?) ?? 0,
        averageLatencyMs: (row['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return hourlyMap.values.toList()..sort((a, b) => a.hour.compareTo(b.hour));
  }

  /// Get daily request distribution for all user's functions (for charts)
  ///
  /// Returns request counts grouped by day for the last [days] days
  Future<List<DailyStats>> getUserDailyStats({
    required int userId,
    int days = 30,
  }) async {
    final results = await Database.rawQueryAll(
      '''
      SELECT 
        DATE_TRUNC('day', fi.timestamp) as day,
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE fi.success = true) as success_count,
        COUNT(*) FILTER (WHERE fi.success = false OR fi.success IS NULL) as error_count,
        COALESCE(AVG(fi.duration_ms) FILTER (WHERE fi.duration_ms IS NOT NULL), 0) as avg_latency_ms
      FROM function_invocations fi
      INNER JOIN functions f ON fi.function_id = f.id
      WHERE f.user_id = @user_id
        AND fi.timestamp >= NOW() - INTERVAL '$days days'
      GROUP BY DATE_TRUNC('day', fi.timestamp)
      ORDER BY day ASC
    ''',
      parameters: {'user_id': userId},
    );

    // Fill in missing days with zero values
    final now = DateTime.now();
    final startDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final dailyMap = <DateTime, DailyStats>{};

    // Initialize all days with zero values
    for (var i = 0; i < days; i++) {
      final day = startDay.add(Duration(days: i));
      dailyMap[day] = DailyStats(
        day: day,
        totalRequests: 0,
        successCount: 0,
        errorCount: 0,
        averageLatencyMs: 0.0,
      );
    }

    // Fill in actual data
    for (final row in results) {
      final day = row['day'] as DateTime;
      final normalizedDay = DateTime(day.year, day.month, day.day);

      dailyMap[normalizedDay] = DailyStats(
        day: normalizedDay,
        totalRequests: (row['total_requests'] as int?) ?? 0,
        successCount: (row['success_count'] as int?) ?? 0,
        errorCount: (row['error_count'] as int?) ?? 0,
        averageLatencyMs: (row['avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return dailyMap.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  }
}

/// Function statistics for a given period
class FunctionStats {
  final int invocationsCount;
  final int successCount;
  final int errorCount;
  final double averageLatencyMs;
  final String period;

  FunctionStats({
    required this.invocationsCount,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
    required this.period,
  });

  factory FunctionStats.empty(String period) {
    return FunctionStats(
      invocationsCount: 0,
      successCount: 0,
      errorCount: 0,
      averageLatencyMs: 0.0,
      period: period,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invocations_count': invocationsCount,
      'success_count': successCount,
      'error_count': errorCount,
      'average_latency_ms': averageLatencyMs.round(),
      'period': period,
    };
  }
}

/// Hourly statistics for chart data
class HourlyStats {
  final DateTime hour;
  final int totalRequests;
  final int successCount;
  final int errorCount;
  final double averageLatencyMs;

  HourlyStats({
    required this.hour,
    required this.totalRequests,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'hour': hour.toIso8601String(),
      'total_requests': totalRequests,
      'success_count': successCount,
      'error_count': errorCount,
      'average_latency_ms': averageLatencyMs.round(),
    };
  }
}

/// Daily statistics for chart data
class DailyStats {
  final DateTime day;
  final int totalRequests;
  final int successCount;
  final int errorCount;
  final double averageLatencyMs;

  DailyStats({
    required this.day,
    required this.totalRequests,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'day': day.toIso8601String(),
      'total_requests': totalRequests,
      'success_count': successCount,
      'error_count': errorCount,
      'average_latency_ms': averageLatencyMs.round(),
    };
  }
}

/// User overview statistics - aggregated across all user's functions
class UserOverviewStats {
  final int totalFunctions;
  final int invocationsCount;
  final int successCount;
  final int errorCount;
  final double averageLatencyMs;
  final String period;

  UserOverviewStats({
    required this.totalFunctions,
    required this.invocationsCount,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
    required this.period,
  });

  factory UserOverviewStats.empty(String period) {
    return UserOverviewStats(
      totalFunctions: 0,
      invocationsCount: 0,
      successCount: 0,
      errorCount: 0,
      averageLatencyMs: 0.0,
      period: period,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_functions': totalFunctions,
      'invocations_count': invocationsCount,
      'success_count': successCount,
      'error_count': errorCount,
      'average_latency_ms': averageLatencyMs.round(),
      'period': period,
    };
  }
}
