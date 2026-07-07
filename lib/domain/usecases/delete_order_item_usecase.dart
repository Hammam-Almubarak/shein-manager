import '../repositories/orders_repository.dart';

/// UseCase: حذف عنصر من عناصر الطلب
class DeleteOrderItemUseCase {
  final OrdersRepository _ordersRepository;

  const DeleteOrderItemUseCase(this._ordersRepository);

  Future<void> call({required int itemId, required int orderId}) {
    return _ordersRepository.deleteOrderItem(itemId: itemId, orderId: orderId);
  }
}
