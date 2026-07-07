import 'package:drift/drift.dart' show Value;

import '../database/daos/products_dao.dart';
import '../database/app_database.dart' show ProductsCompanion, ProductRow;
import '../mappers/product_mapper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsDao _dao;

  const ProductsRepositoryImpl(this._dao);

  @override
  Future<List<Product>> getAllProducts() async {
    final rows = await _dao.getAllProducts();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<Product?> getProductById(int id) async {
    final row = await _dao.getProductById(id);
    return row?.toEntity();
  }

  @override
  Future<List<Product>> searchBySheinId(String sheinProductId) async {
    final rows = await _dao.searchBySheinId(sheinProductId);
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<int> createProduct({
    required String sheinProductId,
    required String sheinUrl,
    required String title,
    String? description,
    String? image,
    String? color,
    String? size,
  }) {
    return _dao.createProduct(
      ProductsCompanion.insert(
        sheinProductId: sheinProductId,
        sheinUrl: sheinUrl,
        title: title,
        description: Value(description),
        image: Value(image),
        color: Value(color),
        size: Value(size),
      ),
    );
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _dao.updateProduct(
      ProductRow(
        id: product.id,
        sheinProductId: product.sheinProductId,
        sheinUrl: product.sheinUrl,
        title: product.title,
        description: product.description,
        image: product.image,
        color: product.color,
        size: product.size,
        createdAt: product.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    // ملاحظة: SQLite سيرمي استثناء تلقائيًا إذا كان المنتج مستخدمًا بطلب فعلي
    // (onDelete: KeyAction.restrict معرّف في order_items_table.dart)
    // على واجهة المستخدم التقاط هذا الاستثناء وعرض رسالة واضحة للمستخدم.
    await _dao.deleteProduct(id);
  }
}
