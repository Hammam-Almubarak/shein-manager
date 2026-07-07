import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/customer.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/customers/customers_list_screen.dart';
import '../../presentation/screens/customers/customer_form_screen.dart';
import '../../presentation/screens/customers/customer_profile_screen.dart';
import '../../presentation/screens/orders/orders_list_screen.dart';
import '../../presentation/screens/orders/order_form_screen.dart';
import '../../presentation/screens/orders/order_details_screen.dart';
import '../../presentation/screens/statistics/statistics_screen.dart';
import '../../presentation/screens/backup/backup_screen.dart';
import '../../presentation/screens/search/global_search_screen.dart';

/// هيكل التنقل الكامل للتطبيق باستخدام go_router
/// الشاشات الرئيسية الأربع محاطة بـ ScaffoldWithNavBar الذي يعرض
/// شريط التنقل السفلي (Bottom NavigationBar)
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // ---- الشاشات ذات شريط التنقل السفلي ----
    ShellRoute(
      builder: (context, state, child) =>
          ScaffoldWithNavBar(child: child),
      routes: [
        // الداشبورد
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),

        // العملاء
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CustomersListScreen(),
          ),
        ),

        // الطلبات
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrdersListScreen(),
          ),
        ),

        // الإحصائيات
        GoRoute(
          path: '/statistics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
      ],
    ),

    // ---- شاشات بدون شريط التنقل (تُدفع فوق الشاشة الحالية) ----

    GoRoute(
      path: '/customers/new',
      builder: (context, state) => const CustomerFormScreen(),
    ),

    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return _buildErrorPage('معرّف العميل غير صالح');
        return CustomerProfileScreen(customerId: id);
      },
    ),

    GoRoute(
      path: '/customers/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return _buildErrorPage('معرّف العميل غير صالح');
        // extra يحمل Customer entity لو مرّرناه، وإلا يحمّل الشاشة بـ id فقط
        final customer = state.extra is Customer ? state.extra as Customer : null;
        return CustomerFormScreen(customerId: id, initialCustomer: customer);
      },
    ),

    GoRoute(
      path: '/orders/new',
      builder: (context, state) {
        final customerId = state.extra is int ? state.extra as int : null;
        return OrderFormScreen(preselectedCustomerId: customerId);
      },
    ),

    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return _buildErrorPage('معرّف الطلب غير صالح');
        return OrderDetailsScreen(orderId: id);
      },
    ),

    GoRoute(
      path: '/search',
      builder: (context, state) => const GlobalSearchScreen(),
    ),

    GoRoute(
      path: '/backup',
      builder: (context, state) => const BackupScreen(),
    ),
  ],
);

/// صفحة خطأ بسيطة تُعرض عند مسار غير صالح
Widget _buildErrorPage(String message) {
  return Scaffold(
    appBar: AppBar(title: const Text('خطأ')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
}

// ---- شريط التنقل السفلي ----

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  static const _tabs = [
    _NavItem(path: '/', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'الرئيسية'),
    _NavItem(path: '/customers', icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'العملاء'),
    _NavItem(path: '/orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'الطلبات'),
    _NavItem(path: '/statistics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'الإحصائيات'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path ||
          (i > 0 && location.startsWith(_tabs[i].path))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (i != selectedIndex) {
            context.go(_tabs[i].path);
          }
        },
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
