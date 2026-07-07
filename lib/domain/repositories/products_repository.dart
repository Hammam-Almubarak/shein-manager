import '../entities/product.dart';

/// عقد مستودع المنتجات
abstract class ProductsRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<List<Product>> searchBySheinId(String sheinProductId);

  Future<int> createProduct({
    required String sheinProductId,
    required String sheinUrl,
    required String title,
    String? description,
    String? image,
    String? color,
    String? size,
  });

  Future<void> updateProduct(Product product);

  /// يرمي استثناء إذا كان المنتج مستخدمًا ضمن طلب فعلي (Restrict على مستوى القاعدة)
  Future<void> deleteProduct(int id);
}
