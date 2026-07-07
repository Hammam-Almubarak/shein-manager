import '../repositories/orders_repository.dart';

/// UseCase: تعديل عنصر طلب موجود
class UpdateOrderItemUseCase {
  final OrdersRepository _ordersRepository;

  const UpdateOrderItemUseCase(this._ordersRepository);

  Future<void> call({
    required int itemId,
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('الكمية يجب أن تكون أكبر من صفر');
    }
    if (purchasePrice < 0 || sellingPrice < 0) {
      throw ArgumentError('الأسعار لا يمكن أن تكون سالبة');
    }

    return _ordersRepository.updateOrderItem(
      itemId: itemId,
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );
  }
}
