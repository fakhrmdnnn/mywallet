import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../database/wallet_repository.dart';
import 'notification_service.dart';

const String dailyReportTaskName = 'mywallet.daily_report_task';
const String dailyReportUniqueName = 'mywallet_daily_report_periodic';

/// Entry-point untuk background isolate Workmanager.
/// Wajib diberi anotasi @pragma('vm:entry-point') agar tidak dihapus saat kompilasi AOT.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (taskName == dailyReportTaskName ||
        taskName == Workmanager.iOSBackgroundTask) {
      await executeDailyReportBackgroundJob();
    }

    return true;
  });
}

/// Membuka database Drift secara mandiri di dalam background isolate,
/// menghitung ringkasan transaksi kemarin, menampilkan notifikasi lokal,
/// lalu menutup koneksi database agar tidak mengunci file SQLite.
Future<void> executeDailyReportBackgroundJob() async {
  await initializeDateFormatting('id_ID', null);

  final db = AppDatabase();
  try {
    final repo = WalletRepository(db);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final summary = await repo.getDailyReportSummary(yesterday);

    await NotificationService.instance.showDailyReportNotification(summary);
  } finally {
    await db.close();
  }
}

/// Pengatur jadwal tugas background harian menggunakan Workmanager.
class DailyReportScheduler {
  DailyReportScheduler._();

  static const String prefEnabledKey = 'daily_report_enabled';
  static const String prefHourKey = 'daily_report_hour';
  static const String prefMinuteKey = 'daily_report_minute';
  static const String prefPermissionPromptedKey =
      'has_prompted_notification_permission';

  static bool _workmanagerInitialized = false;

  /// Menginisialisasi Workmanager dan menerapkan jadwal awal jika belum ada.
  static Future<void> initializeAndEnsureScheduled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      if (!_workmanagerInitialized) {
        await Workmanager().initialize(callbackDispatcher);
        _workmanagerInitialized = true;
      }

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(prefEnabledKey) ?? true;
      final hour = prefs.getInt(prefHourKey) ?? 7;
      final minute = prefs.getInt(prefMinuteKey) ?? 0;

      await applySchedule(enabled: enabled, hour: hour, minute: minute);
    } catch (_) {}
  }

  /// Menghitung selisih waktu dari `now` menuju jam:menit berikutnya.
  static Duration computeInitialDelay(
    DateTime now, {
    required int targetHour,
    required int targetMinute,
  }) {
    var nextRun = DateTime(
      now.year,
      now.month,
      now.day,
      targetHour,
      targetMinute,
    );
    if (!nextRun.isAfter(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    return nextRun.difference(now);
  }

  /// Menjadwalkan ulang atau membatalkan periodic task Workmanager sesuai pengaturan pengguna.
  static Future<void> applySchedule({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      if (!_workmanagerInitialized) {
        await Workmanager().initialize(callbackDispatcher);
        _workmanagerInitialized = true;
      }

      if (!enabled) {
        await Workmanager().cancelByUniqueName(dailyReportUniqueName);
        return;
      }

      final initialDelay = computeInitialDelay(
        DateTime.now(),
        targetHour: hour,
        targetMinute: minute,
      );

      await Workmanager().registerPeriodicTask(
        dailyReportUniqueName,
        dailyReportTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (_) {}
  }
}
