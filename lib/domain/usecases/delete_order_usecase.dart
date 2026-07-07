import '../repositories/orders_repository.dart';

/// UseCase: حذف طلب وكل عناصره المرتبطة به (Cascade تلقائي في الـ DB)
class DeleteOrderUseCase {
  final OrdersRepository _repository;
  const DeleteOrderUseCase(this._repository);

  Future<void> call(int orderId) {
    return _repository.deleteOrder(orderId);
  }
}
