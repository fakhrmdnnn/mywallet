import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_menu_config.dart';
import '../core/widgets/feature_placeholder_view.dart';
import '../features/budget/presentation/budget_page.dart';
import '../features/categories/presentation/manage_categories_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/more/presentation/more_page.dart';
import '../features/stats/presentation/stats_page.dart';
import 'app_shell.dart';

/// Provider GoRouter agar konfigurasi rute terintegrasi dengan state Riverpod.
/// Menggunakan StatefulShellRoute.indexedStack supaya state tiap tab terjaga
/// saat pengguna berpindah menu di bottom bar, serta mendaftarkan seluruh rute
/// menu dari `AppMenuConfig`.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                name: 'stats',
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                name: 'budget',
                builder: (context, state) => const BudgetPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                name: 'more',
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),

      // Rute dinamis untuk seluruh menu di Grid Beranda dan halaman Lainnya
      for (final item in AppMenuConfig.allRoutableItems)
        GoRoute(
          path: item.routePath,
          name: item.id,
          builder: (context, state) {
            if (item.id == 'kelola-kategori') {
              return const ManageCategoriesPage();
            }
            return FeaturePlaceholderView.fromMenuConfig(item);
          },
        ),
    ],
  );
});
