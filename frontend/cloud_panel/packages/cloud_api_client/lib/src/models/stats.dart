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
      invocations: json['invocations'] as int? ?? 0,
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
