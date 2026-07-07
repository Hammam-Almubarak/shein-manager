import '../repositories/customers_repository.dart';

/// UseCase: حذف عميل وكل طلباته المرتبطة به (Cascade تلقائي في الـ DB)
class DeleteCustomerUseCase {
  final CustomersRepository _repository;
  const DeleteCustomerUseCase(this._repository);

  Future<void> call(int customerId) {
    return _repository.deleteCustomer(customerId);
  }
}
