import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/customers_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../widgets/customer_card.dart';
import '../../../domain/entities/customer.dart';

/// شاشة قائمة العملاء - أول شاشة من المرحلة 7
/// تعرض كل العملاء ببطاقات، مع بحث حي فوري بالاسم أو رقم الهاتف،
/// وإمكانية حذف العميل بالسحب (Slidable) بعد تأكيد صريح.
class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Customer customer) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف العميل؟'),
        content: Text(
          'سيتم حذف "${customer.fullName}" وكل طلباته المرتبطة به نهائيًا. '
          'هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(deleteCustomerUseCaseProvider).call(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف "${customer.fullName}"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(customerSearchQueryProvider.notifier).state = value,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customerSearchQueryProvider.notifier)
                              .state = '';
                          setState(() {});
                        },
                      ),
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: filteredCustomersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  final hasQuery =
                      ref.watch(customerSearchQueryProvider).trim().isNotEmpty;
                  return _EmptyState(hasQuery: hasQuery);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(customersListProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Slidable(
                        key: ValueKey(customer.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.28,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _confirmDelete(customer),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'حذف',
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ],
                        ),
                        child: CustomerCard(
                          customer: customer,
                          onTap: () =>
                              context.push('/customers/${customer.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const _CustomersListShimmer(),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('تعذر تحميل العملاء: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/new'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('عميل جديد'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'لا توجد نتائج مطابقة' : 'لا يوجد عملاء بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'جرّب اسمًا أو رقم هاتف مختلف'
                  : 'اضغط على "عميل جديد" لإضافة أول عميل',
              textAlign: TextAlign.center,
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

class _CustomersListShimmer extends StatelessWidget {
  const _CustomersListShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.4),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 84,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
