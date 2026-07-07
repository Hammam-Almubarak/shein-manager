import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/order_items_table.dart';
import '../tables/orders_table.dart';
import '../../../core/utils/money_utils.dart';

part 'order_items_dao.g.dart';

/// DAO خاص بعناصر الطلب
/// المسؤولية الأهم هنا: أي إضافة/تعديل/حذف لعنصر طلب يجب أن:
///   1) يحسب purchaseSubtotal / sellingSubtotal / profitSubtotal تلقائيًا
///   2) يعيد حساب إجماليات الطلب الأب (Orders.purchaseTotal/sellingTotal/profitTotal)
/// كل شي يتم داخل transaction واحدة لضمان تناسق البيانات.
@DriftAccessor(tables: [OrderItems, Orders])
class OrderItemsDao extends DatabaseAccessor<AppDatabase>
    with _$OrderItemsDaoMixin {
  OrderItemsDao(super.db);

  Stream<List<OrderItemRow>> watchItemsForOrder(int orderId) {
    return (select(orderItems)..where((t) => t.orderId.equals(orderId)))
        .watch();
  }

  Future<List<OrderItemRow>> getItemsForOrder(int orderId) {
    return (select(orderItems)..where((t) => t.orderId.equals(orderId))).get();
  }

  /// عدد الأصناف (المنتجات) ضمن طلب معيّن - أسرع من جلب كل الصفوف
  Future<int> getItemsCountForOrder(int orderId) async {
    final countExp = orderItems.id.count();
    final query = selectOnly(orderItems)
      ..addColumns([countExp])
      ..where(orderItems.orderId.equals(orderId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// إضافة عنصر طلب جديد - يحسب الـ subtotals تلقائيًا ثم يحدّث إجماليات الطلب
  Future<int> addItem({
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  }) async {
    return transaction(() async {
      final purchaseSubtotal =
          MoneyUtils.calcSubtotal(unitPrice: purchasePrice, quantity: quantity);
      final sellingSubtotal =
          MoneyUtils.calcSubtotal(unitPrice: sellingPrice, quantity: quantity);
      final profitSubtotal = MoneyUtils.calcProfit(
        sellingTotal: sellingSubtotal,
        purchaseTotal: purchaseSubtotal,
      );

      final newId = await into(orderItems).insert(
        OrderItemsCompanion.insert(
          orderId: orderId,
          productId: productId,
          quantity: Value(quantity),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          purchaseSubtotal: Value(purchaseSubtotal),
          sellingSubtotal: Value(sellingSubtotal),
          profitSubtotal: Value(profitSubtotal),
        ),
      );

      await _recalculateOrderTotals(orderId);
      return newId;
    });
  }

  /// تعديل عنصر طلب موجود - يعيد حساب كل شي تلقائيًا
  Future<void> updateItem({
    required int itemId,
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  }) async {
    return transaction(() async {
      final purchaseSubtotal =
          MoneyUtils.calcSubtotal(unitPrice: purchasePrice, quantity: quantity);
      final sellingSubtotal =
          MoneyUtils.calcSubtotal(unitPrice: sellingPrice, quantity: quantity);
      final profitSubtotal = MoneyUtils.calcProfit(
        sellingTotal: sellingSubtotal,
        purchaseTotal: purchaseSubtotal,
      );

      await (update(orderItems)..where((t) => t.id.equals(itemId))).write(
        OrderItemsCompanion(
          productId: Value(productId),
          quantity: Value(quantity),
          purchasePrice: Value(purchasePrice),
          sellingPrice: Value(sellingPrice),
          purchaseSubtotal: Value(purchaseSubtotal),
          sellingSubtotal: Value(sellingSubtotal),
          profitSubtotal: Value(profitSubtotal),
        ),
      );

      await _recalculateOrderTotals(orderId);
    });
  }

  /// حذف عنصر طلب - يعيد حساب إجماليات الطلب الأب بعد الحذف
  Future<void> deleteItem({required int itemId, required int orderId}) async {
    return transaction(() async {
      await (delete(orderItems)..where((t) => t.id.equals(itemId))).go();
      await _recalculateOrderTotals(orderId);
    });
  }

  /// المنطق المركزي: إعادة حساب إجماليات الطلب من مجموع عناصره
  /// هذه الدالة هي "مصدر الحقيقة الوحيد" لإجماليات الطلب - لا يجوز
  /// تعديل purchaseTotal/sellingTotal/profitTotal يدويًا من أي مكان آخر بالتطبيق.
  Future<void> _recalculateOrderTotals(int orderId) async {
    final purchaseSumExp = orderItems.purchaseSubtotal.sum();
    final sellingSumExp = orderItems.sellingSubtotal.sum();

    final query = selectOnly(orderItems)
      ..addColumns([purchaseSumExp, sellingSumExp])
      ..where(orderItems.orderId.equals(orderId));

    final result = await query.getSingle();
    final purchaseTotal = result.read(purchaseSumExp) ?? 0.0;
    final sellingTotal = result.read(sellingSumExp) ?? 0.0;
    final profitTotal = MoneyUtils.calcProfit(
      sellingTotal: sellingTotal,
      purchaseTotal: purchaseTotal,
    );

    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        purchaseTotal: Value(MoneyUtils.round2(purchaseTotal)),
        sellingTotal: Value(MoneyUtils.round2(sellingTotal)),
        profitTotal: Value(profitTotal),
      ),
    );
  }
}
