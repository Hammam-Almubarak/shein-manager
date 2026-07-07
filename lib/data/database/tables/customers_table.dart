import 'package:drift/drift.dart';

/// جدول العملاء
/// كل عميل يمكن أن يملك عدد غير محدود من الطلبات (One-to-Many مع Orders)
@DataClassName('CustomerRow')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// الاسم الكامل للعميل
  TextColumn get fullName => text().withLength(min: 1, max: 150)();

  /// رقم الهاتف - مفهرس للبحث السريع
  TextColumn get phoneNumber => text().withLength(min: 1, max: 30)();

  /// ملاحظات حرة عن العميل
  TextColumn get notes => text().nullable()();

  /// تاريخ إنشاء سجل العميل
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [];
}
