import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers_table.dart';
import '../tables/orders_table.dart';

part 'customers_dao.g.dart';

/// DAO خاص بجدول العملاء
/// يوفر: إنشاء / تعديل / حذف / بحث بالاسم أو الهاتف / ملف العميل الكامل
@DriftAccessor(tables: [Customers, Orders])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  /// كل العملاء مرتبين حسب الأحدث أولًا
  Future<List<CustomerRow>> getAllCustomers() {
    return (select(customers)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// مراقبة لحظية لقائمة العملاء (للاستخدام مع Riverpod StreamProvider)
  Stream<List<CustomerRow>> watchAllCustomers() {
    return (select(customers)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<CustomerRow?> getCustomerById(int id) {
    return (select(customers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// إجمالي عدد العملاء (لإحصائيات الداشبورد)
  Future<int> getTotalCustomersCount() async {
    final countExp = customers.id.count();
    final row = await (selectOnly(customers)..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  /// بحث بالاسم أو رقم الهاتف معًا (بحث شامل موحّد)
  Future<List<CustomerRow>> searchCustomers(String query) {
    final likeQuery = '%$query%';
    return (select(customers)
          ..where((t) =>
              t.fullName.like(likeQuery) | t.phoneNumber.like(likeQuery)))
        .get();
  }

  Future<int> createCustomer(CustomersCompanion entry) {
    return into(customers).insert(entry);
  }

  Future<bool> updateCustomer(CustomerRow row) {
    return update(customers).replace(row);
  }

  /// حذف العميل يحذف تلقائيًا كل طلباته (Cascade معرّف في جدول Orders)
  Future<int> deleteCustomer(int id) {
    return (delete(customers)..where((t) => t.id.equals(id))).go();
  }

  /// إجمالي عدد الطلبات لعميل معيّن
  Future<int> getOrdersCountForCustomer(int customerId) async {
    final countExp = orders.id.count();
    final query = selectOnly(orders)
      ..addColumns([countExp])
      ..where(orders.customerId.equals(customerId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// إجمالي الربح المتراكم لعميل معيّن (من كل طلباته غير الملغاة)
  Future<double> getTotalProfitForCustomer(int customerId) async {
    final profitSum = orders.profitTotal.sum();
    final query = selectOnly(orders)
      ..addColumns([profitSum])
      ..where(orders.customerId.equals(customerId));
    final row = await query.getSingle();
    return row.read(profitSum) ?? 0.0;
  }

  /// آخر طلب للعميل (لعرضه في بروفايل العميل)
  Future<OrderRow?> getLatestOrderForCustomer(int customerId) {
    return (select(orders)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)])
          ..limit(1))
        .getSingleOrNull();
  }
}
