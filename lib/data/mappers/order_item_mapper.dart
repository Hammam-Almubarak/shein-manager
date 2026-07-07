import '../database/app_database.dart' show OrderItemRow;
import '../../domain/entities/order_item.dart';
import '../../domain/entities/product.dart';

extension OrderItemRowMapper on OrderItemRow {
  /// يتطلب كيان المنتج جاهزًا (يُجلب مسبقًا عبر ProductsDao في الـ Repository)
  OrderItem toEntity(Product product) {
    return OrderItem(
      id: id,
      orderId: orderId,
      product: product,
      quantity: quantity,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      purchaseSubtotal: purchaseSubtotal,
      sellingSubtotal: sellingSubtotal,
      profitSubtotal: profitSubtotal,
    );
  }
}
