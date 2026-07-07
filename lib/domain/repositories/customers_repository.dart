import '../entities/customer.dart';

/// عقد مستودع العملاء - طبقة الـ Domain لا تعرف شي عن Drift أو SQLite إطلاقًا
/// طبقة الـ Data (Phase 4) هي من ستنفّذ هذا العقد فعليًا
abstract class CustomersRepository {
  Future<List<Customer>> getAllCustomers();
  Stream<List<Customer>> watchAllCustomers();
  Future<Customer?> getCustomerById(int id);
  Future<List<Customer>> searchCustomers(String query);

  Future<int> createCustomer({
    required String fullName,
    required String phoneNumber,
    String? notes,
  });

  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(int id);

  /// يجلب بروفايل العميل الكامل (عدد الطلبات + الربح الكلي + آخر طلب)
  Future<CustomerProfile> getCustomerProfile(int customerId);
}
