import '../database/daos/customers_dao.dart';
import '../database/app_database.dart' show CustomersCompanion, CustomerRow;
import '../mappers/customer_mapper.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import 'package:drift/drift.dart' show Value;

/// التنفيذ الفعلي لعقد CustomersRepository باستخدام Drift (CustomersDao)
class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersDao _dao;

  const CustomersRepositoryImpl(this._dao);

  @override
  Future<List<Customer>> getAllCustomers() async {
    final rows = await _dao.getAllCustomers();
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<Customer>> watchAllCustomers() {
    return _dao.watchAllCustomers().map(
        (rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Customer?> getCustomerById(int id) async {
    final row = await _dao.getCustomerById(id);
    return row?.toEntity();
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    final rows = await _dao.searchCustomers(query);
    return rows.map((r) => r.toEntity()).toList();
  }

  @override
  Future<int> createCustomer({
    required String fullName,
    required String phoneNumber,
    String? notes,
  }) {
    return _dao.createCustomer(
      CustomersCompanion.insert(
        fullName: fullName,
        phoneNumber: phoneNumber,
        notes: Value(notes),
      ),
    );
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await _dao.updateCustomer(
      CustomerRow(
        id: customer.id,
        fullName: customer.fullName,
        phoneNumber: customer.phoneNumber,
        notes: customer.notes,
        createdAt: customer.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await _dao.deleteCustomer(id);
  }

  @override
  Future<CustomerProfile> getCustomerProfile(int customerId) async {
    final customerRow = await _dao.getCustomerById(customerId);
    if (customerRow == null) {
      throw StateError('العميل غير موجود (id: $customerId)');
    }

    final totalOrders = await _dao.getOrdersCountForCustomer(customerId);
    final totalProfit = await _dao.getTotalProfitForCustomer(customerId);
    final latestOrder = await _dao.getLatestOrderForCustomer(customerId);

    return CustomerProfile(
      customer: customerRow.toEntity(),
      totalOrders: totalOrders,
      totalProfit: totalProfit,
      latestOrderDate: latestOrder?.orderDate,
      latestOrderNumber: latestOrder?.orderNumber,
    );
  }
}
