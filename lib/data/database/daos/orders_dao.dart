import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/orders_table.dart';
import '../tables/customers_table.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/constants/orders_sort_by.dart';
import '../../../core/utils/order_number_generator.dart';

part 'orders_dao.g.dart';

/// DAO خاص بجدول الطلبات
/// يشمل: توليد رقم الطلب، الإنشاء، تعديل الحالة، الفلترة، الفرز،
/// وإحصائيات الداشبورد (عدد الطلبات النشطة/المسلّمة/الخ)
@DriftAccessor(tables: [Orders, Customers])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  /// يولّد رقم الطلب التالي لسنة معينة، مثال: ORD-2026-0007
  /// يعتمد على عدّ الطلبات الحالية لنفس السنة + 1
  Future<String> generateNextOrderNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final startOfYear = DateTime(year, 1, 1);
    final startOfNextYear = DateTime(year + 1, 1, 1);

    final countExp = orders.id.count();
    final query = selectOnly(orders)
      ..addColumns([countExp])
      ..where(orders.orderDate.isBiggerOrEqualValue(startOfYear) &
          orders.orderDate.isSmallerThanValue(startOfNextYear));

    final row = await query.getSingle();
    final currentCount = row.read(countExp) ?? 0;

    return OrderNumberGenerator.generate(year: year, seq: currentCount + 1);
  }

  /// إنشاء طلب جديد فارغ (بدون عناصر بعد) - رقم الطلب يُولَّد تلقائيًا هنا
  Future<int> createOrder({
    required int customerId,
    DateTime? expectedArrivalDate,
    String? notes,
  }) async {
    final orderNumber = await generateNextOrderNumber();
    return into(orders).insert(
      OrdersCompanion.insert(
        orderNumber: orderNumber,
        customerId: customerId,
        expectedArrivalDate: Value(expectedArrivalDate),
        notes: Value(notes),
      ),
    );
  }

  Future<OrderRow?> getOrderById(int id) {
    return (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateOrderStatus(int orderId, OrderStatus status) async {
    final updated = await (update(orders)..where((t) => t.id.equals(orderId)))
        .write(OrdersCompanion(status: Value(status.index)));
    return updated > 0;
  }

  Future<bool> updateOrder(OrderRow row) {
    return update(orders).replace(row);
  }

  /// تحديث ملاحظات الطلب وتاريخ الوصول المتوقع فقط (دون تغيير باقي الحقول)
  Future<void> updateOrderNotes({
    required int orderId,
    String? notes,
    DateTime? expectedArrivalDate,
    bool clearExpectedDate = false,
  }) async {
    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        notes: Value(notes),
        expectedArrivalDate: clearExpectedDate
            ? const Value(null)
            : Value(expectedArrivalDate),
      ),
    );
  }

  /// حذف الطلب يحذف تلقائيًا كل عناصره (Cascade معرّف في order_items_table.dart)
  Future<int> deleteOrder(int id) {
    return (delete(orders)..where((t) => t.id.equals(id))).go();
  }

  /// قائمة الطلبات مع دعم البحث (برقم الطلب) + الفلترة بالحالة + الفرز
  Future<List<OrderRow>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
    OrdersSortBy sortBy = OrdersSortBy.dateDesc,
  }) {
    final query = select(orders);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query.where((t) => t.orderNumber.like('%$searchQuery%'));
    }
    if (statusFilter != null) {
      query.where((t) => t.status.equals(statusFilter.index));
    }

    switch (sortBy) {
      case OrdersSortBy.dateDesc:
        query.orderBy([(t) => OrderingTerm.desc(t.orderDate)]);
        break;
      case OrdersSortBy.dateAsc:
        query.orderBy([(t) => OrderingTerm.asc(t.orderDate)]);
        break;
      case OrdersSortBy.profitDesc:
        query.orderBy([(t) => OrderingTerm.desc(t.profitTotal)]);
        break;
      case OrdersSortBy.profitAsc:
        query.orderBy([(t) => OrderingTerm.asc(t.profitTotal)]);
        break;
    }

    return query.get();
  }

  Stream<List<OrderRow>> watchRecentOrders({int limit = 5}) {
    return (select(orders)
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)])
          ..limit(limit))
        .watch();
  }

  // ---------------------------------------------------------------------
  // إحصائيات الداشبورد
  // ---------------------------------------------------------------------

  Future<int> countAllOrders() async {
    final countExp = orders.id.count();
    final row = await (selectOnly(orders)..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> countByStatus(OrderStatus status) async {
    final countExp = orders.id.count();
    final query = selectOnly(orders)
      ..addColumns([countExp])
      ..where(orders.status.equals(status.index));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// الطلبات "النشطة" = كل شي عدا Delivered و Cancelled
  Future<int> countActiveOrders() async {
    final countExp = orders.id.count();
    final query = selectOnly(orders)
      ..addColumns([countExp])
      ..where(orders.status.isNotIn(
          [OrderStatus.delivered.index, OrderStatus.cancelled.index]));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<double> sumPurchaseTotal() async {
    final sumExp = orders.purchaseTotal.sum();
    final row = await (selectOnly(orders)..addColumns([sumExp])).getSingle();
    return row.read(sumExp) ?? 0.0;
  }

  Future<double> sumSellingTotal() async {
    final sumExp = orders.sellingTotal.sum();
    final row = await (selectOnly(orders)..addColumns([sumExp])).getSingle();
    return row.read(sumExp) ?? 0.0;
  }

  Future<double> sumProfitTotal() async {
    final sumExp = orders.profitTotal.sum();
    final row = await (selectOnly(orders)..addColumns([sumExp])).getSingle();
    return row.read(sumExp) ?? 0.0;
  }
}
