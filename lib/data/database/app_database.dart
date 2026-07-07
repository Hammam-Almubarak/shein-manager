import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart' as _;

import 'tables/customers_table.dart';
import 'tables/products_table.dart';
import 'tables/orders_table.dart';
import 'tables/order_items_table.dart';
import 'daos/customers_dao.dart';
import 'daos/products_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/order_items_dao.dart';

part 'app_database.g.dart';

/// قاعدة البيانات الرئيسية للتطبيق
/// تحتوي: العملاء - المنتجات - الطلبات - عناصر الطلبات
/// مع كل العلاقات (Foreign Keys) والحذف المتسلسل (Cascade) عند الحاجة
@DriftDatabase(
  tables: [Customers, Products, Orders, OrderItems],
  daos: [CustomersDao, ProductsDao, OrdersDao, OrderItemsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ملاحظة: كل مرة تُضاف/تُعدّل جدول، يجب رفع رقم الإصدار وإضافة migration
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // مكان إضافة خطوات الترقية المستقبلية بين إصدارات قاعدة البيانات
        },
        beforeOpen: (details) async {
          // تفعيل قيود الـ Foreign Keys في SQLite (معطّلة افتراضيًا)
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// فتح اتصال قاعدة البيانات في ملف داخل مجلد بيانات التطبيق
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shein_manager.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
