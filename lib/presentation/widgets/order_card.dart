import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';
import 'order_status_badge.dart';

/// بطاقة طلب واحدة - تُستخدم في الداشبورد (آخر الطلبات) وشاشة الطلبات الكاملة
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OrderStatusBadge(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customer.fullName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniInfo(
                    icon: Icons.inventory_2_outlined,
                    label: '${order.itemsCount} منتج',
                  ),
                  const SizedBox(width: 16),
                  _MiniInfo(
                    icon: Icons.calendar_today_outlined,
                    label: AppFormatters.date(order.orderDate),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AmountColumn(
                    label: 'الشراء',
                    value: order.purchaseTotal,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  _AmountColumn(
                    label: 'البيع',
                    value: order.sellingTotal,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  _AmountColumn(
                    label: 'الربح',
                    value: order.profitTotal,
                    color: const Color(0xFF00C9A7),
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _AmountColumn({
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
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          AppFormatters.currency(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
