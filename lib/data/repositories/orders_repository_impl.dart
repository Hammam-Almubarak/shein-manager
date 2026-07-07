import '../database/daos/orders_dao.dart';
import '../database/daos/order_items_dao.dart';
import '../database/daos/customers_dao.dart';
import '../database/daos/products_dao.dart';
import '../database/app_database.dart' show OrderRow;
import '../mappers/customer_mapper.dart';
import '../mappers/product_mapper.dart';
import '../mappers/order_mapper.dart';
import '../mappers/order_item_mapper.dart';
import '../../core/constants/order_status.dart';
import '../../core/constants/orders_sort_by.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/orders_repository.dart';

/// التنفيذ الفعلي لعقد OrdersRepository
/// هذا المستودع هو "المنسّق" (Coordinator) بين 4 جداول: Orders, OrderItems,
/// Customers, Products - لأن كيان Order بطبقة الـ Domain يحتاج بيانات من الكل معًا.
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDao _ordersDao;
  final OrderItemsDao _orderItemsDao;
  final CustomersDao _customersDao;
  final ProductsDao _productsDao;

  const OrdersRepositoryImpl(
    this._ordersDao,
    this._orderItemsDao,
    this._customersDao,
    this._productsDao,
  );

  /// يبني كيان Order كامل من صف قاعدة بيانات واحد، بجلب العميل والعناصر
  /// (وكل منتج لكل عنصر) - نقطة التجميع المركزية لكل الاستعلامات
  Future<Order> _hydrateOrder(OrderRow row) async {
    final customerRow = await _customersDao.getCustomerById(row.customerId);
    if (customerRow == null) {
      throw StateError('العميل المرتبط بالطلب ${row.orderNumber} غير موجود');
    }

    final itemRows = await _orderItemsDao.getItemsForOrder(row.id);
    final items = <OrderItem>[];
    for (final itemRow in itemRows) {
      final productRow = await _productsDao.getProductById(itemRow.productId);
      if (productRow == null) continue; // بيانات غير متسقة - يُتجاهل بأمان
      items.add(itemRow.toEntity(productRow.toEntity()));
    }

    return row.toEntity(customer: customerRow.toEntity(), items: items);
  }

  @override
  Future<List<Order>> getOrders({
    String? searchQuery,
    OrderStatus? statusFilter,
    OrdersSortBy sortBy = OrdersSortBy.dateDesc,
  }) async {
    final rows = await _ordersDao.getOrders(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      sortBy: sortBy,
    );
    final orders = <Order>[];
    for (final row in rows) {
      orders.add(await _hydrateOrder(row));
    }
    return orders;
  }

  @override
  Stream<List<Order>> watchRecentOrders({int limit = 5}) {
    return _ordersDao.watchRecentOrders(limit: limit).asyncMap((rows) async {
      final orders = <Order>[];
      for (final row in rows) {
        orders.add(await _hydrateOrder(row));
      }
      return orders;
    });
  }

  @override
  Future<Order?> getOrderById(int id) async {
    final row = await _ordersDao.getOrderById(id);
    if (row == null) return null;
    return _hydrateOrder(row);
  }

  @override
  Future<int> createOrder({
    required int customerId,
    DateTime? expectedArrivalDate,
    String? notes,
  }) {
    return _ordersDao.createOrder(
      customerId: customerId,
      expectedArrivalDate: expectedArrivalDate,
      notes: notes,
    );
  }

  @override
  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    await _ordersDao.updateOrderStatus(orderId, status);
  }

  @override
  Future<void> updateOrderNotes({
    required int orderId,
    String? notes,
    DateTime? expectedArrivalDate,
  }) async {
    await _ordersDao.updateOrderNotes(
      orderId: orderId,
      notes: notes,
      expectedArrivalDate: expectedArrivalDate,
    );
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    await _ordersDao.deleteOrder(orderId);
  }

  // ---- عناصر الطلب ----

  @override
  Stream<List<OrderItem>> watchItemsForOrder(int orderId) {
    return _orderItemsDao.watchItemsForOrder(orderId).asyncMap((rows) async {
      final items = <OrderItem>[];
      for (final row in rows) {
        final productRow = await _productsDao.getProductById(row.productId);
        if (productRow == null) continue;
        items.add(row.toEntity(productRow.toEntity()));
      }
      return items;
    });
  }

  @override
  Future<int> addOrderItem({
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  }) {
    return _orderItemsDao.addItem(
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );
  }

  @override
  Future<void> updateOrderItem({
    required int itemId,
    required int orderId,
    required int productId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
  }) {
    return _orderItemsDao.updateItem(
      itemId: itemId,
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );
  }

  @override
  Future<void> deleteOrderItem({required int itemId, required int orderId}) {
    return _orderItemsDao.deleteItem(itemId: itemId, orderId: orderId);
  }

  // ---- الداشبورد ----

  @override
  Future<DashboardStats> getDashboardStats() async {
    // ننفّذ كل الاستعلامات بالتوازي لتسريع تحميل الداشبورد
    final results = await Future.wait([
      _customersDao.getTotalCustomersCount(),
      _ordersDao.countAllOrders(),
      _ordersDao.countActiveOrders(),
      _ordersDao.countByStatus(OrderStatus.delivered),
      _ordersDao.countByStatus(OrderStatus.newOrder),
      _ordersDao.countByStatus(OrderStatus.ordered),
      _ordersDao.sumPurchaseTotal(),
      _ordersDao.sumSellingTotal(),
      _ordersDao.sumProfitTotal(),
    ]);

    final waitingOrders = (results[4] as int) + (results[5] as int);

    return DashboardStats(
      totalCustomers: results[0] as int,
      totalOrders: results[1] as int,
      activeOrders: results[2] as int,
      deliveredOrders: results[3] as int,
      waitingOrders: waitingOrders,
      totalPurchaseAmount: results[6] as double,
      totalSellingAmount: results[7] as double,
      totalProfit: results[8] as double,
    );
  }
}
