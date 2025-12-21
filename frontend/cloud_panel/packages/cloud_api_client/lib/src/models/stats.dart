import 'package:equatable/equatable.dart';

class FunctionStats extends Equatable {
  final int invocations;
  final int errors;
  final double errorRate;
  final int avgLatency;
  final DateTime? lastInvocation;
  final int minLatency;
  final int maxLatency;

  const FunctionStats({
    required this.invocations,
    required this.errors,
    required this.errorRate,
    required this.avgLatency,
    this.lastInvocation,
    required this.minLatency,
    required this.maxLatency,
  });

  factory FunctionStats.fromJson(Map<String, dynamic> json) {
    return FunctionStats(
      invocations: json['invocations_count'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      errorRate: (json['error_rate'] as num?)?.toDouble() ?? 0.0,
      avgLatency: json['avg_latency'] as int? ?? 0,
      lastInvocation: json['last_invocation'] != null
          ? DateTime.parse(json['last_invocation'] as String)
          : null,
      minLatency: json['min_latency'] as int? ?? 0,
      maxLatency: json['max_latency'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        invocations,
        errors,
        errorRate,
        avgLatency,
        lastInvocation,
        minLatency,
        maxLatency,
      ];
}

class OverviewStats extends Equatable {
  final int totalFunctions;
  final int invocationsCount;
  final int successCount;
  final int errorCount;
  final double averageLatencyMs;
  final String period;

  const OverviewStats({
    this.totalFunctions = 0,
    this.invocationsCount = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.averageLatencyMs = 0.0,
    this.period = '',
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalFunctions: json['total_functions'] as int? ?? 0,
      invocationsCount: json['invocations_count'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      averageLatencyMs: (json['average_latency_ms'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        totalFunctions,
        invocationsCount,
        successCount,
        errorCount,
        averageLatencyMs,
        period,
      ];
}
