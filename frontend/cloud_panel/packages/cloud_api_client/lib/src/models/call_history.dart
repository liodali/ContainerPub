import 'package:equatable/equatable.dart';

/// Represents a single data point for hourly statistics
class HourlyStats extends Equatable {
  final DateTime hour;
  final int totalRequests;
  final int successCount;
  final int errorCount;
  final int averageLatencyMs;

  const HourlyStats({
    required this.hour,
    required this.totalRequests,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
  });

  factory HourlyStats.fromJson(Map<String, dynamic> json) {
    return HourlyStats(
      hour: DateTime.parse(json['hour'] as String),
      totalRequests: json['total_requests'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      averageLatencyMs: json['average_latency_ms'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        hour,
        totalRequests,
        successCount,
        errorCount,
        averageLatencyMs,
      ];
}

/// Represents a single data point for daily statistics
class DailyStats extends Equatable {
  final DateTime day;
  final int totalRequests;
  final int successCount;
  final int errorCount;
  final int averageLatencyMs;

  const DailyStats({
    required this.day,
    required this.totalRequests,
    required this.successCount,
    required this.errorCount,
    required this.averageLatencyMs,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      day: DateTime.parse(json['day'] as String),
      totalRequests: json['total_requests'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      averageLatencyMs: json['average_latency_ms'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        day,
        totalRequests,
        successCount,
        errorCount,
        averageLatencyMs,
      ];
}

/// Response wrapper for hourly stats API
class HourlyStatsResponse extends Equatable {
  final List<HourlyStats> data;
  final int hours;

  const HourlyStatsResponse({
    required this.data,
    required this.hours,
  });

  factory HourlyStatsResponse.fromJson(Map<String, dynamic> json) {
    return HourlyStatsResponse(
      data: (json['data'] as List)
          .map((e) => HourlyStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      hours: json['hours'] as int? ?? 24,
    );
  }

  @override
  List<Object?> get props => [data, hours];
}

/// Response wrapper for daily stats API
class DailyStatsResponse extends Equatable {
  final List<DailyStats> data;
  final int days;

  const DailyStatsResponse({
    required this.data,
    required this.days,
  });

  factory DailyStatsResponse.fromJson(Map<String, dynamic> json) {
    return DailyStatsResponse(
      data: (json['data'] as List)
          .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      days: json['days'] as int? ?? 30,
    );
  }

  @override
  List<Object?> get props => [data, days];
}
