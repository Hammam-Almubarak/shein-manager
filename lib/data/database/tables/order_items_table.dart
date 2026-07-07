import 'package:drift/drift.dart';
import 'orders_table.dart';
import 'products_table.dart';

/// جدول عناصر الطلب - كل عنصر يمثل منتج واحد ضمن طلب معين
/// الطلب الواحد يمكن أن يحتوي على عدد غير محدود من العناصر (One-to-Many)
@DataClassName('OrderItemRow')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// الطلب الأب - عند حذف الطلب تُحذف عناصره تلقائيًا
  IntColumn get orderId =>
      integer().references(Orders, #id, onDelete: KeyAction.cascade)();

  /// المنتج المرتبط بهذا العنصر
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();

  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// سعر الشراء من SHEIN للوحدة الواحدة (وليس "رأس المال")
  RealColumn get purchasePrice => real()();

  /// سعر البيع للزبون للوحدة الواحدة
  RealColumn get sellingPrice => real()();

  /// purchasePrice * quantity - محسوب تلقائيًا عند الحفظ
  RealColumn get purchaseSubtotal => real().withDefault(const Constant(0))();

  /// sellingPrice * quantity - محسوب تلقائيًا عند الحفظ
  RealColumn get sellingSubtotal => real().withDefault(const Constant(0))();

  /// sellingSubtotal - purchaseSubtotal - محسوب تلقائيًا، الربح دائمًا تلقائي
  RealColumn get profitSubtotal => real().withDefault(const Constant(0))();
}
