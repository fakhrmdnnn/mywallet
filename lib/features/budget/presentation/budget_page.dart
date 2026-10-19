import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_placeholder_view.dart';

/// Halaman Anggaran (Budgeting) MyWallet.
/// Akan menampilkan batas anggaran bulanan per kategori beserta indikator warna.
class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderView(
      title: 'Anggaran',
      stageLabel: 'Menunggu Modul Anggaran',
      subtitle:
          'Belum ada anggaran kategori untuk bulan ini. '
          'Pada tahap budgeting, Anda dapat mengatur batas pengeluaran bulanan per kategori.',
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.warning,
      upcomingPoints: [
        'Target anggaran per kategori setiap bulan',
        'Indikator progres hijau (aman), kuning (hampir penuh), dan merah (melebihi batas)',
        'Sisa anggaran yang masih bisa digunakan',
      ],
    );
  }
}
