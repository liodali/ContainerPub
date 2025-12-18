import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'stat_card.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.func,
  });
  final CloudFunction func;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          _StatsSection(funcUuid: func.uuid),
          _DashboardSection(funcUuid: func.uuid),
        ],
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection({
    required this.funcUuid,
  });

  final String funcUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(functionStatsProvider(funcUuid));

    return statsAsync.when(
      data: (stats) => Column(
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: StatCard(
                  label: 'Invocations',
                  value: stats.invocations.toString(),
                  context: context,
                ),
              ),
              Expanded(
                child: StatCard(
                  label: 'Errors',
                  value: stats.errors.toString(),
                  context: context,
                ),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: StatCard(
                  label: 'Error Rate',
                  value: '${(stats.errorRate * 100).toStringAsFixed(2)}%',
                  context: context,
                ),
              ),
              Expanded(
                child: StatCard(
                  label: 'Avg Latency',
                  value: '${stats.avgLatency}ms',
                  context: context,
                ),
              ),
            ],
          ),
          if (stats.lastInvocation != null)
            StatCard(
              label: 'Last Invocation',
              value: _formatDateTime(stats.lastInvocation!),
              context: context,
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading stats: $e')),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DashboardSection extends ConsumerStatefulWidget {
  const _DashboardSection({required this.funcUuid});

  final String funcUuid;

  @override
  ConsumerState<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends ConsumerState<_DashboardSection> {
  bool _showHourly = true;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Call History',
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  _buildToggleButton('Hourly', _showHourly, () {
                    setState(() => _showHourly = true);
                  }),
                  _buildToggleButton('Daily', !_showHourly, () {
                    setState(() => _showHourly = false);
                  }),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: _showHourly
                ? _HourlyChart(funcUuid: widget.funcUuid)
                : _DailyChart(funcUuid: widget.funcUuid),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? context.theme.colors.primary
              : context.theme.colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? context.theme.colors.primary
                : context.theme.colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? context.theme.colors.primaryForeground
                : context.theme.colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HourlyChart extends ConsumerWidget {
  const _HourlyChart({required this.funcUuid});

  final String funcUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyAsync = ref.watch(functionHourlyStatsProvider(funcUuid));

    return hourlyAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return const Center(child: Text('No data available'));
        }
        return _BarChart(
          data: response.data
              .map(
                (e) => _ChartDataPoint(
                  label: '${e.hour.hour}:00',
                  value: e.totalRequests.toDouble(),
                  successCount: e.successCount,
                  errorCount: e.errorCount,
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _DailyChart extends ConsumerWidget {
  const _DailyChart({required this.funcUuid});

  final String funcUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(functionDailyStatsProvider(funcUuid));

    return dailyAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return const Center(child: Text('No data available'));
        }
        return _BarChart(
          data: response.data
              .map(
                (e) => _ChartDataPoint(
                  label: '${e.day.month}/${e.day.day}',
                  value: e.totalRequests.toDouble(),
                  successCount: e.successCount,
                  errorCount: e.errorCount,
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _ChartDataPoint {
  final String label;
  final double value;
  final int successCount;
  final int errorCount;

  const _ChartDataPoint({
    required this.label,
    required this.value,
    required this.successCount,
    required this.errorCount,
  });
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<_ChartDataPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxValue == 0 ? 1.0 : maxValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            (constraints.maxWidth - (data.length - 1) * 4) / data.length;
        final clampedBarWidth = barWidth.clamp(8.0, 40.0);

        return Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((point) {
                  final barHeight =
                      (point.value / normalizedMax) *
                      (constraints.maxHeight - 30);
                  final successRatio = point.value > 0
                      ? point.successCount / point.value
                      : 1.0;

                  return Tooltip(
                    message:
                        'Total: ${point.value.toInt()}\nSuccess: ${point.successCount}\nErrors: ${point.errorCount}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: clampedBarWidth,
                          height: barHeight.clamp(
                            2.0,
                            constraints.maxHeight - 30,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.green.withValues(alpha: 0.8),
                                successRatio < 1.0
                                    ? Colors.red.withValues(alpha: 0.8)
                                    : Colors.green.withValues(alpha: 0.6),
                              ],
                              stops: [successRatio, successRatio],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((point) {
                return SizedBox(
                  width: clampedBarWidth + 4,
                  child: Text(
                    point.label,
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
