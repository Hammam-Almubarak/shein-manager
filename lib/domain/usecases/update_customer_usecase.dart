import '../entities/customer.dart';
import '../repositories/customers_repository.dart';

/// UseCase: تعديل بيانات عميل موجود
class UpdateCustomerUseCase {
  final CustomersRepository _repository;
  const UpdateCustomerUseCase(this._repository);

  Future<void> call(Customer customer) {
    final name = customer.fullName.trim();
    final phone = customer.phoneNumber.trim();

    if (name.isEmpty) throw ArgumentError('اسم العميل مطلوب');
    if (phone.isEmpty) throw ArgumentError('رقم الهاتف مطلوب');
    if (name.length < 2) throw ArgumentError('الاسم يجب أن يكون حرفين على الأقل');

    return _repository.updateCustomer(
      customer.copyWith(
        fullName: name,
        phoneNumber: phone,
        notes: customer.notes?.trim().isEmpty == true ? null : customer.notes?.trim(),
      ),
    );
  }
}
