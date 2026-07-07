/// حالات الطلب الممكنة
enum OrderStatus {
  newOrder, // جديد
  ordered, // تم الطلب من SHEIN
  shipped, // تم الشحن
  arrived, // وصل
  delivered, // تم التسليم للزبون
  cancelled; // ملغى

  /// الاسم المعروض بالعربية
  String get labelAr {
    switch (this) {
      case OrderStatus.newOrder:
        return 'جديد';
      case OrderStatus.ordered:
        return 'تم الطلب';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.arrived:
        return 'وصل';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغى';
    }
  }

  static OrderStatus fromIndex(int index) => OrderStatus.values[index];
}
