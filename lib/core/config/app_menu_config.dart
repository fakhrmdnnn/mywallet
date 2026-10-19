import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Model konfigurasi satu item menu (digunakan pada Grid Fitur Beranda maupun halaman Lainnya).
class AppMenuItemConfig {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color pastelColor;
  final String routePath;
  final List<String> upcomingPoints;
  final bool opensTransferSheet;

  const AppMenuItemConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pastelColor,
    required this.routePath,
    this.upcomingPoints = const [],
    this.opensTransferSheet = false,
  });
}

/// Konfigurasi terpusat untuk menu "Fitur pilihan kamu" di Beranda
/// dan daftar menu di halaman "Lainnya".
/// Memudahkan penambahan atau perubahan nama, ikon, warna pastel, serta rute.
class AppMenuConfig {
  AppMenuConfig._();

  /// 6 item pada Grid "Fitur pilihan kamu" di Beranda.
  static const List<AppMenuItemConfig> homeFeatureItems = [
    AppMenuItemConfig(
      id: 'transfer',
      title: 'Transfer',
      subtitle: 'Pindahkan saldo antar dompet tunai, bank, dan e-wallet.',
      icon: Icons.swap_horiz_rounded,
      pastelColor: AppColors.pastelSky,
      routePath: '/feature/transfer',
      opensTransferSheet: true,
      upcomingPoints: [
        'Transfer cepat antar dompet tanpa memengaruhi total pemasukan/pengeluaran',
        'Riwayat perpindahan saldo lengkap dengan catatan',
      ],
    ),
    AppMenuItemConfig(
      id: 'split-bill',
      title: 'Split Bill',
      subtitle:
          'Hitung patungan makan atau belanja bersama teman secara adil dan praktis.',
      icon: Icons.call_split_rounded,
      pastelColor: AppColors.pastelOrange,
      routePath: '/feature/split-bill',
      upcomingPoints: [
        'Mode bagi rata (equal split) atau per item pesanan',
        'Perhitungan pajak (PPN) dan biaya layanan otomatis',
        'Bagikan rincian tagihan langsung ke WhatsApp',
      ],
    ),
    AppMenuItemConfig(
      id: 'tagihan',
      title: 'Tagihan',
      subtitle:
          'Kelola jadwal tagihan berulang (Planned Payment) agar tidak terlambat bayar.',
      icon: Icons.event_repeat_rounded,
      pastelColor: AppColors.pastelMint,
      routePath: '/feature/tagihan',
      upcomingPoints: [
        'Jadwal tagihan rutin bulanan atau mingguan',
        'Pengingat notifikasi lokal otomatis pada H-3 dan H-1',
        'Konfirmasi pembayaran sekali ketuk ke riwayat transaksi',
      ],
    ),
    AppMenuItemConfig(
      id: 'target-tabungan',
      title: 'Target Tabungan',
      subtitle:
          'Buat target dana impian dan pantau progres tabunganmu secara bertahap.',
      icon: Icons.savings_outlined,
      pastelColor: AppColors.pastelIndigo,
      routePath: '/feature/target-tabungan',
      upcomingPoints: [
        'Target nominal dan tenggat waktu pencapaian tabungan',
        'Simulasi setoran rutin mingguan atau bulanan',
        'Indikator persentase progres dana terkumpul',
      ],
    ),
    AppMenuItemConfig(
      id: 'utang-piutang',
      title: 'Utang & Piutang',
      subtitle:
          'Catat pinjaman dan piutang agar setiap cicilan serta jatuh tempo tercatat jelas.',
      icon: Icons.handshake_outlined,
      pastelColor: AppColors.pastelOrange,
      routePath: '/feature/utang-piutang',
      upcomingPoints: [
        'Pencatatan daftar utang dan piutang beserta nama kontak',
        'Riwayat pembayaran cicilan bertahap hingga lunas',
        'Pengingat tanggal jatuh tempo pelunasan',
      ],
    ),
    AppMenuItemConfig(
      id: 'transaksi-cepat',
      title: 'Transaksi Cepat',
      subtitle:
          'Simpan template transaksi favorit untuk dicatat kembali dalam satu ketukan.',
      icon: Icons.bolt_rounded,
      pastelColor: AppColors.pastelMint,
      routePath: '/feature/transaksi-cepat',
      upcomingPoints: [
        'Template pengeluaran harian (seperti parkir, kopi, atau transport)',
        'Sekali ketuk langsung menambah transaksi tanpa mengetik ulang',
      ],
    ),
  ];

  /// 7 item pada halaman "Lainnya" (menu bottom bar).
  static const List<AppMenuItemConfig> moreMenuItems = [
    AppMenuItemConfig(
      id: 'cari-transaksi',
      title: 'Cari Transaksi',
      subtitle: 'Temukan transaksi berdasarkan kata kunci, kategori, atau rentang tanggal.',
      icon: Icons.search_rounded,
      pastelColor: AppColors.pastelSky,
      routePath: '/more/cari-transaksi',
      upcomingPoints: [
        'Pencarian instan berdasarkan catatan dan nominal',
        'Filter gabungan per dompet, kategori, dan tanggal',
      ],
    ),
    AppMenuItemConfig(
      id: 'laporan-ekspor',
      title: 'Laporan & Ekspor',
      subtitle: 'Unduh rekapitulasi keuangan bulanan dalam format CSV atau PDF.',
      icon: Icons.file_download_outlined,
      pastelColor: AppColors.pastelMint,
      routePath: '/more/laporan-ekspor',
      upcomingPoints: [
        'Ekspor riwayat transaksi ke file CSV / Excel',
        'Ringkasan laporan pemasukan dan pengeluaran siap cetak',
      ],
    ),
    AppMenuItemConfig(
      id: 'kelola-kategori',
      title: 'Kelola Kategori',
      subtitle: 'Tambah, ubah ikon, atau atur warna kategori pemasukan dan pengeluaran.',
      icon: Icons.category_outlined,
      pastelColor: AppColors.pastelIndigo,
      routePath: '/more/kelola-kategori',
      upcomingPoints: [
        'Tambah kategori kustom sesuai kebutuhan pribadi',
        'Pilih ikon dan warna kategori secara bebas',
      ],
    ),
    AppMenuItemConfig(
      id: 'backup-restore',
      title: 'Backup & Restore',
      subtitle: 'Cadangkan database lokal dan pulihkan data saat berganti perangkat.',
      icon: Icons.cloud_sync_outlined,
      pastelColor: AppColors.pastelOrange,
      routePath: '/more/backup-restore',
      upcomingPoints: [
        'Buat file cadangan database lokal secara offline',
        'Pulihkan (restore) data transaksi dan dompet dengan aman',
      ],
    ),
    AppMenuItemConfig(
      id: 'langganan',
      title: 'Langganan',
      subtitle: 'Pantau biaya langganan digital bulanan seperti streaming dan internet.',
      icon: Icons.subscriptions_outlined,
      pastelColor: AppColors.pastelSky,
      routePath: '/more/langganan',
      upcomingPoints: [
        'Daftar layanan berlangganan aktif beserta siklus tagihan',
        'Estimasi total biaya langganan setiap bulan',
      ],
    ),
    AppMenuItemConfig(
      id: 'kalkulator',
      title: 'Kalkulator',
      subtitle: 'Kalkulator finansial cepat untuk menghitung diskon dan simulasi pengeluaran.',
      icon: Icons.calculate_outlined,
      pastelColor: AppColors.pastelMint,
      routePath: '/more/kalkulator',
      upcomingPoints: [
        'Kalkulator cepat terintegrasi langsung dengan form transaksi',
        'Perhitungan diskon belanja dan pembagian biaya',
      ],
    ),
    AppMenuItemConfig(
      id: 'pengaturan',
      title: 'Pengaturan',
      subtitle: 'Atur jadwal notifikasi laporan harian dan preferensi aplikasi.',
      icon: Icons.settings_outlined,
      pastelColor: AppColors.pastelIndigo,
      routePath: '/more/pengaturan',
      upcomingPoints: [
        'Pengaturan jam notifikasi laporan harian setiap pagi',
        'Preferensi profil sapaan dan tampilan aplikasi',
      ],
    ),
  ];

  /// Seluruh item menu yang memiliki rute placeholder tersendiri.
  static List<AppMenuItemConfig> get allRoutableItems => [
        ...homeFeatureItems,
        ...moreMenuItems,
      ];

  /// Mencari konfigurasi menu berdasarkan routePath.
  static AppMenuItemConfig? findByRoute(String routePath) {
    for (final item in allRoutableItems) {
      if (item.routePath == routePath) return item;
    }
    return null;
  }
}
