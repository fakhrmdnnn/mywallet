import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/widgets/recent_transactions_section.dart';

/// Halaman "Lihat Semua" yang menampilkan seluruh riwayat transaksi
/// yang dikelompokkan per hari dari tanggal dan jam terbaru.
class AllTransactionsPage extends ConsumerWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    final transactions = txAsync.value ?? const <TransactionEntry>[];
    final categories = categoriesAsync.value ?? const <Category>[];
    final wallets = walletsAsync.value ?? const <Wallet>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding bawah >= 100px agar item terakhir selalu leluasa dibaca
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
          child: GroupedTransactionsList(
            transactions: transactions,
            categories: categories,
            wallets: wallets,
            maxDays: null,
          ),
        ),
      ),
    );
  }
}
