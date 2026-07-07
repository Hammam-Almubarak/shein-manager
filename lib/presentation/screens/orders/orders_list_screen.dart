import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/orders_providers.dart';
import '../../widgets/order_card.dart';
import '../../widgets/order_status_badge.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/constants/orders_sort_by.dart';

/// شاشة قائمة الطلبات الكاملة مع البحث والفلترة والفرز
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(ordersFilterProvider.notifier).update((f) =>
        f.copyWith(searchQuery: null));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(ordersFilterProvider);
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'فرز',
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(ordersFilterProvider.notifier)
                  .update((f) => f.copyWith(searchQuery: v.trim().isEmpty ? null : v.trim())),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطلب أو اسم العميل...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),

          // رقائق فلاتر الحالة
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // كل الحالات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('الكل'),
                    selected: filter.statusFilter == null,
                    onSelected: (_) => ref.read(ordersFilterProvider.notifier)
                        .update((f) => f.copyWith(clearStatusFilter: true)),
                  ),
                ),
                // حالة واحدة لكل
                ...OrderStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(status.labelAr),
                        selected: filter.statusFilter == status,
                        onSelected: (_) =>
                            ref.read(ordersFilterProvider.notifier).update(
                                  (f) => f.statusFilter == status
                                      ? f.copyWith(clearStatusFilter: true)
                                      : f.copyWith(statusFilter: status),
                                ),
                      ),
                    )),
              ],
            ),
          ),

          // نتائج البادج - عدد الطلبات
          ordersAsync.maybeWhen(
            data: (orders) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${orders.length} طلب',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (filter.statusFilter != null) ...[
                    const SizedBox(width: 8),
                    OrderStatusBadge(status: filter.statusFilter!, compact: true),
                  ],
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // القائمة
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return _EmptyOrders(hasFilter: filter.statusFilter != null ||
                      (filter.searchQuery?.isNotEmpty ?? false));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ordersListProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        onTap: () => context
                            .push('/orders/${order.id}')
                            .then((_) => ref.invalidate(ordersListProvider)),
                      );
                    },
                  ),
                );
              },
              loading: () => const _OrdersShimmer(),
              error: (err, _) => Center(child: Text('خطأ في التحميل: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push('/orders/new')
            .then((_) => ref.invalidate(ordersListProvider)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب جديد'),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(ordersFilterProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('ترتيب حسب',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _SortTile(
                label: 'التاريخ (الأحدث أولاً)',
                icon: Icons.calendar_today_outlined,
                selected: filter.sortBy == OrdersSortBy.dateDesc,
                onTap: () {
                  ref.read(ordersFilterProvider.notifier)
                      .update((f) => f.copyWith(sortBy: OrdersSortBy.dateDesc));
                  Navigator.pop(ctx);
                },
              ),
              _SortTile(
                label: 'التاريخ (الأقدم أولاً)',
                icon: Icons.calendar_today_outlined,
                selected: filter.sortBy == OrdersSortBy.dateAsc,
                onTap: () {
                  ref.read(ordersFilterProvider.notifier)
                      .update((f) => f.copyWith(sortBy: OrdersSortBy.dateAsc));
                  Navigator.pop(ctx);
                },
              ),
              _SortTile(
                label: 'الربح (الأعلى أولاً)',
                icon: Icons.trending_up_rounded,
                selected: filter.sortBy == OrdersSortBy.profitDesc,
                onTap: () {
                  ref.read(ordersFilterProvider.notifier)
                      .update((f) => f.copyWith(sortBy: OrdersSortBy.profitDesc));
                  Navigator.pop(ctx);
                },
              ),
              _SortTile(
                label: 'الربح (الأقل أولاً)',
                icon: Icons.trending_down_rounded,
                selected: filter.sortBy == OrdersSortBy.profitAsc,
                onTap: () {
                  ref.read(ordersFilterProvider.notifier)
                      .update((f) => f.copyWith(sortBy: OrdersSortBy.profitAsc));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: selected ? theme.colorScheme.primary : null),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      selected: selected,
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final bool hasFilter;

  const _EmptyOrders({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'لا توجد طلبات مطابقة' : 'لا توجد طلبات بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'جرّب تغيير الفلتر أو البحث'
                  : 'اضغط على "طلب جديد" لإنشاء أول طلب',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersShimmer extends StatelessWidget {
  const _OrdersShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 140,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
