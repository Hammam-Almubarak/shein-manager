import '../database/app_database.dart' show ProductRow;
import '../../domain/entities/product.dart';

extension ProductRowMapper on ProductRow {
  Product toEntity() {
    return Product(
      id: id,
      sheinProductId: sheinProductId,
      sheinUrl: sheinUrl,
      title: title,
      description: description,
      image: image,
      color: color,
      size: size,
      createdAt: createdAt,
    );
  }
}
