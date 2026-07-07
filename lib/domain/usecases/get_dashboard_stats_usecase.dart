import '../entities/dashboard_stats.dart';
import '../repositories/orders_repository.dart';

/// UseCase: جلب كل إحصائيات الداشبورد الرئيسية دفعة واحدة
class GetDashboardStatsUseCase {
  final OrdersRepository _ordersRepository;

  const GetDashboardStatsUseCase(this._ordersRepository);

  Future<DashboardStats> call() {
    return _ordersRepository.getDashboardStats();
  }
}
