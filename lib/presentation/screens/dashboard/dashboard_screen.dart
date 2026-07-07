import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/orders_providers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/order_card.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/dashboard_stats.dart';

/// شاشة الداشبورد الرئيسية - أول شاشة يراها المندوب عند فتح التطبيق
/// تعرض: إحصائيات سريعة + آخر الطلبات، وتتحدث تلقائيًا لحظيًا
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(recentOrdersProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              data: (stats) => _StatsGrid(stats: stats),
              loading: () => const _StatsGridShimmer(),
              error: (err, _) => _ErrorBox(message: 'تعذر تحميل الإحصائيات: $err'),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر الطلبات',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const _EmptyOrders();
                }
                return Column(
                  children: orders
                      .map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OrderCard(order: o),
                          ))
                      .toList(),
                );
              },
              loading: () => const _RecentOrdersShimmer(),
              error: (err, _) => _ErrorBox(message: 'تعذر تحميل الطلبات: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

/// شبكة بطاقات الإحصائيات الثمانية
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <StatCard>[
      StatCard(
        label: 'إجمالي العملاء',
        value: '${stats.totalCustomers}',
        icon: Icons.people_alt_rounded,
        color: AppColors.secondary,
        animationIndex: 0,
      ),
      StatCard(
        label: 'إجمالي الطلبات',
        value: '${stats.totalOrders}',
        icon: Icons.receipt_long_rounded,
        color: AppColors.primary,
        animationIndex: 1,
      ),
      StatCard(
        label: 'الطلبات النشطة',
        value: '${stats.activeOrders}',
        icon: Icons.pending_actions_rounded,
        color: AppColors.statusOrdered,
        animationIndex: 2,
      ),
      StatCard(
        label: 'الطلبات المسلَّمة',
        value: '${stats.deliveredOrders}',
        icon: Icons.check_circle_rounded,
        color: AppColors.statusDelivered,
        animationIndex: 3,
      ),
      StatCard(
        label: 'بانتظار الوصول',
        value: '${stats.waitingOrders}',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.statusShipped,
        animationIndex: 4,
      ),
      StatCard(
        label: 'إجمالي الشراء',
        value: AppFormatters.currency(stats.totalPurchaseAmount),
        icon: Icons.shopping_bag_rounded,
        color: AppColors.purchaseColor,
        animationIndex: 5,
      ),
      StatCard(
        label: 'إجمالي البيع',
        value: AppFormatters.currency(stats.totalSellingAmount),
        icon: Icons.sell_rounded,
        color: AppColors.sellingColor,
        animationIndex: 6,
      ),
      StatCard(
        label: 'إجمالي الربح',
        value: AppFormatters.currency(stats.totalProfit),
        icon: Icons.trending_up_rounded,
        color: AppColors.profitColor,
        animationIndex: 7,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items,
    );
  }
}

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: List.generate(
          8,
          (_) => Container(
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOrdersShimmer extends StatelessWidget {
  const _RecentOrdersShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('لا توجد طلبات بعد', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
