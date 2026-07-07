import '../repositories/orders_repository.dart';

/// UseCase: تحديث ملاحظات الطلب وتاريخ الوصول المتوقع
class UpdateOrderNotesUseCase {
  final OrdersRepository _repository;
  const UpdateOrderNotesUseCase(this._repository);

  Future<void> call({
    required int orderId,
    String? notes,
    DateTime? expectedArrivalDate,
  }) {
    return _repository.updateOrderNotes(
      orderId: orderId,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      expectedArrivalDate: expectedArrivalDate,
    );
  }
}
