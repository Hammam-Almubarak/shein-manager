import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/customers_dao.dart';
import '../../data/database/daos/products_dao.dart';
import '../../data/database/daos/orders_dao.dart';
import '../../data/database/daos/order_items_dao.dart';

/// مثيل واحد فقط من قاعدة البيانات لكل عمر التطبيق (Singleton)
/// keepAlive: true لأن قاعدة البيانات يجب أن تبقى مفتوحة طوال تشغيل التطبيق
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final customersDaoProvider = Provider<CustomersDao>((ref) {
  return ref.watch(appDatabaseProvider).customersDao;
});

final productsDaoProvider = Provider<ProductsDao>((ref) {
  return ref.watch(appDatabaseProvider).productsDao;
});

final ordersDaoProvider = Provider<OrdersDao>((ref) {
  return ref.watch(appDatabaseProvider).ordersDao;
});

final orderItemsDaoProvider = Provider<OrderItemsDao>((ref) {
  return ref.watch(appDatabaseProvider).orderItemsDao;
});
