import '../repositories/orders_repository.dart';

/// UseCase: إضافة منتج إلى طلب موجود
/// يتحقق من صحة المدخلات قبل الحفظ (قواعد العمل الأساسية)
class AddOrderItemUseCase {
  final OrdersRepository _ordersRepository;

  const AddOrderItemUseCase(this._ordersRepository);

  Future<int> call({
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
    // ملاحظة قصدية: لا نمنع سعر بيع أقل من سعر الشراء هنا (قد يبيع بخسارة
    // مقصودة أحيانًا) لكن الواجهة يجب أن تُظهر تحذيرًا بصريًا في هذه الحالة.

    return _ordersRepository.addOrderItem(
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );
  }
}
