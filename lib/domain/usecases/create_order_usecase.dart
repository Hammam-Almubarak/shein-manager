import '../repositories/orders_repository.dart';

/// UseCase: إنشاء طلب جديد لعميل معيّن
/// (رقم الطلب يُولَّد تلقائيًا في طبقة الـ Data، الطلب يبدأ بدون عناصر)
class CreateOrderUseCase {
  final OrdersRepository _ordersRepository;

  const CreateOrderUseCase(this._ordersRepository);

  Future<int> call({
    required int customerId,
    DateTime? expectedArrivalDate,
    String? notes,
  }) {
    return _ordersRepository.createOrder(
      customerId: customerId,
      expectedArrivalDate: expectedArrivalDate,
      notes: notes,
    );
  }
}
