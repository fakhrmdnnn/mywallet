import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'wallet_repository.dart';

/// Provider singleton untuk koneksi database lokal Drift.
/// Otomatis menutup koneksi saat provider di-dispose.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider untuk mengakses WalletRepository di seluruh fitur aplikasi.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WalletRepository(db);
});

/// Stream provider untuk memantau daftar dompet.
final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepositoryProvider).watchAllWallets();
});

/// Stream provider untuk memantau seluruh dompet beserta saldo terkininya.
final walletsWithBalanceStreamProvider =
    StreamProvider<List<WalletWithBalance>>((ref) {
  return ref.watch(walletRepositoryProvider).watchAllWalletsWithBalance();
});

/// Provider turunan untuk menghitung total gabungan saldo dari seluruh dompet.
final totalBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final walletsAsync = ref.watch(walletsWithBalanceStreamProvider);
  return walletsAsync.whenData(
    (items) => items.fold<int>(0, (sum, item) => sum + item.currentBalance),
  );
});

/// Stream provider untuk memantau daftar kategori.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(walletRepositoryProvider).watchAllCategories();
});

/// Stream provider untuk memantau daftar transaksi terbaru untuk pengelompokan harian.
final recentTransactionsStreamProvider =
    StreamProvider<List<TransactionEntry>>((ref) {
  return ref
      .watch(walletRepositoryProvider)
      .watchRecentTransactions(limit: 200);
});

/// Stream provider untuk memantau total pemasukan dan pengeluaran bulan berjalan.
final currentMonthSummaryStreamProvider =
    StreamProvider<MonthlySummary>((ref) {
  final now = DateTime.now();
  return ref
      .watch(walletRepositoryProvider)
      .watchMonthlySummary(now.year, now.month);
});

/// Stream provider untuk memantau ringkasan laporan hari kemarin secara reaktif.
final yesterdayReportStreamProvider =
    StreamProvider<DailyReportSummary>((ref) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return ref.watch(walletRepositoryProvider).watchDailyReportSummary(yesterday);
});

