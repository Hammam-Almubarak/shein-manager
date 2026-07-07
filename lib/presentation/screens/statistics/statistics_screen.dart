import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/statistics_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// شاشة الإحصائيات - أربعة رسوم بيانية باستخدام fl_chart:
/// 1. الأرباح الشهرية (Line Chart)
/// 2. المبيعات الشهرية (Line Chart)
/// 3. الطلبات حسب الحالة (Pie Chart)
/// 4. أفضل العملاء بالربح (Bar Chart)
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyStatsProvider);
    final statusAsync = ref.watch(statusStatsProvider);
    final topCustomersAsync = ref.watch(topCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(monthlyStatsProvider);
              ref.invalidate(statusStatsProvider);
              ref.invalidate(topCustomersProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(statusStatsProvider);
          ref.invalidate(topCustomersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ---- الأرباح الشهرية ----
            _ChartCard(
              title: 'الأرباح الشهرية',
              subtitle: 'آخر 6 أشهر',
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.profitColor,
              child: monthlyAsync.when(
                data: (data) => _MonthlyLineChart(
                  data: data,
                  useProfit: true,
                  color: AppColors.profitColor,
                ),
                loading: () => const _ChartShimmer(),
                error: (e, _) => _ChartError(error: '$e'),
              ),
            ),
            const SizedBox(height: 16),

            // ---- المبيعات الشهرية ----
            _ChartCard(
              title: 'المبيعات الشهرية',
              subtitle: 'آخر 6 أشهر',
              icon: Icons.show_chart_rounded,
              iconColor: AppColors.sellingColor,
              child: monthlyAsync.when(
                data: (data) => _MonthlyLineChart(
                  data: data,
                  useProfit: false,
                  color: AppColors.sellingColor,
                ),
                loading: () => const _ChartShimmer(),
                error: (e, _) => _ChartError(error: '$e'),
              ),
            ),
            const SizedBox(height: 16),

            // ---- الطلبات حسب الحالة ----
            _ChartCard(
              title: 'الطلبات حسب الحالة',
              subtitle: 'توزيع نسبي',
              icon: Icons.pie_chart_rounded,
              iconColor: AppColors.primary,
              child: statusAsync.when(
                data: (data) => data.isEmpty
                    ? const _NoDataMessage()
                    : _StatusPieChart(data: data),
                loading: () => const _ChartShimmer(),
                error: (e, _) => _ChartError(error: '$e'),
              ),
            ),
            const SizedBox(height: 16),

            // ---- أفضل العملاء ----
            _ChartCard(
              title: 'أفضل العملاء',
              subtitle: 'حسب إجمالي الربح',
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFFFD700),
              child: topCustomersAsync.when(
                data: (data) => data.isEmpty
                    ? const _NoDataMessage()
                    : _TopCustomersChart(data: data),
                loading: () => const _ChartShimmer(),
                error: (e, _) => _ChartError(error: '$e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- إطار البطاقة ----

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ---- رسم خطي للأرباح/المبيعات الشهرية ----

class _MonthlyLineChart extends StatelessWidget {
  final List<MonthlyStats> data;
  final bool useProfit;
  final Color color;

  const _MonthlyLineChart({
    required this.data,
    required this.useProfit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spots = data.asMap().entries.map((e) {
      final value = useProfit ? e.value.profit : e.value.sales;
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final maxY = data.fold(0.0, (max, m) {
      final v = useProfit ? m.profit : m.sales;
      return v > max ? v : max;
    });

    final labels = data
        .map((m) => DateFormat('MMM', 'ar').format(m.month))
        .toList();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, meta) => Text(
                  '\$${v.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          minY: 0,
          maxY: maxY == 0 ? 100 : maxY * 1.25,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (spot, %, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        AppFormatters.currency(s.y),
                        TextStyle(
                            color: color, fontWeight: FontWeight.w700),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- رسم دائري لحالات الطلبات ----

class _StatusPieChart extends StatefulWidget {
  final List<StatusStats> data;

  const _StatusPieChart({required this.data});

  @override
  State<_StatusPieChart> createState() => _StatusPieChartState();
}

class _StatusPieChartState extends State<_StatusPieChart> {
  int _touchedIndex = -1;

  static const _colors = [
    AppColors.statusNew,
    AppColors.statusOrdered,
    AppColors.statusShipped,
    AppColors.statusArrived,
    AppColors.statusDelivered,
    AppColors.statusCancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (ev, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: widget.data.asMap().entries.map((e) {
                final isTouched = e.key == _touchedIndex;
                final color = _colors[e.value.status.index % _colors.length];
                return PieChartSectionData(
                  value: e.value.count.toDouble(),
                  title: '${e.value.percentage.toStringAsFixed(0)}%',
                  color: color,
                  radius: isTouched ? 65 : 55,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // وسيلة الإيضاح
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: widget.data.asMap().entries.map((e) {
            final color = _colors[e.value.status.index % _colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.value.status.labelAr} (${e.value.count})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---- رسم أعمدة لأفضل العملاء ----

class _TopCustomersChart extends StatelessWidget {
  final List<TopCustomerStats> data;

  const _TopCustomersChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // نأخذ أفضل 5 فقط
    final top = data.take(5).toList();
    final maxY = top.fold(0.0, (m, c) => c.totalProfit > m ? c.totalProfit : m);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 100 : maxY * 1.2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (v, _) => Text(
                      '\$${v.toInt()}',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= top.length) {
                        return const SizedBox.shrink();
                      }
                      // اختصر الاسم لثلاث كلمات
                      final name = top[i].customerName.split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          name,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: top.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.totalProfit,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.profitColor,
                        ],
                      ),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final c = top[group.x];
                    return BarTooltipItem(
                      '${c.customerName}\n${AppFormatters.currency(c.totalProfit)}\n${c.ordersCount} طلب',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ترتيب نصي
        ...top.asMap().entries.map((e) => _CustomerRankRow(
              rank: e.key + 1,
              stats: e.value,
            )),
      ],
    );
  }
}

class _CustomerRankRow extends StatelessWidget {
  final int rank;
  final TopCustomerStats stats;

  const _CustomerRankRow({required this.rank, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalColors = [
      const Color(0xFFFFD700), // ذهبي
      const Color(0xFFC0C0C0), // فضي
      const Color(0xFFCD7F32), // برونزي
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? medalColors[rank - 1].withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: rank <= 3
                      ? medalColors[rank - 1]
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(stats.customerName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(
            '${stats.ordersCount} طلب',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.currency(stats.totalProfit),
            style: TextStyle(
              color: AppColors.profitColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- مساعدات ----

class _ChartShimmer extends StatelessWidget {
  const _ChartShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  final String error;
  const _ChartError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('خطأ في تحميل البيانات: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('لا توجد بيانات كافية بعد',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
