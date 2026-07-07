import 'package:drift/drift.dart';
import 'customers_table.dart';

/// جدول الطلبات
/// كل طلب مرتبط بعميل واحد (FK -> Customers.id)
/// الإجماليات (purchaseTotal, sellingTotal, profitTotal) تُحسب تلقائيًا
/// من مجموع عناصر الطلب (OrderItems) وتُخزَّن هنا لتسريع عرض القوائم/الداشبورد.
@DataClassName('OrderRow')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// رقم الطلب المُولَّد تلقائيًا، مثال: ORD-2026-0001
  TextColumn get orderNumber => text().withLength(min: 1, max: 40)();

  /// ربط الطلب بالعميل - عند حذف العميل تُحذف طلباته (Cascade)
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get expectedArrivalDate => dateTime().nullable()();

  DateTimeColumn get arrivalDate => dateTime().nullable()();

  /// حالة الطلب مخزنة كـ index من OrderStatus enum
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// إجمالي سعر الشراء من SHEIN (مجموع عناصر الطلب)
  RealColumn get purchaseTotal => real().withDefault(const Constant(0))();

  /// إجمالي سعر البيع للزبون (مجموع عناصر الطلب)
  RealColumn get sellingTotal => real().withDefault(const Constant(0))();

  /// إجمالي الربح = sellingTotal - purchaseTotal (يُحسب تلقائيًا، لا يُدخل يدويًا)
  RealColumn get profitTotal => real().withDefault(const Constant(0))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
