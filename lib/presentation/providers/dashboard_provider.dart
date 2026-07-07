import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'usecase_providers.dart';
import '../../domain/entities/dashboard_stats.dart';

/// إحصائيات الداشبورد الرئيسية
/// استخدم ref.invalidate(dashboardStatsProvider) بعد أي عملية تعديل بيانات
/// (إنشاء طلب، تعديل حالة، إضافة عنصر...) لإعادة حساب الأرقام فورًا
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(getDashboardStatsUseCaseProvider)();
});
