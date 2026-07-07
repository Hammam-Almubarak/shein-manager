import 'package:drift/drift.dart';

/// جدول المنتجات (منتجات SHEIN التي طُلبت من قبل الزبائن)
/// ملاحظة: هذا التطبيق ليس نظام مخزون - المندوب لا يملك هذه المنتجات،
/// هذا الجدول فقط لتخزين بيانات المنتج المرجعية لكل عنصر طلب.
@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// معرف المنتج في موقع SHEIN (يُستخدم في البحث الشامل)
  TextColumn get sheinProductId => text().withLength(min: 1, max: 100)();

  /// رابط المنتج على SHEIN
  TextColumn get sheinUrl => text()();

  /// عنوان المنتج
  TextColumn get title => text().withLength(min: 1, max: 250)();

  /// وصف المنتج
  TextColumn get description => text().nullable()();

  /// مسار/رابط صورة المنتج
  TextColumn get image => text().nullable()();

  /// اللون
  TextColumn get color => text().nullable()();

  /// المقاس
  TextColumn get size => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
