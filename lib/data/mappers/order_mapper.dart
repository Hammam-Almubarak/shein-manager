import '../database/app_database.dart' show OrderRow;
import '../../core/constants/order_status.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

extension OrderRowMapper on OrderRow {
  /// يتطلب كيان العميل جاهزًا، وقائمة عناصر (اختيارية - فارغة افتراضيًا لقوائم العرض السريع)
  Order toEntity({required Customer customer, List<OrderItem> items = const []}) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      customer: customer,
      orderDate: orderDate,
      expectedArrivalDate: expectedArrivalDate,
      arrivalDate: arrivalDate,
      status: OrderStatus.fromIndex(status),
      purchaseTotal: purchaseTotal,
      sellingTotal: sellingTotal,
      profitTotal: profitTotal,
      notes: notes,
      items: items,
    );
  }
}
