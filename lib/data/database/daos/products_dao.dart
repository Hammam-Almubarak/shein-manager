import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';

part 'products_dao.g.dart';

/// DAO خاص بجدول المنتجات (بيانات مرجعية لمنتجات SHEIN)
@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<ProductRow>> getAllProducts() => select(products).get();

  Future<ProductRow?> getProductById(int id) {
    return (select(products)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// بحث بمعرف منتج SHEIN (يُستخدم في البحث الشامل)
  Future<List<ProductRow>> searchBySheinId(String sheinProductId) {
    return (select(products)
          ..where((t) => t.sheinProductId.like('%$sheinProductId%')))
        .get();
  }

  Future<int> createProduct(ProductsCompanion entry) {
    return into(products).insert(entry);
  }

  Future<bool> updateProduct(ProductRow row) {
    return update(products).replace(row);
  }

  /// حذف محمي: إذا كان المنتج مستخدمًا ضمن عنصر طلب سيرفض SQLite الحذف
  /// (onDelete: KeyAction.restrict معرّف في order_items_table.dart)
  Future<int> deleteProduct(int id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }
}
