import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/component/error_card_component.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';
import '../component/stat_card.dart';

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
      data: (stats) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatCard(
            label: AppLocalizations.of(context)!.invocations,
            value: stats.invocations.toString(),
            context: context,
          ),
          StatCard(
            label: AppLocalizations.of(context)!.errors,
            value: stats.errors.toString(),
            context: context,
          ),
          StatCard(
            label: AppLocalizations.of(context)!.errorRate,
            value: '${(stats.errorRate).toStringAsFixed(2)}%',
            context: context,
          ),
          StatCard(
            label: AppLocalizations.of(context)!.avgLatency,
            value: '${stats.avgLatency}ms',
            context: context,
          ),
          if (stats.lastInvocation != null) ...[
            StatCard(
              label: AppLocalizations.of(context)!.lastInvocation,
              value: _formatDateTime(stats.lastInvocation!),
              context: context,
            ),
          ],
        ],
      ),
      loading: () => const Center(child: FCircularProgress()),
      error: (e, s) => Center(
        child: ErrorCardComponent(
          title: AppLocalizations.of(context)!.errorLoadStatsTitle,
          subtitle: AppLocalizations.of(context)!.errorLoadStatsSubtitle,
        ),
      ),
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
                  ToggleButton(
                    label: 'Hourly',
                    isActive: _showHourly,
                    onTap: () {
                      setState(() => _showHourly = true);
                    },
                  ),
                  ToggleButton(
                    label: 'Daily',
                    isActive: !_showHourly,
                    onTap: () {
                      setState(() => _showHourly = false);
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: _showHourly
                ? _HourlyChart(
                    funcUuid: widget.funcUuid,
                  )
                : _DailyChart(
                    funcUuid: widget.funcUuid,
                  ),
          ),
        ],
      ),
    );
  }
}

class ToggleButton extends StatelessWidget {
  const ToggleButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
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
                  label: '${e.hour.hour}',
                  value: e.totalRequests.toDouble(),
                  successCount: e.successCount,
                  errorCount: e.errorCount,
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: FCircularProgress()),
      error: (e, s) => Center(
        child: FAlert(
          title: const Text('Oppssy!! Cannot load hourly function stats'),
          subtitle: Text('Something went wrong'),
          style: FAlertStyle.destructive(),
        ),
      ),
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
      loading: () => const Center(child: FCircularProgress()),
      error: (e, s) => Center(
        child: FAlert(
          title: const Text('Oppssy!! Cannot load daily function stats'),
          subtitle: Text('Something went wrong'),
          style: FAlertStyle.destructive(),
        ),
      ),
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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: normalizedMax * 1.1,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => context.theme.colors.background,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = data[group.x.toInt()];
              return BarTooltipItem(
                '${point.label}\n',
                TextStyle(
                  color: context.theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Total: ${point.value.toInt()}\n',
                    style: TextStyle(
                      color: context.theme.colors.foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Success: ${point.successCount}\n',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Errors: ${point.errorCount}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].label,
                    style: TextStyle(
                      color: context.theme.colors.foreground,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: context.theme.colors.foreground,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: normalizedMax / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.theme.colors.border.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          final hasErrors = point.errorCount > 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.value,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: hasErrors
                      ? [
                          Colors.green.withValues(alpha: 0.8),
                          Colors.orange.withValues(alpha: 0.8),
                        ]
                      : [
                          Colors.green.withValues(alpha: 0.6),
                          Colors.green.withValues(alpha: 0.9),
                        ],
                ),
                rodStackItems: hasErrors
                    ? [
                        BarChartRodStackItem(
                          0,
                          point.successCount.toDouble(),
                          Colors.green.withValues(alpha: 0.8),
                        ),
                        BarChartRodStackItem(
                          point.successCount.toDouble(),
                          point.value,
                          Colors.red.withValues(alpha: 0.8),
                        ),
                      ]
                    : null,
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
