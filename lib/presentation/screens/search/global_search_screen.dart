import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/global_search_provider.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/order_card.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/order.dart';

/// حالة البحث الشامل المحلي (بدون ضرب قاعدة البيانات عند كل حرف)
class _SearchState {
  final List<Customer> customers;
  final List<Order> orders;
  final bool hasQuery;

  const _SearchState({
    this.customers = const [],
    this.orders = const [],
    this.hasQuery = false,
  });

  bool get isEmpty => customers.isEmpty && orders.isEmpty;
}

/// شاشة البحث الشامل - تبحث في العملاء + الطلبات + معرفات SHEIN لحظيًا
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _SearchState _computeResults({
    required List<Customer> allCustomers,
    required List<Order> allOrders,
  }) {
    if (_query.isEmpty) return const _SearchState(hasQuery: false);
    final q = _query.toLowerCase();

    final customers = allCustomers
        .where((c) =>
            c.fullName.toLowerCase().contains(q) || c.phoneNumber.contains(q))
        .toList();

    final orders = allOrders
        .where((o) =>
            o.orderNumber.toLowerCase().contains(q) ||
            o.customer.fullName.toLowerCase().contains(q) ||
            o.customer.phoneNumber.contains(q) ||
            o.items.any(
                (i) => i.product.sheinProductId.toLowerCase().contains(q)))
        .toList();

    return _SearchState(
        customers: customers, orders: orders, hasQuery: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customersListProvider);
    final ordersAsync = ref.watch(ordersListProvider);

    // نبني نتائج البحث من الـ cache الموجود
    final results = customersAsync.maybeWhen(
      data: (customers) => ordersAsync.maybeWhen(
        data: (orders) => _computeResults(
            allCustomers: customers, allOrders: orders),
        orElse: () => const _SearchState(),
      ),
      orElse: () => const _SearchState(),
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v.trim()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم، الهاتف، رقم الطلب، ID SHEIN...',
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? _SearchHint()
          : results.isEmpty && results.hasQuery
              ? _NoResults(query: _query)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // ---- العملاء ----
                    if (results.customers.isNotEmpty) ...[
                      _SectionTitle(
                        icon: Icons.people_alt_rounded,
                        title: 'العملاء',
                        count: results.customers.length,
                      ),
                      const SizedBox(height: 8),
                      ...results.customers.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CustomerCard(
                              customer: c,
                              onTap: () => context.push('/customers/${c.id}'),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],

                    // ---- الطلبات ----
                    if (results.orders.isNotEmpty) ...[
                      _SectionTitle(
                        icon: Icons.receipt_long_rounded,
                        title: 'الطلبات',
                        count: results.orders.length,
                      ),
                      const SizedBox(height: 8),
                      ...results.orders.map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: OrderCard(
                              order: o,
                              onTap: () => context.push('/orders/${o.id}'),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('ابحث عن أي شيء',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'الاسم · الهاتف · رقم الطلب · معرّف SHEIN',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text('لا توجد نتائج لـ "$query"',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'جرّب كلمات بحث أخرى',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
