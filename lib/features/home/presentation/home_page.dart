import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/wallet_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/add_wallet_sheet.dart';
import 'widgets/feature_grid_section.dart';
import 'widgets/home_segmented_tabs.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/wallet_carousel_section.dart';

/// Halaman Beranda utama MyWallet dengan tata letak terang (Light Fintech).
/// Memuat header sapaan personal + ikon lonceng, tab pill tersegmen,
/// carousel kartu dompet, grid 6 fitur pilihan, serta riwayat transaksi per hari.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const String _prefUserNameKey = 'mywallet_user_display_name';

  int _selectedSegment = 0;
  String _userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefUserNameKey);
    if (saved != null && saved.trim().isNotEmpty && mounted) {
      setState(() => _userName = saved.trim());
    }
  }

  Future<void> _editUserNameDialog() async {
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Ubah Nama Sapaan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Masukkan nama panggilan kamu',
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _userName = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserNameKey, result);
    }
  }

  void _showNotificationPreview(BuildContext context) {
    final yesterdayReport = ref.read(yesterdayReportStreamProvider).value;
    final message = yesterdayReport != null
        ? '${yesterdayReport.notificationTitle}: ${yesterdayReport.notificationBody}'
        : 'Laporan harian dikirim setiap pagi. Atur jadwalnya di menu Lainnya.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsWithBalanceAsync = ref.watch(walletsWithBalanceStreamProvider);
    final monthlySummaryAsync = ref.watch(currentMonthSummaryStreamProvider);
    final recentTxAsync = ref.watch(recentTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: walletsWithBalanceAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'Memuat data dompet dan transaksi...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expense,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gagal memuat data Beranda',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(walletsWithBalanceStreamProvider);
                      ref.invalidate(currentMonthSummaryStreamProvider);
                      ref.invalidate(recentTransactionsStreamProvider);
                    },
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            ),
          ),
          data: (walletsWithBalance) {
            final totalBalance = walletsWithBalance.fold<int>(
              0,
              (sum, item) => sum + item.currentBalance,
            );
            final monthlySummary = monthlySummaryAsync.value ??
                const MonthlySummary(totalIncome: 0, totalExpense: 0);
            final recentTransactions =
                recentTxAsync.value ?? const <TransactionEntry>[];
            final categories = categoriesAsync.value ?? const <Category>[];
            final wallets = walletsWithBalance.map((e) => e.wallet).toList();

            return SingleChildScrollView(
              // Padding bawah >= 100px agar konten terakhir tidak tertutup tombol "+ Catat" dan bottom bar
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header: Avatar + "Hai, [nama]!" di kiri, hanya ikon lonceng di kanan
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _editUserNameDialog,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textPrimary,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.textPrimary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Hai, $_userName!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showNotificationPreview(context),
                        tooltip: 'Notifikasi Laporan Harian',
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Tab Pill Segmented: Ringkasan | Transaksi | Tabungan
                  HomeSegmentedTabs(
                    selectedIndex: _selectedSegment,
                    onChanged: (idx) => setState(() => _selectedSegment = idx),
                  ),
                  const SizedBox(height: 22),

                  // 3. Carousel Kartu Dompet
                  WalletCarouselSection(
                    wallets: walletsWithBalance,
                    totalBalance: totalBalance,
                    monthlySummary: monthlySummary,
                  ),
                  const SizedBox(height: 24),

                  // Konten menyesuaikan tab pill yang dipilih
                  if (_selectedSegment == 0) ...[
                    // 4. Section "Fitur pilihan kamu" + link "Atur"
                    const FeatureGridSection(),
                    const SizedBox(height: 26),

                    // 5. Section "Transaksi terbaru" (3 hari terakhir) + link "Lihat Semua"
                    RecentTransactionsSection(
                      transactions: recentTransactions,
                      categories: categories,
                      wallets: wallets,
                      maxDays: 3,
                    ),
                  ] else if (_selectedSegment == 1) ...[
                    RecentTransactionsSection(
                      transactions: recentTransactions,
                      categories: categories,
                      wallets: wallets,
                      maxDays: null,
                    ),
                  ] else ...[
                    _SavingsWalletsBreakdown(
                      wallets: walletsWithBalance,
                      totalBalance: totalBalance,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tampilan rincian saldo per dompet saat pengguna memilih tab pill "Tabungan".
class _SavingsWalletsBreakdown extends StatelessWidget {
  final List<WalletWithBalance> wallets;
  final int totalBalance;

  const _SavingsWalletsBreakdown({
    required this.wallets,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alokasi Saldo Dompet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: () => AddWalletSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Dompet Baru'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in wallets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.wallet.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(item.currentBalance),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
