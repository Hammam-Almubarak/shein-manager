import '../repositories/customers_repository.dart';

/// UseCase: إنشاء عميل جديد مع التحقق من صحة المدخلات
class CreateCustomerUseCase {
  final CustomersRepository _repository;
  const CreateCustomerUseCase(this._repository);

  Future<int> call({
    required String fullName,
    required String phoneNumber,
    String? notes,
  }) {
    final name = fullName.trim();
    final phone = phoneNumber.trim();

    if (name.isEmpty) throw ArgumentError('اسم العميل مطلوب');
    if (phone.isEmpty) throw ArgumentError('رقم الهاتف مطلوب');
    if (name.length < 2) throw ArgumentError('الاسم يجب أن يكون حرفين على الأقل');

    return _repository.createCustomer(
      fullName: name,
      phoneNumber: phone,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
  }
}
