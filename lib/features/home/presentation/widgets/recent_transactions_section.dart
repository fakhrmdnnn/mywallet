import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/presentation/add_transaction_sheet.dart';
import '../../../transactions/presentation/all_transactions_page.dart';

/// Model kelompok transaksi untuk satu tanggal kalender.
class DailyTransactionGroup {
  final DateTime day;
  final List<TransactionEntry> items;
  final int totalExpense;

  const DailyTransactionGroup({
    required this.day,
    required this.items,
    required this.totalExpense,
  });

  /// Mengelompokkan transaksi per hari, diurutkan dari tanggal terbaru ke terlama
  /// dan di dalam satu hari diurutkan dari jam terbaru.
  static List<DailyTransactionGroup> fromTransactions(
    List<TransactionEntry> transactions,
  ) {
    if (transactions.isEmpty) return const [];

    // Urutkan dari waktu terbaru ke terlama (tie-breaker: id terbesar/terbaru).
    final sorted = [...transactions]..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

    final groupedMap = <DateTime, List<TransactionEntry>>{};
    for (final tx in sorted) {
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedMap.putIfAbsent(dayKey, () => []).add(tx);
    }

    final sortedDays = groupedMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDays.map((day) {
      final dayItems = groupedMap[day]!;
      var expenseSum = 0;
      for (final tx in dayItems) {
        if (tx.type == TransactionTypes.expense) {
          expenseSum += tx.amount;
        }
      }
      return DailyTransactionGroup(
        day: day,
        items: dayItems,
        totalExpense: expenseSum,
      );
    }).toList();
  }
}

/// Seksi "Transaksi terbaru" + tautan "Lihat Semua" di halaman Beranda.
/// Secara default hanya menampilkan 3 kelompok hari terakhir di Beranda.
class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionEntry> transactions;
  final List<Category> categories;
  final List<Wallet> wallets;
  final int? maxDays;
  final VoidCallback? onSeeAllTap;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.categories,
    required this.wallets,
    this.maxDays = 3,
    this.onSeeAllTap,
  });

  void _openAllTransactions(BuildContext context) {
    if (onSeeAllTap != null) {
      onSeeAllTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AllTransactionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi terbaru',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => _openAllTransactions(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: AppColors.accentLinkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accentLink,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GroupedTransactionsList(
          transactions: transactions,
          categories: categories,
          wallets: wallets,
          maxDays: maxDays,
        ),
      ],
    );
  }
}

/// Komponen daftar transaksi yang dikelompokkan per tanggal.
/// Tiap kelompok tanggal memiliki:
/// - Header hari ("Hari ini", "Kemarin", atau "Jumat, 16 Okt 2026") di kiri
/// - Total pengeluaran hari tersebut ("- Rp 31.500") di kanan dengan warna sekunder
/// - Satu card putih berisi semua item pada hari itu dengan garis pemisah tipis antar item.
class GroupedTransactionsList extends ConsumerWidget {
  final List<TransactionEntry> transactions;
  final List<Category> categories;
  final List<Wallet> wallets;
  final int? maxDays;

  const GroupedTransactionsList({
    super.key,
    required this.transactions,
    required this.categories,
    required this.wallets,
    this.maxDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return _EmptyTransactionsCard(
        onAddPressed: () => AddTransactionSheet.show(context),
      );
    }

    final categoryMap = {for (final c in categories) c.id: c};
    final walletMap = {for (final w in wallets) w.id: w};

    final allGroups = DailyTransactionGroup.fromTransactions(transactions);
    final visibleGroups = maxDays != null && allGroups.length > maxDays!
        ? allGroups.take(maxDays!).toList()
        : allGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var gIndex = 0; gIndex < visibleGroups.length; gIndex++) ...[
          if (gIndex > 0) const SizedBox(height: 20),
          _DayTransactionCardGroup(
            group: visibleGroups[gIndex],
            categoryMap: categoryMap,
            walletMap: walletMap,
            onDeleteTransaction: (tx) async {
              await ref
                  .read(walletRepositoryProvider)
                  .deleteTransaction(tx.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi dihapus.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }
}

class _DayTransactionCardGroup extends StatelessWidget {
  final DailyTransactionGroup group;
  final Map<int, Category> categoryMap;
  final Map<int, Wallet> walletMap;
  final ValueChanged<TransactionEntry> onDeleteTransaction;

  const _DayTransactionCardGroup({
    required this.group,
    required this.categoryMap,
    required this.walletMap,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = AppFormatters.dayGroupHeader(group.day);
    final expenseLabel = '- ${AppFormatters.currency(group.totalExpense)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header hari di kiri + total pengeluaran hari itu di kanan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                expenseLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Satu card putih untuk seluruh transaksi pada hari tersebut
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 16,
                    color: AppColors.surfaceBorder,
                  ),
                _buildDismissibleTile(context, group.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDismissibleTile(
    BuildContext context,
    TransactionEntry tx,
  ) {
    final category =
        tx.categoryId != null ? categoryMap[tx.categoryId!] : null;
    final parentCategory = category?.parentId != null
        ? categoryMap[category!.parentId!]
        : null;
    final fromWallet = walletMap[tx.walletId];
    final toWallet =
        tx.toWalletId != null ? walletMap[tx.toWalletId!] : null;

    return Dismissible(
      key: ValueKey('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.pastelOrange,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.expense,
            ),
            SizedBox(width: 6),
            Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDeleteTransaction(tx),
      child: _TransactionTile(
        transaction: tx,
        category: category,
        parentCategory: parentCategory,
        fromWallet: fromWallet,
        toWallet: toWallet,
        onTap: () => AddTransactionSheet.show(
          context,
          existingTransaction: tx,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntry transaction;
  final Category? category;
  final Category? parentCategory;
  final Wallet? fromWallet;
  final Wallet? toWallet;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.parentCategory,
    required this.fromWallet,
    required this.toWallet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionTypes.income;
    final isExpense = transaction.type == TransactionTypes.expense;
    final isTransfer = transaction.type == TransactionTypes.transfer;

    final Color amountColor;
    final String amountPrefix;
    final int circleIconCode;
    final int circleColorValue;
    final String titleText;
    final String walletSubtitle;

    if (isTransfer) {
      amountColor = AppColors.textPrimary;
      amountPrefix = '';
      circleIconCode = Icons.swap_horiz_rounded.codePoint;
      circleColorValue = AppColors.primary.toARGB32();
      final fromName = fromWallet?.name ?? 'Dompet';
      final toName = toWallet?.name ?? 'Dompet';
      titleText = 'Transfer: $fromName ke $toName';
      walletSubtitle = 'Pindah saldo';
    } else {
      amountColor = isIncome ? AppColors.income : AppColors.expense;
      amountPrefix = isIncome ? '+ ' : '- ';
      circleIconCode = category?.iconCode ??
          (isIncome
              ? Icons.paid_rounded.codePoint
              : Icons.restaurant_rounded.codePoint);
      circleColorValue = category?.colorValue ??
          parentCategory?.colorValue ??
          (isIncome
              ? const Color(0xFFFFCA28).toARGB32()
              : const Color(0xFF9E9E9E).toARGB32());
      titleText = category?.name ?? (isExpense ? 'Pengeluaran' : 'Pemasukan');
      final baseWalletName = fromWallet?.name ?? 'Dompet';
      walletSubtitle = parentCategory != null
          ? '${parentCategory!.name} • $baseWalletName'
          : baseWalletName;
    }

    final hasNote =
        transaction.note != null && transaction.note!.trim().isNotEmpty;
    final timeString = AppFormatters.time24(
      transaction.date.hour,
      transaction.date.minute,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Ikon kategori: lingkaran warna solid + ikon putih
            CategoryCircleIcon(
              iconCode: circleIconCode,
              colorValue: circleColorValue,
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasNote
                        ? '${transaction.note!} • $walletSubtitle'
                        : walletSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${AppFormatters.currency(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyTransactionsCard({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.pastelMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Yuk, mulai catat pengeluaran atau pemasukan pertamamu hari ini agar arus kas tercatat rapi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Catat Transaksi Pertama'),
          ),
        ],
      ),
    );
  }
}
