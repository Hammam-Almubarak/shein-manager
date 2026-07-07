import '../../core/constants/order_status.dart';
import '../../core/constants/orders_sort_by.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../entities/dashboard_stats.dart';

/// عقد مستودع الطلبات - العقد الأهم بالتطبيق
abstract class OrdersRepository {
  Future<List<Order>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
    OrdersSortBy sortBy = OrdersSortBy.dateDesc,
  });

  Stream<List<Order>> watchRecentOrders({int limit = 5});

  Future<Order?> getOrderById(int id);

  /// إنشاء طلب جديد فارغ (رقم الطلب يُولَّد تلقائيًا داخل التنفيذ)
  Future<int> createOrder({
    required int customerId,
    DateTime? expectedArrivalDate,
    String? notes,
  });

  Future<void> updateOrderStatus(int orderId, OrderStatus status);

  /// تحديث ملاحظات الطلب وتاريخ الوصول المتوقع فقط
  Future<void> updateOrderNotes({
    required int orderId,
    String? notes,
    DateTime? expectedArrivalDate,
  });

  Future<void> deleteOrder(int orderId);

  // ---- عناصر الطلب ----

  Stream<List<OrderItem>> watchItemsForOrder(int orderId);

  Future<int> addOrderItem({
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  });

  Future<void> updateOrderItem({
    required int itemId,
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  });

  Future<void> deleteOrderItem({required int itemId, required int orderId});

  // ---- الداشبورد ----

  Future<DashboardStats> getDashboardStats();
}
