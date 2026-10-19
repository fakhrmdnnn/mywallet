import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/wallet_repository.dart';

/// Layanan terpusat untuk mengelola notifikasi lokal (Laporan Harian & Pengingat Tagihan).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int dailyReportNotificationId = 1001;
  static const String dailyReportPayload = 'daily_report';
  static const String _dailyChannelId = 'mywallet_daily_report_channel';
  static const String _dailyChannelName = 'Laporan Harian MyWallet';
  static const String _dailyChannelDesc =
      'Ringkasan pengeluaran dan pemasukan hari sebelumnya setiap pagi.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _tapPayloadController =
      StreamController<String>.broadcast();

  bool _initialized = false;

  /// Stream payload saat pengguna mengetuk notifikasi di status bar.
  Stream<String> get onNotificationTap => _tapPayloadController.stream;

  /// Inisialisasi plugin notifikasi lokal. Aman dipanggil di main isolate maupun background isolate.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Buka MyWallet',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'MyWallet',
      appUserModelId: 'com.example.mywallet',
      guid: '81a30d68-6e9c-4812-ab98-4641f1c41b27',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _tapPayloadController.add(payload);
          }
        },
      );
      _initialized = true;
    } catch (_) {
      // Pada lingkungan unit/widget test tanpa platform channel, abaikan kegagalan inisialisasi.
    }
  }

  /// Memeriksa apakah aplikasi diluncurkan dari ketukan notifikasi saat aplikasi tertutup.
  Future<String?> getLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse?.payload;
      }
    } catch (_) {}
    return null;
  }

  /// Meminta izin POST_NOTIFICATIONS pada Android 13+ (API 33+).
  Future<bool> requestAndroidPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      await initialize();
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Menampilkan notifikasi lokal berisi ringkasan laporan keuangan harian.
  Future<void> showDailyReportNotification(DailyReportSummary summary) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      _dailyChannelId,
      _dailyChannelName,
      channelDescription: _dailyChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(summary.notificationBody),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id: dailyReportNotificationId,
        title: summary.notificationTitle,
        body: summary.notificationBody,
        notificationDetails: details,
        payload: dailyReportPayload,
      );
    } catch (_) {
      // Abaikan jika dijalankan di lingkungan pengujian tanpa plugin native.
    }
  }
}
