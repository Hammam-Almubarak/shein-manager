import '../../core/constants/order_status.dart';
import '../repositories/orders_repository.dart';

/// UseCase: تغيير حالة الطلب
/// يفرض قاعدة عمل بسيطة: لا يمكن تغيير حالة طلب "ملغى" أو "مُسلَّم" مباشرة
/// إلا بإجراء واعٍ (لا رجوع تلقائي)، لمنع أخطاء تشغيلية بالضغط الخاطئ.
class UpdateOrderStatusUseCase {
  final OrdersRepository _ordersRepository;

  const UpdateOrderStatusUseCase(this._ordersRepository);

  Future<void> call({
    required int orderId,
    required OrderStatus currentStatus,
    required OrderStatus newStatus,
  }) {
    if (currentStatus == OrderStatus.cancelled &&
        newStatus != OrderStatus.cancelled) {
      throw StateError('لا يمكن إعادة تفعيل طلب ملغى مباشرة، أنشئ طلبًا جديدًا بدلًا من ذلك');
    }

    return _ordersRepository.updateOrderStatus(orderId, newStatus);
  }
}
