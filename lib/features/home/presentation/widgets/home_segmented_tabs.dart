import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Tab pill tersegmen untuk Beranda: "Ringkasan | Transaksi | Tabungan".
/// Tab aktif menggunakan latar hijau limau (#D9F99D) dengan teks gelap tebal (#0F172A).
class HomeSegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const HomeSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _labels = [
    'Ringkasan',
    'Transaksi',
    'Tabungan',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.activeTabPill : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
