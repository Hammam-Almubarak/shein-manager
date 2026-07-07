import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/customers_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../providers/orders_providers.dart';
import '../../widgets/order_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer.dart';

/// شاشة بروفايل العميل الكامل:
/// - بيانات العميل (الاسم، الهاتف، الملاحظات)
/// - إحصائياته (عدد الطلبات، إجمالي الربح، آخر طلب)
/// - قائمة كل طلباته المرتبطة
class CustomerProfileScreen extends ConsumerWidget {
  final int customerId;

  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider(customerId));

    return profileAsync.when(
      data: (profile) => _ProfileBody(profile: profile, customerId: customerId),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('بروفايل العميل')),
        body: const _ProfileShimmer(),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('بروفايل العميل')),
        body: Center(child: Text('خطأ في التحميل: $err')),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final dynamic profile; // CustomerProfile
  final int customerId;

  const _ProfileBody({required this.profile, required this.customerId});

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    final customer = profile.customer as Customer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف العميل؟'),
        content: Text(
          'سيتم حذف "${customer.fullName}" وكل طلباته نهائيًا.\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deleteCustomerUseCaseProvider).call(customerId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customer = profile.customer as Customer;

    // جلب طلبات هذا العميل تحديدًا من الـ provider الموجود
    final allOrdersAsync = ref.watch(ordersListProvider);
    final ordersAsync = allOrdersAsync.whenData(
      (orders) => orders.where((o) => o.customer.id == customerId).toList(),
    );

    final initials = customer.fullName.trim().isNotEmpty
        ? customer.fullName.trim()[0].toUpperCase()
        : '؟';

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'تعديل',
            onPressed: () => context.push(
              '/customers/${customer.id}/edit',
              extra: customer,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
            tooltip: 'حذف العميل',
            onPressed: () => _deleteCustomer(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // بطاقة بيانات العميل
          _CustomerInfoCard(customer: customer, initials: initials),
          const SizedBox(height: 16),

          // إحصائيات سريعة
          _StatsRow(profile: profile),
          const SizedBox(height: 24),

          // عنوان قائمة الطلبات
          Text(
            'طلبات العميل',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // قائمة الطلبات
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return _EmptyOrders(customerName: customer.fullName);
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
            loading: () => const Center(
              heightFactor: 3,
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Text('خطأ: $err'),
          ),
        ],
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final Customer customer;
  final String initials;

  const _CustomerInfoCard({required this.customer, required this.initials});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عميل منذ ${AppFormatters.date(customer.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // رقم الهاتف (قابل للضغط للاتصال)
            InkWell(
              onTap: () => launchUrl(Uri.parse('tel:${customer.phoneNumber}')),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    customer.phoneNumber,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.call_rounded,
                      color: theme.colorScheme.primary, size: 18),
                ],
              ),
            ),
            if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      color: theme.colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      customer.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic profile;

  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _StatBox(
          label: 'إجمالي الطلبات',
          value: '${profile.totalOrders}',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'إجمالي الربح',
          value: AppFormatters.currency(profile.totalProfit),
          icon: Icons.trending_up_rounded,
          color: AppColors.profitColor,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final String customerName;

  const _EmptyOrders({required this.customerName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 52, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('لا توجد طلبات لـ $customerName بعد',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
                height: 160,
                decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            Container(
                height: 80,
                decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
