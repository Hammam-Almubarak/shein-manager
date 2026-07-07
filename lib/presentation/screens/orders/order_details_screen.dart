import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../providers/orders_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/order_status_badge.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_item.dart';
import 'add_order_item_sheet.dart';

/// شاشة تفاصيل الطلب الكاملة:
/// - معلومات الطلب الأساسية
/// - تغيير الحالة
/// - قائمة المنتجات مع إمكانية الإضافة/التعديل/الحذف
/// - مجاميع تلقائية في الأسفل
class OrderDetailsScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل الطلب')),
            body: const Center(child: Text('الطلب غير موجود')),
          );
        }
        return _OrderDetailsBody(
          order: order,
          itemsAsync: itemsAsync,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: Center(child: Text('خطأ: $err')),
      ),
    );
  }
}

class _OrderDetailsBody extends ConsumerStatefulWidget {
  final Order order;
  final AsyncValue<List<OrderItem>> itemsAsync;

  const _OrderDetailsBody({required this.order, required this.itemsAsync});

  @override
  ConsumerState<_OrderDetailsBody> createState() => _OrderDetailsBodyState();
}

class _OrderDetailsBodyState extends ConsumerState<_OrderDetailsBody> {
  Future<void> _changeStatus(BuildContext context) async {
    final current = widget.order.status;
    final result = await showModalBottomSheet<OrderStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusPicker(currentStatus: current),
    );
    if (result != null && result != current) {
      try {
        await ref.read(updateOrderStatusUseCaseProvider).call(
              orderId: widget.order.id,
              currentStatus: current,
              newStatus: result,
            );
        ref.invalidate(orderDetailsProvider(widget.order.id));
        ref.invalidate(dashboardStatsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('تم تحديث الحالة إلى: ${result.labelAr}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الطلب؟'),
        content: Text(
          'سيتم حذف الطلب "${widget.order.orderNumber}" وكل منتجاته نهائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deleteOrderUseCaseProvider).call(widget.order.id);
      ref.invalidate(dashboardStatsProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteItem(OrderItem item) async {
    try {
      await ref.read(deleteOrderItemUseCaseProvider).call(
            itemId: item.id,
            orderId: widget.order.id,
          );
      ref.invalidate(orderDetailsProvider(widget.order.id));
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
      }
    }
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddOrderItemSheet(
        orderId: widget.order.id,
        onSaved: () {
          ref.invalidate(orderItemsProvider(widget.order.id));
          ref.invalidate(orderDetailsProvider(widget.order.id));
          ref.invalidate(dashboardStatsProvider);
        },
      ),
    );
  }

  void _editItem(OrderItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddOrderItemSheet(
        orderId: widget.order.id,
        existingItem: item,
        onSaved: () {
          ref.invalidate(orderItemsProvider(widget.order.id));
          ref.invalidate(orderDetailsProvider(widget.order.id));
          ref.invalidate(dashboardStatsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert_circle_outlined),
            tooltip: 'تغيير الحالة',
            onPressed: () => _changeStatus(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error),
            tooltip: 'حذف الطلب',
            onPressed: () => _deleteOrder(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                // بطاقة معلومات الطلب
                _OrderHeaderCard(order: order, onChangeStatus: () => _changeStatus(context)),
                const SizedBox(height: 16),

                // عنوان المنتجات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المنتجات',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('إضافة منتج'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // قائمة المنتجات
                widget.itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return _EmptyItems(onAdd: _addItem);
                    }
                    return Column(
                      children: items
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Slidable(
                                  key: ValueKey(e.value.id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _editItem(e.value),
                                        backgroundColor: theme.colorScheme.secondary,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit_rounded,
                                        label: 'تعديل',
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(14),
                                          bottomRight: Radius.circular(14),
                                        ),
                                      ),
                                      SlidableAction(
                                        onPressed: (_) => _deleteItem(e.value),
                                        backgroundColor: theme.colorScheme.error,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete_rounded,
                                        label: 'حذف',
                                      ),
                                    ],
                                  ),
                                  child: _OrderItemCard(item: e.value),
                                ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)).slideY(begin: 0.1, end: 0),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                      heightFactor: 3, child: CircularProgressIndicator()),
                  error: (err, _) => Text('خطأ: $err'),
                ),
              ],
            ),
          ),

          // مجاميع في الأسفل
          _TotalsBar(order: order),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'إضافة منتج',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ---- بطاقة معلومات الطلب ----

class _OrderHeaderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onChangeStatus;

  const _OrderHeaderCard({required this.order, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customer.fullName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(order.customer.phoneNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onChangeStatus,
                  child: OrderStatusBadge(status: order.status),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(icon: Icons.calendar_today_outlined,
                label: 'تاريخ الطلب', value: AppFormatters.date(order.orderDate)),
            if (order.expectedArrivalDate != null)
              _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'وصول متوقع',
                  value: AppFormatters.date(order.expectedArrivalDate!)),
            if (order.arrivalDate != null)
              _InfoRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'تاريخ الوصول الفعلي',
                  value: AppFormatters.date(order.arrivalDate!)),
            if (order.notes != null && order.notes!.isNotEmpty)
              _InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'ملاحظات',
                  value: order.notes!),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---- بطاقة عنصر الطلب ----

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج أو placeholder
              _ProductImage(imageUrl: item.product.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.product.color != null || item.product.size != null)
                      Wrap(
                        spacing: 6,
                        children: [
                          if (item.product.color != null)
                            _Chip(Icons.palette_outlined, item.product.color!),
                          if (item.product.size != null)
                            _Chip(Icons.straighten_rounded, item.product.size!),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'كمية: ${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      'ID: ${item.product.sheinProductId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // أسعار الوحدة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceBox(
                label: 'شراء الوحدة',
                value: item.purchasePrice,
                color: AppColors.purchaseColor,
              ),
              _PriceBox(
                label: 'بيع الوحدة',
                value: item.sellingPrice,
                color: AppColors.sellingColor,
              ),
              _PriceBox(
                label: 'ربح الإجمالي',
                value: item.profitSubtotal,
                color: AppColors.profitColor,
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(theme),
        ),
      );
    }
    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.inventory_2_outlined,
            color: theme.colorScheme.onSurfaceVariant, size: 28),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _PriceBox({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          AppFormatters.currency(value),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 14 : 12,
          ),
        ),
      ],
    );
  }
}

// ---- مجاميع الأسفل ----

class _TotalsBar extends StatelessWidget {
  final Order order;

  const _TotalsBar({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TotalColumn(
            label: 'إجمالي الشراء',
            value: order.purchaseTotal,
            color: AppColors.purchaseColor,
          ),
          _TotalColumn(
            label: 'إجمالي البيع',
            value: order.sellingTotal,
            color: AppColors.sellingColor,
          ),
          _TotalColumn(
            label: 'إجمالي الربح',
            value: order.profitTotal,
            color: AppColors.profitColor,
            prominent: true,
          ),
        ],
      ),
    );
  }
}

class _TotalColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool prominent;

  const _TotalColumn({
    required this.label,
    required this.value,
    required this.color,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppFormatters.currency(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: prominent ? 18 : 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---- قائمة الحالات ----

class _StatusPicker extends StatelessWidget {
  final OrderStatus currentStatus;

  const _StatusPicker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('تغيير الحالة',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...OrderStatus.values.map((s) {
            final isSelected = s == currentStatus;
            return ListTile(
              leading: OrderStatusBadge(status: s, compact: true),
              title: Text(s.labelAr),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              selected: isSelected,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pop(context, s),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyItems({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.add_box_outlined,
              size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('لا توجد منتجات بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة أول منتج'),
          ),
        ],
      ),
    );
  }
}
