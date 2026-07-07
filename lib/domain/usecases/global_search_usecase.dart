import '../entities/customer.dart';
import '../entities/order.dart';
import '../entities/product.dart';
import '../repositories/customers_repository.dart';
import '../repositories/orders_repository.dart';
import '../repositories/products_repository.dart';

/// نتيجة موحّدة للبحث الشامل تجمع كل الأنواع المطابقة
class GlobalSearchResults {
  final List<Customer> customers;
  final List<Order> orders;
  final List<Product> products;

  const GlobalSearchResults({
    required this.customers,
    required this.orders,
    required this.products,
  });

  bool get isEmpty => customers.isEmpty && orders.isEmpty && products.isEmpty;
}

/// UseCase: البحث الشامل بحسب:
/// اسم العميل - رقم الهاتف - رقم الطلب - معرف منتج SHEIN
/// (المطلوب في قسم "Search" من مواصفات المشروع)
class GlobalSearchUseCase {
  final CustomersRepository _customersRepository;
  final OrdersRepository _ordersRepository;
  final ProductsRepository _productsRepository;

  const GlobalSearchUseCase(
    this._customersRepository,
    this._ordersRepository,
    this._productsRepository,
  );

  Future<GlobalSearchResults> call(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const GlobalSearchResults(customers: [], orders: [], products: []);
    }

    // ننفّذ عمليات البحث الثلاث بالتوازي لتسريع الاستجابة
    final results = await Future.wait([
      _customersRepository.searchCustomers(trimmed),
      _ordersRepository.getOrders(searchQuery: trimmed),
      _productsRepository.searchBySheinId(trimmed),
    ]);

    return GlobalSearchResults(
      customers: results[0] as List<Customer>,
      orders: results[1] as List<Order>,
      products: results[2] as List<Product>,
    );
  }
}
