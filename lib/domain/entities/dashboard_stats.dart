/// كيان إحصائيات الداشبورد الرئيسية
class DashboardStats {
  final int totalCustomers;
  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final int waitingOrders; // الطلبات بحالة "جديد" أو "تم الطلب" (لم تُشحن بعد)
  final double totalPurchaseAmount;
  final double totalSellingAmount;
  final double totalProfit;

  const DashboardStats({
    required this.totalCustomers,
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.waitingOrders,
    required this.totalPurchaseAmount,
    required this.totalSellingAmount,
    required this.totalProfit,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalCustomers: 0,
        totalOrders: 0,
        activeOrders: 0,
        deliveredOrders: 0,
        waitingOrders: 0,
        totalPurchaseAmount: 0,
        totalSellingAmount: 0,
        totalProfit: 0,
      );
}

/// نتيجة موحّدة للبحث الشامل (يجمع عملاء + طلبات لأن كل نوع له شاشة مختلفة)
class GlobalSearchResult {
  final List<int> matchingCustomerIds;
  final List<int> matchingOrderIds;

  const GlobalSearchResult({
    required this.matchingCustomerIds,
    required this.matchingOrderIds,
  });

  bool get isEmpty => matchingCustomerIds.isEmpty && matchingOrderIds.isEmpty;
}
