import '../../core/constants/order_status.dart';
import 'customer.dart';
import 'order_item.dart';

/// كيان الطلب - العنصر المركزي في التطبيق
/// يحتوي إجماليات جاهزة (purchaseTotal/sellingTotal/profitTotal) محسوبة
/// مسبقًا من طبقة البيانات (OrderItemsDao._recalculateOrderTotals)
class Order {
  final int id;
  final String orderNumber;
  final Customer customer;
  final DateTime orderDate;
  final DateTime? expectedArrivalDate;
  final DateTime? arrivalDate;
  final OrderStatus status;
  final double purchaseTotal;
  final double sellingTotal;
  final double profitTotal;
  final String? notes;

  /// عناصر الطلب - قد تكون فارغة إذا لم تُحمَّل بعد (Lazy loading اختياري)
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.orderDate,
    this.expectedArrivalDate,
    this.arrivalDate,
    required this.status,
    required this.purchaseTotal,
    required this.sellingTotal,
    required this.profitTotal,
    this.notes,
    this.items = const [],
  });

  /// عدد المنتجات (الأصناف) ضمن الطلب - يُستخدم في بطاقة الطلب بشاشة الطلبات
  int get itemsCount => items.length;

  Order copyWith({
    OrderStatus? status,
    DateTime? arrivalDate,
    List<OrderItem>? items,
    double? purchaseTotal,
    double? sellingTotal,
    double? profitTotal,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      customer: customer,
      orderDate: orderDate,
      expectedArrivalDate: expectedArrivalDate,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      status: status ?? this.status,
      purchaseTotal: purchaseTotal ?? this.purchaseTotal,
      sellingTotal: sellingTotal ?? this.sellingTotal,
      profitTotal: profitTotal ?? this.profitTotal,
      notes: notes,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Order && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
