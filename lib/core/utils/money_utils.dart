/// أدوات مساعدة للحسابات المالية
/// نستخدم تقريب لخانتين عشريتين دائمًا لتفادي أخطاء الفاصلة العائمة
/// (مثال: 19.99 * 3 قد تعطي 59.970000000000006 بدون تقريب)
class MoneyUtils {
  const MoneyUtils._();

  static double round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static double calcSubtotal({required double unitPrice, required int quantity}) {
    return round2(unitPrice * quantity);
  }

  static double calcProfit({required double sellingTotal, required double purchaseTotal}) {
    return round2(sellingTotal - purchaseTotal);
  }
}
