/// كيان العميل في طبقة الـ Domain (مستقل تمامًا عن Drift/قاعدة البيانات)
/// هذا هو الشكل الذي تتعامل معه واجهات المستخدم وUseCases
class Customer {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.notes,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// ملخص بروفايل العميل الكامل (يُستخدم في شاشة تفاصيل العميل)
class CustomerProfile {
  final Customer customer;
  final int totalOrders;
  final double totalProfit;
  final DateTime? latestOrderDate;
  final String? latestOrderNumber;

  const CustomerProfile({
    required this.customer,
    required this.totalOrders,
    required this.totalProfit,
    this.latestOrderDate,
    this.latestOrderNumber,
  });
}
