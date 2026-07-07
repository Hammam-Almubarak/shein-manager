import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import '../../core/constants/order_status.dart';
import '../../core/constants/orders_sort_by.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

/// معاملات فلترة/فرز قائمة الطلبات - كائن واحد يجمعهم لتسهيل استخدام
/// Provider.family (Riverpod يحتاج معاملة قابلة للمقارنة بـ == و hashCode)
class OrdersFilter {
  final String? searchQuery;
  final OrderStatus? statusFilter;
  final OrdersSortBy sortBy;

  const OrdersFilter({
    this.searchQuery,
    this.statusFilter,
    this.sortBy = OrdersSortBy.dateDesc,
  });

  OrdersFilter copyWith({
    String? searchQuery,
    OrderStatus? statusFilter,
    OrdersSortBy? sortBy,
    bool clearStatusFilter = false,
  }) {
    return OrdersFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrdersFilter &&
      other.searchQuery == searchQuery &&
      other.statusFilter == statusFilter &&
      other.sortBy == sortBy;

  @override
  int get hashCode => Object.hash(searchQuery, statusFilter, sortBy);
}

/// حالة الفلتر الحالية بشاشة الطلبات (يُعدَّل من واجهة البحث/الفلاتر)
final ordersFilterProvider =
    StateProvider<OrdersFilter>((ref) => const OrdersFilter());

/// قائمة الطلبات المفلترة/المرتبة حسب ordersFilterProvider
final ordersListProvider = FutureProvider<List<Order>>((ref) {
  final filter = ref.watch(ordersFilterProvider);
  return ref.watch(ordersRepositoryProvider).getOrders(
        searchQuery: filter.searchQuery,
        statusFilter: filter.statusFilter,
        sortBy: filter.sortBy,
      );
});

/// آخر 5 طلبات - تُعرض بالداشبورد، تتحدث لحظيًا
final recentOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchRecentOrders(limit: 5);
});

/// تفاصيل طلب واحد كامل (بعناصره) - يُستخدم في شاشة تفاصيل الطلب
final orderDetailsProvider =
    FutureProvider.family<Order?, int>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).getOrderById(orderId);
});

/// عناصر طلب معيّن - Stream حي (يتحدث فورًا عند إضافة/تعديل/حذف عنصر)
final orderItemsProvider =
    StreamProvider.family<List<OrderItem>, int>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).watchItemsForOrder(orderId);
});
