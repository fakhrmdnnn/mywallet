import 'package:flutter/material.dart';

import '../../../../core/database/tables.dart';
import '../../../../core/database/wallet_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import 'add_wallet_sheet.dart';

/// Carousel kartu dompet bergaya modern dengan kartu besar gradien hijau (#10B981 -> #0D9488),
/// badge "UTAMA", fitur sembunyikan/tampilkan saldo (Rp********), kartu kecil "+ Tambah dompet",
/// serta indikator titik (dots) di bawahnya.
class WalletCarouselSection extends StatefulWidget {
  final List<WalletWithBalance> wallets;
  final int totalBalance;
  final MonthlySummary monthlySummary;

  const WalletCarouselSection({
    super.key,
    required this.wallets,
    required this.totalBalance,
    required this.monthlySummary,
  });

  @override
  State<WalletCarouselSection> createState() => _WalletCarouselSectionState();
}

class _WalletCarouselSectionState extends State<WalletCarouselSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isBalanceHidden = false;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Lebar rata-rata kartu utama (268) + jarak (12) = 280.
    final index = (offset / 240).round().clamp(0, widget.wallets.length);
    if (index != _activeIndex) {
      setState(() => _activeIndex = index);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showAllWalletsOverview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan Semua Dompet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      AddWalletSheet.show(context);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pastelMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saldo Gabungan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceHidden
                          ? 'Rp********'
                          : AppFormatters.currency(widget.totalBalance),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final item in widget.wallets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              item.wallet.type.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _isBalanceHidden
                              ? 'Rp********'
                              : AppFormatters.currency(item.currentBalance),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;
    final dotCount = wallets.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul seksi + tautan Lihat Semua berwarna aksen #F59E0B
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dompet transaksi kamu',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => _showAllWalletsOverview(context),
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
        const SizedBox(height: 12),

        // Carousel Kartu Dompet + Kartu Kecil "+ Tambah dompet" di tepi kanan
        SizedBox(
          height: 168,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: wallets.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == wallets.length) {
                return _AddWalletCompactCard(
                  onTap: () => AddWalletSheet.show(context),
                );
              }

              final item = wallets[index];
              final isPrimaryWallet = index == 0;

              return _PrimaryWalletCard(
                item: item,
                isPrimary: isPrimaryWallet,
                isBalanceHidden: _isBalanceHidden,
                onToggleVisibility: () {
                  setState(() => _isBalanceHidden = !_isBalanceHidden);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Indikator titik (dots) di bawah carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
            final isSelected = i == _activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 8 : 7,
              height: isSelected ? 8 : 7,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // Ringkasan Pemasukan & Pengeluaran bulan ini dalam kartu putih bersih
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: _MiniCashflowStat(
                  label: 'Pemasukan',
                  subtitle: 'bulan ini',
                  amount: widget.monthlySummary.totalIncome,
                  isHidden: _isBalanceHidden,
                  color: AppColors.income,
                  bgColor: AppColors.pastelMint,
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.surfaceBorder,
              ),
              Expanded(
                child: _MiniCashflowStat(
                  label: 'Pengeluaran',
                  subtitle: 'bulan ini',
                  amount: widget.monthlySummary.totalExpense,
                  isHidden: _isBalanceHidden,
                  color: AppColors.expense,
                  bgColor: AppColors.pastelOrange,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryWalletCard extends StatelessWidget {
  final WalletWithBalance item;
  final bool isPrimary;
  final bool isBalanceHidden;
  final VoidCallback onToggleVisibility;

  const _PrimaryWalletCard({
    required this.item,
    required this.isPrimary,
    required this.isBalanceHidden,
    required this.onToggleVisibility,
  });

  String _typeSubtitle(String type) {
    switch (type) {
      case WalletTypes.bank:
        return 'REKENING BANK';
      case WalletTypes.eWallet:
        return 'E-WALLET DIGITAL';
      case WalletTypes.cash:
      default:
        return 'DOMPET TUNAI';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          // Siluet lengkung halus di sisi kanan untuk memberi kedalaman visual kartu
          Positioned(
            right: -36,
            top: -24,
            bottom: -24,
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Baris atas: Nama Dompet + Badge "UTAMA"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _typeSubtitle(item.wallet.type),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'UTAMA',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                // Baris bawah: Label Saldo efektif + Nominal + Ikon Mata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo efektif',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isBalanceHidden
                                ? 'Rp********'
                                : AppFormatters.currency(item.currentBalance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: isBalanceHidden
                              ? 'Tampilkan saldo'
                              : 'Sembunyikan saldo',
                          child: InkWell(
                            onTap: onToggleVisibility,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                isBalanceHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kecil di tepi kanan carousel sebagai ajakan "+ Tambah dompet".
class _AddWalletCompactCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWalletCompactCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pastelMint,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
            const Text(
              '+ Tambah\ndompet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCashflowStat extends StatelessWidget {
  final String label;
  final String subtitle;
  final int amount;
  final bool isHidden;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _MiniCashflowStat({
    required this.label,
    required this.subtitle,
    required this.amount,
    required this.isHidden,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isHidden ? 'Rp******' : AppFormatters.currency(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
