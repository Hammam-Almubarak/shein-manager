import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import '../../domain/entities/customer.dart';

/// قائمة العملاء الحية - تتحدث تلقائيًا عند أي إضافة/تعديل/حذف
final customersListProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).watchAllCustomers();
});

/// نص البحث الحالي في شاشة العملاء (يُحدَّث من حقل البحث بالواجهة)
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// نتيجة البحث المفلترة - مبنية فوق customersListProvider مباشرة
/// (بحث محلي فوري بدون ضرب قاعدة البيانات في كل حرف يُكتب)
final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();
  final customersAsync = ref.watch(customersListProvider);

  return customersAsync.whenData((customers) {
    if (query.isEmpty) return customers;
    return customers
        .where((c) =>
            c.fullName.toLowerCase().contains(query) ||
            c.phoneNumber.contains(query))
        .toList();
  });
});

/// بروفايل عميل معيّن (عدد الطلبات + الربح الكلي + آخر طلب)
final customerProfileProvider =
    FutureProvider.family<CustomerProfile, int>((ref, customerId) {
  return ref.watch(customersRepositoryProvider).getCustomerProfile(customerId);
});
