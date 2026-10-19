import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../home/presentation/widgets/add_wallet_sheet.dart';

/// Form bottom sheet untuk menambah atau mengubah transaksi
/// (Pengeluaran, Pemasukan, atau Transfer Antar Dompet).
/// Mendukung pemilihan Kategori Utama terlebih dahulu, lalu Subkategori (opsional) lewat bottom sheet.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionEntry? existingTransaction;
  final String? initialType;

  const AddTransactionSheet({
    super.key,
    this.existingTransaction,
    this.initialType,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionEntry? existingTransaction,
    String? initialType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTransactionSheet(
        existingTransaction: existingTransaction,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String _selectedType;
  int? _selectedWalletId;
  int? _selectedToWalletId;
  int? _selectedCategoryId;
  late DateTime _selectedDate;

  String? _errorMessage;
  bool _isSaving = false;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    _selectedType =
        existing?.type ?? widget.initialType ?? TransactionTypes.expense;
    _selectedWalletId = existing?.walletId;
    _selectedToWalletId = existing?.toWalletId;
    _selectedCategoryId = existing?.categoryId;
    _selectedDate = existing?.date ?? DateTime.now();

    _amountController = TextEditingController(
      text: existing != null ? AppFormatters.thousand(existing.amount) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      _selectedCategoryId = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  /// Menampilkan bottom sheet untuk memilih subkategori (opsional) dari kategori utama yang dipilih.
  Future<void> _showSubcategoryPickerSheet(
    Category parentCategory,
    List<Category> subcategories,
  ) async {
    final chosenId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  CategoryCircleIcon(
                    iconCode: parentCategory.iconCode,
                    colorValue: parentCategory.colorValue,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentCategory.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Pilih subkategori (opsional)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Opsi gunakan kategori utama saja (tanpa subkategori)
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: CategoryCircleIcon(
                  iconCode: parentCategory.iconCode,
                  colorValue: parentCategory.colorValue,
                  size: 40,
                  iconSize: 20,
                ),
                title: Text(
                  'Umum (${parentCategory.name})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Gunakan kategori utama tanpa subkategori',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: _selectedCategoryId == parentCategory.id
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(parentCategory.id),
              ),
              const SizedBox(height: 4),

              // Daftar subkategori
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final sub in subcategories)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: CategoryCircleIcon(
                            iconCode: sub.iconCode,
                            colorValue: sub.colorValue,
                            size: 40,
                            iconSize: 20,
                          ),
                          title: Text(
                            sub.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: _selectedCategoryId == sub.id
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(sheetContext).pop(sub.id),
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

    if (chosenId != null && mounted) {
      setState(() => _selectedCategoryId = chosenId);
    }
  }

  Future<void> _submit(List<Wallet> wallets, List<Category> categories) async {
    final amount = AppFormatters.parseDigits(_amountController.text);
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Nominal harus lebih dari Rp 0.';
      });
      return;
    }

    final walletId = _selectedWalletId ?? wallets.firstOrNull?.id;
    if (walletId == null) {
      setState(() {
        _errorMessage = 'Pilih dompet terlebih dahulu.';
      });
      return;
    }

    int? categoryId = _selectedCategoryId;
    int? toWalletId = _selectedToWalletId;

    if (_selectedType == TransactionTypes.transfer) {
      if (toWalletId == null) {
        setState(() {
          _errorMessage = 'Pilih dompet tujuan transfer.';
        });
        return;
      }
      if (toWalletId == walletId) {
        setState(() {
          _errorMessage = 'Dompet tujuan tidak boleh sama dengan dompet asal.';
        });
        return;
      }
      categoryId = null;
    } else {
      final matchingMainCategories = categories
          .where((c) => c.type == _selectedType && c.parentId == null)
          .toList();
      categoryId ??= matchingMainCategories.firstOrNull?.id;
      if (categoryId == null) {
        setState(() {
          _errorMessage = 'Pilih kategori transaksi.';
        });
        return;
      }
      toWalletId = null;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    final noteText = _noteController.text.trim();
    final repo = ref.read(walletRepositoryProvider);

    if (_isEditing) {
      final updated = TransactionEntry(
        id: widget.existingTransaction!.id,
        walletId: walletId,
        categoryId: categoryId,
        type: _selectedType,
        amount: amount,
        note: noteText.isEmpty ? null : noteText,
        date: _selectedDate,
        toWalletId: toWalletId,
      );
      await repo.updateTransaction(updated);
    } else {
      await repo.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          categoryId: Value(categoryId),
          type: _selectedType,
          amount: amount,
          note: Value(noteText.isEmpty ? null : noteText),
          date: _selectedDate,
          toWalletId: Value(toWalletId),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteExisting() async {
    final existing = widget.existingTransaction;
    if (existing == null) return;

    setState(() => _isSaving = true);
    await ref.read(walletRepositoryProvider).deleteTransaction(existing.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final wallets = walletsAsync.value ?? const <Wallet>[];
    final allCategories = categoriesAsync.value ?? const <Category>[];
    final categoryMap = {for (final c in allCategories) c.id: c};

    final activeWalletId = _selectedWalletId ?? wallets.firstOrNull?.id;
    if (_selectedWalletId == null && activeWalletId != null) {
      _selectedWalletId = activeWalletId;
    }

    if (_selectedType == TransactionTypes.transfer &&
        (_selectedToWalletId == null ||
            _selectedToWalletId == _selectedWalletId)) {
      final otherWallet =
          wallets.where((w) => w.id != _selectedWalletId).firstOrNull;
      _selectedToWalletId = otherWallet?.id;
    }

    // Kategori utama untuk tipe transaksi yang aktif (parentId == null)
    final mainCategories = allCategories
        .where((c) => c.type == _selectedType && c.parentId == null)
        .toList();

    if (_selectedType != TransactionTypes.transfer &&
        _selectedCategoryId == null &&
        mainCategories.isNotEmpty) {
      _selectedCategoryId = mainCategories.first.id;
    }

    final selectedCategory = _selectedCategoryId != null
        ? categoryMap[_selectedCategoryId!]
        : null;
    final activeParentCategoryId = selectedCategory != null
        ? (selectedCategory.parentId ?? selectedCategory.id)
        : null;
    final activeParentCategory = activeParentCategoryId != null
        ? categoryMap[activeParentCategoryId]
        : null;
    final activeSubcategories = activeParentCategoryId != null
        ? allCategories
            .where((c) => c.parentId == activeParentCategoryId)
            .toList()
        : const <Category>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Ubah Transaksi' : 'Tambah Transaksi',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isEditing)
                      IconButton(
                        onPressed: _isSaving ? null : _deleteExisting,
                        tooltip: 'Hapus Transaksi',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.expense,
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Toggle 3 pilihan: Pengeluaran / Pemasukan / Transfer
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  _TypeTabButton(
                    label: 'Pengeluaran',
                    activeColor: AppColors.expense,
                    selected: _selectedType == TransactionTypes.expense,
                    onTap: () => _onTypeChanged(TransactionTypes.expense),
                  ),
                  _TypeTabButton(
                    label: 'Pemasukan',
                    activeColor: AppColors.income,
                    selected: _selectedType == TransactionTypes.income,
                    onTap: () => _onTypeChanged(TransactionTypes.income),
                  ),
                  _TypeTabButton(
                    label: 'Transfer',
                    activeColor: AppColors.accent,
                    selected: _selectedType == TransactionTypes.transfer,
                    onTap: () => _onTypeChanged(TransactionTypes.transfer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Input Nominal Besar dengan format Rupiah otomatis
            const Text(
              'Nominal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Pilihan Dompet (Asal & Tujuan jika Transfer)
            Text(
              _selectedType == TransactionTypes.transfer
                  ? 'Dompet Asal'
                  : 'Pilih Dompet',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _WalletSelectorRow(
              wallets: wallets,
              selectedWalletId: _selectedWalletId,
              onSelect: (id) {
                setState(() {
                  _selectedWalletId = id;
                  if (_selectedToWalletId == id) {
                    _selectedToWalletId =
                        wallets.where((w) => w.id != id).firstOrNull?.id;
                  }
                });
              },
            ),

            if (_selectedType == TransactionTypes.transfer) ...[
              const SizedBox(height: 16),
              const Text(
                'Dompet Tujuan',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (wallets.length < 2)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Transfer membutuhkan minimal 2 dompet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => AddWalletSheet.show(context),
                        child: const Text('Tambah Dompet'),
                      ),
                    ],
                  ),
                )
              else
                _WalletSelectorRow(
                  wallets:
                      wallets.where((w) => w.id != _selectedWalletId).toList(),
                  selectedWalletId: _selectedToWalletId,
                  onSelect: (id) => setState(() => _selectedToWalletId = id),
                ),
            ] else ...[
              // Pilihan Kategori Utama + Subkategori (opsional lewat bottom sheet)
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategori Utama',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activeParentCategory != null &&
                      activeSubcategories.isNotEmpty)
                    InkWell(
                      onTap: () => _showSubcategoryPickerSheet(
                        activeParentCategory,
                        activeSubcategories,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCategory != null &&
                                      selectedCategory.parentId != null
                                  ? 'Sub: ${selectedCategory.name}'
                                  : 'Pilih Subkategori',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mainCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final parentCat = mainCategories[index];
                  final isParentActive =
                      parentCat.id == activeParentCategoryId;
                  final catColor = Color(parentCat.colorValue);
                  final subcategories = allCategories
                      .where((c) => c.parentId == parentCat.id)
                      .toList();

                  // Label menampilkan subkategori jika sedang dipilih di bawah kategori utama ini
                  final displayLabel = isParentActive &&
                          selectedCategory != null &&
                          selectedCategory.parentId == parentCat.id
                      ? selectedCategory.name
                      : parentCat.name;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategoryId = parentCat.id);
                      if (subcategories.isNotEmpty) {
                        _showSubcategoryPickerSheet(parentCat, subcategories);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isParentActive
                            ? catColor.withValues(alpha: 0.14)
                            : AppColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isParentActive
                              ? catColor
                              : AppColors.surfaceBorder,
                          width: isParentActive ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lingkaran warna solid + ikon putih
                          CategoryCircleIcon(
                            iconCode: isParentActive &&
                                    selectedCategory != null &&
                                    selectedCategory.parentId == parentCat.id
                                ? selectedCategory.iconCode
                                : parentCat.iconCode,
                            colorValue: parentCat.colorValue,
                            size: 38,
                            iconSize: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isParentActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isParentActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 18),

            // Pilih Tanggal & Catatan Opsional
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppFormatters.fullDate(_selectedDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan (Opsional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tulis keterangan transaksi...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expense,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () => _submit(wallets, allCategories),
                child: Text(
                  _isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  final String label;
  final Color activeColor;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTabButton({
    required this.label,
    required this.activeColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? activeColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletSelectorRow extends StatelessWidget {
  final List<Wallet> wallets;
  final int? selectedWalletId;
  final ValueChanged<int> onSelect;

  const _WalletSelectorRow({
    required this.wallets,
    required this.selectedWalletId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final wallet in wallets)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => onSelect(wallet.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: wallet.id == selectedWalletId
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wallet.id == selectedWalletId
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: wallet.id == selectedWalletId ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(wallet.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        wallet.name,
                        style: TextStyle(
                          color: wallet.id == selectedWalletId
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: wallet.id == selectedWalletId
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
