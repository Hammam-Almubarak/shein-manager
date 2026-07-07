import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/add_order_item_usecase.dart';
import '../../domain/usecases/update_order_item_usecase.dart';
import '../../domain/usecases/delete_order_item_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/global_search_usecase.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/update_order_notes_usecase.dart';
import '../../domain/usecases/create_product_usecase.dart';

// ---- الطلبات ----

final createOrderUseCaseProvider = Provider<CreateOrderUseCase>((ref) {
  return CreateOrderUseCase(ref.watch(ordersRepositoryProvider));
});

final addOrderItemUseCaseProvider = Provider<AddOrderItemUseCase>((ref) {
  return AddOrderItemUseCase(ref.watch(ordersRepositoryProvider));
});

final updateOrderItemUseCaseProvider = Provider<UpdateOrderItemUseCase>((ref) {
  return UpdateOrderItemUseCase(ref.watch(ordersRepositoryProvider));
});

final deleteOrderItemUseCaseProvider = Provider<DeleteOrderItemUseCase>((ref) {
  return DeleteOrderItemUseCase(ref.watch(ordersRepositoryProvider));
});

final updateOrderStatusUseCaseProvider =
    Provider<UpdateOrderStatusUseCase>((ref) {
  return UpdateOrderStatusUseCase(ref.watch(ordersRepositoryProvider));
});

final updateOrderNotesUseCaseProvider =
    Provider<UpdateOrderNotesUseCase>((ref) {
  return UpdateOrderNotesUseCase(ref.watch(ordersRepositoryProvider));
});

final deleteOrderUseCaseProvider = Provider<DeleteOrderUseCase>((ref) {
  return DeleteOrderUseCase(ref.watch(ordersRepositoryProvider));
});

// ---- العملاء ----

final createCustomerUseCaseProvider = Provider<CreateCustomerUseCase>((ref) {
  return CreateCustomerUseCase(ref.watch(customersRepositoryProvider));
});

final updateCustomerUseCaseProvider = Provider<UpdateCustomerUseCase>((ref) {
  return UpdateCustomerUseCase(ref.watch(customersRepositoryProvider));
});

final deleteCustomerUseCaseProvider = Provider<DeleteCustomerUseCase>((ref) {
  return DeleteCustomerUseCase(ref.watch(customersRepositoryProvider));
});

// ---- المنتجات ----

final createProductUseCaseProvider = Provider<CreateProductUseCase>((ref) {
  return CreateProductUseCase(ref.watch(productsRepositoryProvider));
});

// ---- الداشبورد ----

final getDashboardStatsUseCaseProvider =
    Provider<GetDashboardStatsUseCase>((ref) {
  return GetDashboardStatsUseCase(ref.watch(ordersRepositoryProvider));
});

// ---- البحث الشامل ----

final globalSearchUseCaseProvider = Provider<GlobalSearchUseCase>((ref) {
  return GlobalSearchUseCase(
    ref.watch(customersRepositoryProvider),
    ref.watch(ordersRepositoryProvider),
    ref.watch(productsRepositoryProvider),
  );
});
