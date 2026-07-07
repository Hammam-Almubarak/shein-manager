import '../repositories/products_repository.dart';

/// UseCase: إنشاء منتج SHEIN جديد كجزء من عملية إضافة عنصر للطلب
class CreateProductUseCase {
  final ProductsRepository _repository;
  const CreateProductUseCase(this._repository);

  Future<int> call({
    required String sheinProductId,
    required String sheinUrl,
    required String title,
    String? description,
    String? image,
    String? color,
    String? size,
  }) {
    final id = sheinProductId.trim();
    final url = sheinUrl.trim();
    final ttl = title.trim();

    if (id.isEmpty) throw ArgumentError('معرّف SHEIN مطلوب');
    if (url.isEmpty) throw ArgumentError('رابط المنتج مطلوب');
    if (ttl.isEmpty) throw ArgumentError('اسم المنتج مطلوب');

    return _repository.createProduct(
      sheinProductId: id,
      sheinUrl: url,
      title: ttl,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      image: image?.trim().isEmpty == true ? null : image?.trim(),
      color: color?.trim().isEmpty == true ? null : color?.trim(),
      size: size?.trim().isEmpty == true ? null : size?.trim(),
    );
  }
}
