import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/wallet_repository.dart';
import '../../../core/services/daily_report_worker.dart';
import '../../../core/services/notification_service.dart';

/// Model konfigurasi laporan harian yang disimpan di SharedPreferences.
class DailyReportSettings {
  final bool enabled;
  final int hour;
  final int minute;
  final bool hasPromptedPermission;

  const DailyReportSettings({
    this.enabled = true,
    this.hour = 7,
    this.minute = 0,
    this.hasPromptedPermission = false,
  });

  DailyReportSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? hasPromptedPermission,
  }) {
    return DailyReportSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      hasPromptedPermission:
          hasPromptedPermission ?? this.hasPromptedPermission,
    );
  }
}

/// Notifier Riverpod untuk membaca dan memperbarui pengaturan laporan harian,
/// serta menjadwalkan ulang tugas background Workmanager setiap kali jam diubah.
class DailyReportSettingsNotifier extends AsyncNotifier<DailyReportSettings> {
  @override
  Future<DailyReportSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyReportSettings(
      enabled: prefs.getBool(DailyReportScheduler.prefEnabledKey) ?? true,
      hour: prefs.getInt(DailyReportScheduler.prefHourKey) ?? 7,
      minute: prefs.getInt(DailyReportScheduler.prefMinuteKey) ?? 0,
      hasPromptedPermission:
          prefs.getBool(DailyReportScheduler.prefPermissionPromptedKey) ??
              false,
    );
  }

  /// Mengaktifkan atau menonaktifkan laporan harian.
  Future<void> toggleEnabled(bool value) async {
    final current = state.value ?? const DailyReportSettings();
    final updated = current.copyWith(enabled: value);
    state = AsyncData(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DailyReportScheduler.prefEnabledKey, value);

    if (value) {
      await NotificationService.instance.requestAndroidPermission();
    }

    await DailyReportScheduler.applySchedule(
      enabled: updated.enabled,
      hour: updated.hour,
      minute: updated.minute,
    );
  }

  /// Mengubah jam pengiriman notifikasi laporan harian dan menjadwalkan ulang Workmanager.
  Future<void> updateTime(int hour, int minute) async {
    final current = state.value ?? const DailyReportSettings();
    final updated = current.copyWith(hour: hour, minute: minute);
    state = AsyncData(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DailyReportScheduler.prefHourKey, hour);
    await prefs.setInt(DailyReportScheduler.prefMinuteKey, minute);

    await DailyReportScheduler.applySchedule(
      enabled: updated.enabled,
      hour: updated.hour,
      minute: updated.minute,
    );
  }

  /// Menandai bahwa dialog penjelasan izin notifikasi sudah ditampilkan saat pertama kali aplikasi dibuka.
  Future<void> markPermissionPrompted() async {
    final current = state.value ?? const DailyReportSettings();
    if (current.hasPromptedPermission) return;

    state = AsyncData(current.copyWith(hasPromptedPermission: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DailyReportScheduler.prefPermissionPromptedKey, true);
  }

  /// Menjalankan tes notifikasi laporan harian saat ini juga dengan membaca database Drift.
  Future<DailyReportSummary> triggerTestNotificationNow() async {
    final repo = ref.read(walletRepositoryProvider);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final summary = await repo.getDailyReportSummary(yesterday);

    await NotificationService.instance.showDailyReportNotification(summary);
    return summary;
  }
}

final dailyReportSettingsProvider =
    AsyncNotifierProvider<DailyReportSettingsNotifier, DailyReportSettings>(
  DailyReportSettingsNotifier.new,
);
