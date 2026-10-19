import 'package:flutter/material.dart';

import '../config/app_menu_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Komponen tampilan halaman placeholder ("Segera hadir") untuk setiap modul fitur.
/// Menampilkan informasi terstruktur mengenai fungsi halaman dengan kotak ikon pastel.
class FeaturePlaceholderView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String stageLabel;
  final IconData icon;
  final Color iconColor;
  final Color? pastelBgColor;
  final List<String> upcomingPoints;
  final Widget? extraContent;

  const FeaturePlaceholderView({
    super.key,
    required this.title,
    required this.subtitle,
    this.stageLabel = 'Segera hadir',
    required this.icon,
    this.iconColor = AppColors.textPrimary,
    this.pastelBgColor,
    this.upcomingPoints = const [],
    this.extraContent,
  });

  /// Membuat halaman placeholder langsung dari konfigurasi menu terpusat.
  factory FeaturePlaceholderView.fromMenuConfig(
    AppMenuItemConfig config, {
    Key? key,
    Widget? extraContent,
  }) {
    return FeaturePlaceholderView(
      key: key,
      title: config.title,
      subtitle: config.subtitle,
      stageLabel: 'Segera hadir',
      icon: config.icon,
      iconColor: AppColors.textPrimary,
      pastelBgColor: config.pastelColor,
      upcomingPoints: config.upcomingPoints,
      extraContent: extraContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boxColor =
        pastelBgColor ?? iconColor.withValues(alpha: 0.14);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding bawah >= 100px agar tidak tertutup tombol "+ Catat" dan bottom bar
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: boxColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(icon, size: 28, color: iconColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.activeTabPill,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      stageLabel,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (upcomingPoints.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Cakupan fitur pada modul ini:',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final point in upcomingPoints)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (extraContent != null) ...[
                    const SizedBox(height: 16),
                    extraContent!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
