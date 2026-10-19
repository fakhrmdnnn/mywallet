import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/daily_report_settings_provider.dart';
import '../features/transactions/presentation/add_transaction_sheet.dart';

/// Kerangka navigasi utama dengan:
/// - Bottom bar putih berbayangan lembut berisi 4 menu (Beranda, Statistik, Anggaran, Lainnya).
/// - Tombol melayang berbentuk PILL gelap (#0F172A) berisi ikon "+" dan teks "Catat"
///   yang mengambang di tengah atas bottom bar (tanpa notch).
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<String>? _notificationTapSub;
  bool _permissionDialogChecked = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationHandling();
  }

  Future<void> _setupNotificationHandling() async {
    _notificationTapSub =
        NotificationService.instance.onNotificationTap.listen(_handlePayload);

    final launchPayload = await NotificationService.instance.getLaunchPayload();
    if (launchPayload != null && mounted) {
      _handlePayload(launchPayload);
    }
  }

  void _handlePayload(String payload) {
    if (!mounted) return;
    if (payload == NotificationService.dailyReportPayload) {
      widget.navigationShell.goBranch(1);
    }
  }

  void _maybePromptNotificationPermission(
    DailyReportSettings settings,
  ) {
    if (_permissionDialogChecked) return;
    _permissionDialogChecked = true;

    if (settings.hasPromptedPermission) return;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showPermissionRationaleDialog();
    });
  }

  Future<void> _showPermissionRationaleDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Izinkan Notifikasi Harian',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'MyWallet memerlukan izin notifikasi untuk mengirimkan ringkasan '
          'laporan keuangan hari sebelumnya setiap pagi (jam 07:00) serta '
          'pengingat tagihan berulang.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Nanti',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );

    await ref
        .read(dailyReportSettingsProvider.notifier)
        .markPermissionPrompted();

    if (shouldRequest == true) {
      await NotificationService.instance.requestAndroidPermission();
    }
  }

  @override
  void dispose() {
    _notificationTapSub?.cancel();
    super.dispose();
  }

  void _onSelectTab(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<DailyReportSettings>>(
      dailyReportSettingsProvider,
      (_, next) {
        if (next.hasValue) {
          _maybePromptNotificationPermission(next.value!);
        }
      },
    );

    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(child: widget.navigationShell),

          // Tombol melayang berbentuk PILL gelap (#0F172A) di tengah bawah, mengambang di atas bottom bar
          Positioned(
            bottom: 14,
            child: Semantics(
              button: true,
              label: 'Catat transaksi baru',
              child: Tooltip(
                message: 'Catat Transaksi',
                child: Material(
                  color: AppColors.floatingPill,
                  shape: const StadiumBorder(),
                  elevation: 6,
                  shadowColor: AppColors.floatingPill.withValues(alpha: 0.35),
                  child: InkWell(
                    onTap: () => AddTransactionSheet.show(context),
                    customBorder: const StadiumBorder(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Catat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTheme.softShadow,
          border: const Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    selected: currentIndex == 0,
                    onTap: () => _onSelectTab(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Statistik',
                    selected: currentIndex == 1,
                    onTap: () => _onSelectTab(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    label: 'Anggaran',
                    selected: currentIndex == 2,
                    onTap: () => _onSelectTab(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Lainnya',
                    selected: currentIndex == 3,
                    onTap: () => _onSelectTab(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item navigasi bawah dengan ikon outline (aktif berwarna primary + label).
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: color,
                size: 23,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
