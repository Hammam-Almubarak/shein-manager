import 'product.dart';

/// كيان عنصر الطلب - مرتبط بمنتج واحد ضمن طلب معيّن
/// كل الحقول المالية (subtotal/profit) هي نتيجة حساب تلقائي في الطبقة الأدنى
/// (OrderItemsDao) ولا يجوز حسابها أو تعديلها يدويًا هنا.
class OrderItem {
  final int id;
  final int orderId;
  final Product product;
  final int quantity;
  final double purchasePrice; // سعر الشراء من SHEIN للوحدة
  final double sellingPrice; // سعر البيع للزبون للوحدة
  final double purchaseSubtotal;
  final double sellingSubtotal;
  final double profitSubtotal;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.product,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.purchaseSubtotal,
    required this.sellingSubtotal,
    required this.profitSubtotal,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OrderItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
