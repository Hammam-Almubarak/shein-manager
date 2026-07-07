import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';
import '../../data/repositories/customers_repository_impl.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/repositories/customers_repository.dart';
import '../../domain/repositories/products_repository.dart';
import '../../domain/repositories/orders_repository.dart';

/// نربط هنا الواجهة المجردة (Interface) بالتنفيذ الفعلي (Impl)
/// بقية التطبيق (UseCases, UI) يعتمد فقط على النوع المجرد CustomersRepository،
/// وليس CustomersRepositoryImpl - هذا هو مبدأ Dependency Inversion في SOLID.
final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepositoryImpl(ref.watch(customersDaoProvider));
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(ref.watch(productsDaoProvider));
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    ref.watch(ordersDaoProvider),
    ref.watch(orderItemsDaoProvider),
    ref.watch(customersDaoProvider),
    ref.watch(productsDaoProvider),
  );
});
