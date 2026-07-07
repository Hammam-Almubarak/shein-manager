import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import '../../domain/entities/product.dart';

final productsListProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).getAllProducts();
});

final productSearchBySheinIdProvider =
    FutureProvider.family<List<Product>, String>((ref, sheinProductId) {
  return ref
      .watch(productsRepositoryProvider)
      .searchBySheinId(sheinProductId);
});
