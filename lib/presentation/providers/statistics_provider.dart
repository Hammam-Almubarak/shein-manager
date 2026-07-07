import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import '../../core/constants/order_status.dart';
import '../../domain/entities/order.dart';

/// بيانات الإحصائيات الشهرية (آخر 6 أشهر)
class MonthlyStats {
  final DateTime month; // أول يوم في الشهر
  final double profit;
  final double sales;
  final int ordersCount;

  const MonthlyStats({
    required this.month,
    required this.profit,
    required this.sales,
    required this.ordersCount,
  });
}

/// إحصائيات توزيع الطلبات حسب الحالة
class StatusStats {
  final OrderStatus status;
  final int count;
  final double percentage;

  const StatusStats({
    required this.status,
    required this.count,
    required this.percentage,
  });
}

/// أفضل عميل حسب الربح
class TopCustomerStats {
  final String customerName;
  final double totalProfit;
  final int ordersCount;

  const TopCustomerStats({
    required this.customerName,
    required this.totalProfit,
    required this.ordersCount,
  });
}

/// يجلب كل الطلبات (بدون فلاتر) لحساب الإحصائيات
final _allOrdersForStatsProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

/// إحصائيات الأشهر الستة الأخيرة
final monthlyStatsProvider = FutureProvider<List<MonthlyStats>>((ref) async {
  final orders = await ref.watch(_allOrdersForStatsProvider.future);
  final now = DateTime.now();

  // بناء قائمة آخر 6 أشهر
  final months = <DateTime>[];
  for (int i = 5; i >= 0; i--) {
    months.add(DateTime(now.year, now.month - i, 1));
  }

  return months.map((monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    final monthOrders = orders
        .where((o) =>
            o.status != OrderStatus.cancelled &&
            o.orderDate.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
            o.orderDate.isBefore(monthEnd))
        .toList();

    return MonthlyStats(
      month: monthStart,
      profit: monthOrders.fold(0.0, (sum, o) => sum + o.profitTotal),
      sales: monthOrders.fold(0.0, (sum, o) => sum + o.sellingTotal),
      ordersCount: monthOrders.length,
    );
  }).toList();
});

/// توزيع الطلبات حسب الحالة (للرسم البياني الدائري)
final statusStatsProvider = FutureProvider<List<StatusStats>>((ref) async {
  final orders = await ref.watch(_allOrdersForStatsProvider.future);
  if (orders.isEmpty) return [];

  final countByStatus = <OrderStatus, int>{};
  for (final o in orders) {
    countByStatus[o.status] = (countByStatus[o.status] ?? 0) + 1;
  }

  return countByStatus.entries
      .map((e) => StatusStats(
            status: e.key,
            count: e.value,
            percentage: e.value / orders.length * 100,
          ))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
});

/// أفضل 5 عملاء حسب الربح الإجمالي
final topCustomersProvider = FutureProvider<List<TopCustomerStats>>((ref) async {
  final orders = await ref.watch(_allOrdersForStatsProvider.future);
  if (orders.isEmpty) return [];

  // تجميع الربح وعدد الطلبات لكل عميل
  final Map<String, ({double profit, int count})> customerMap = {};

  for (final order in orders) {
    if (order.status == OrderStatus.cancelled) continue;
    final name = order.customer.fullName;
    final existing = customerMap[name];
    customerMap[name] = (
      profit: (existing?.profit ?? 0) + order.profitTotal,
      count: (existing?.count ?? 0) + 1,
    );
  }

  final sorted = customerMap.entries
      .map((e) => TopCustomerStats(
            customerName: e.key,
            totalProfit: e.value.profit,
            ordersCount: e.value.count,
          ))
      .toList()
    ..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

  return sorted.take(5).toList();
});
