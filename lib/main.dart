import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'core/services/daily_report_worker.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi data format tanggal Bahasa Indonesia (id_ID) untuk package intl.
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi layanan notifikasi lokal dan penjadwal background Workmanager.
  await NotificationService.instance.initialize();
  await DailyReportScheduler.initializeAndEnsureScheduled();

  // ProviderScope wajib membungkus root widget agar seluruh provider Riverpod dapat diakses.
  runApp(
    const ProviderScope(
      child: MyWalletApp(),
    ),
  );
}

/// Root widget aplikasi MyWallet yang menghubungkan tema terang (Light Theme) dan GoRouter.
class MyWalletApp extends ConsumerWidget {
  const MyWalletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MyWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
