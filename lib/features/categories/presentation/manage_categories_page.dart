import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';

/// Halaman "Kelola Kategori" (diakses dari menu Lainnya).
/// Menampilkan daftar kategori utama yang bisa dibuka untuk melihat subkategori,
/// serta mendukung tambah, ubah, dan hapus kategori utama maupun subkategori
/// lengkap dengan pemilih warna solid dan ikon putih.
class ManageCategoriesPage extends ConsumerStatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  ConsumerState<ManageCategoriesPage> createState() =>
      _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends ConsumerState<ManageCategoriesPage> {
  String _selectedType = CategoryTypes.expense;
  final Set<int> _expandedParentIds = <int>{};

  void _toggleExpand(int parentId) {
    setState(() {
      if (_expandedParentIds.contains(parentId)) {
        _expandedParentIds.remove(parentId);
      } else {
        _expandedParentIds.add(parentId);
      }
    });
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    Category category, {
    required int subcategoryCount,
  }) async {
    final isParent = category.parentId == null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          isParent ? 'Hapus Kategori Utama?' : 'Hapus Subkategori?',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          isParent && subcategoryCount > 0
              ? 'Menghapus "${category.name}" juga akan menghapus $subcategoryCount subkategori di dalamnya. Transaksi yang sudah ada tetap aman.'
              : 'Yakin ingin menghapus "${category.name}"? Transaksi yang sudah ada tetap aman.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(walletRepositoryProvider).deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        actions: [
          IconButton(
            onPressed: () => _CategoryFormSheet.show(
              context,
              categoryType: _selectedType,
            ),
            tooltip: 'Tambah Kategori Utama',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text(
              'Gagal memuat kategori: $err',
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
          data: (allCategories) {
            final mainCategories = allCategories
                .where((c) => c.type == _selectedType && c.parentId == null)
                .toList();

            return SingleChildScrollView(
              // Padding bawah >= 100px agar konten paling bawah leluasa dibaca
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toggle tipe kategori: Pengeluaran | Pemasukan
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TypeFilterTab(
                            label: 'Pengeluaran',
                            selected: _selectedType == CategoryTypes.expense,
                            onTap: () => setState(
                              () => _selectedType = CategoryTypes.expense,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _TypeFilterTab(
                            label: 'Pemasukan',
                            selected: _selectedType == CategoryTypes.income,
                            onTap: () => setState(
                              () => _selectedType = CategoryTypes.income,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol tambah kategori utama
                  OutlinedButton.icon(
                    onPressed: () => _CategoryFormSheet.show(
                      context,
                      categoryType: _selectedType,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _selectedType == CategoryTypes.expense
                          ? 'Tambah Kategori Utama Pengeluaran'
                          : 'Tambah Kategori Utama Pemasukan',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daftar kategori utama beserta subkategorinya
                  for (final parent in mainCategories) ...[
                    Builder(
                      builder: (context) {
                        final subcategories = allCategories
                            .where((c) => c.parentId == parent.id)
                            .toList();
                        final isExpanded =
                            _expandedParentIds.contains(parent.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _MainCategoryAccordionCard(
                            parent: parent,
                            subcategories: subcategories,
                            isExpanded: isExpanded,
                            onToggleExpand: () => _toggleExpand(parent.id),
                            onEditParent: () => _CategoryFormSheet.show(
                              context,
                              categoryType: parent.type,
                              existingCategory: parent,
                            ),
                            onDeleteParent: () => _confirmDeleteCategory(
                              context,
                              parent,
                              subcategoryCount: subcategories.length,
                            ),
                            onAddSubcategory: () {
                              setState(
                                () => _expandedParentIds.add(parent.id),
                              );
                              _CategoryFormSheet.show(
                                context,
                                categoryType: parent.type,
                                parentCategory: parent,
                              );
                            },
                            onEditSubcategory: (sub) =>
                                _CategoryFormSheet.show(
                              context,
                              categoryType: sub.type,
                              parentCategory: parent,
                              existingCategory: sub,
                            ),
                            onDeleteSubcategory: (sub) =>
                                _confirmDeleteCategory(
                              context,
                              sub,
                              subcategoryCount: 0,
                            ),
                          ),
                        );
                      },
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

class _TypeFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.activeTabPill : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MainCategoryAccordionCard extends StatelessWidget {
  final Category parent;
  final List<Category> subcategories;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEditParent;
  final VoidCallback onDeleteParent;
  final VoidCallback onAddSubcategory;
  final ValueChanged<Category> onEditSubcategory;
  final ValueChanged<Category> onDeleteSubcategory;

  const _MainCategoryAccordionCard({
    required this.parent,
    required this.subcategories,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onEditParent,
    required this.onDeleteParent,
    required this.onAddSubcategory,
    required this.onEditSubcategory,
    required this.onDeleteSubcategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  CategoryCircleIcon(
                    iconCode: parent.iconCode,
                    colorValue: parent.colorValue,
                    size: 44,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subcategories.isEmpty
                              ? 'Tidak ada subkategori • Ketuk untuk tambah'
                              : '${subcategories.length} subkategori • Ketuk untuk lihat',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEditParent,
                    tooltip: 'Ubah ${parent.name}',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    onPressed: onDeleteParent,
                    tooltip: 'Hapus ${parent.name}',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.expense,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.surfaceBorder),
            Container(
              color: AppColors.bg.withValues(alpha: 0.65),
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < subcategories.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 48,
                        color: AppColors.surfaceBorder,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CategoryCircleIcon(
                            iconCode: subcategories[i].iconCode,
                            colorValue: subcategories[i].colorValue,
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subcategories[i].name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                onEditSubcategory(subcategories[i]),
                            tooltip: 'Ubah ${subcategories[i].name}',
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                onDeleteSubcategory(subcategories[i]),
                            tooltip: 'Hapus ${subcategories[i].name}',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAddSubcategory,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Subkategori'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet form untuk menambah atau mengubah Kategori Utama maupun Subkategori,
/// dilengkapi pemilih warna lingkaran solid dan pemilih ikon putih.
class _CategoryFormSheet extends ConsumerStatefulWidget {
  final String categoryType;
  final Category? parentCategory;
  final Category? existingCategory;

  const _CategoryFormSheet({
    required this.categoryType,
    this.parentCategory,
    this.existingCategory,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryType,
    Category? parentCategory,
    Category? existingCategory,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryFormSheet(
        categoryType: categoryType,
        parentCategory: parentCategory,
        existingCategory: existingCategory,
      ),
    );
  }

  @override
  ConsumerState<_CategoryFormSheet> createState() =>
      _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late int _selectedColorValue;
  late int _selectedIconCode;
  String? _errorMessage;
  bool _isSaving = false;

  bool get _isEditing => widget.existingCategory != null;
  bool get _isSubcategory =>
      widget.parentCategory != null ||
      widget.existingCategory?.parentId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCategory;
    final parent = widget.parentCategory;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _selectedColorValue = existing?.colorValue ??
        parent?.colorValue ??
        CategoryIconHelper.availableColors.first.toARGB32();
    _selectedIconCode = existing?.iconCode ??
        parent?.iconCode ??
        CategoryIconHelper.availableIcons.first.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Nama kategori wajib diisi.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    final repo = ref.read(walletRepositoryProvider);
    final existing = widget.existingCategory;

    if (existing != null) {
      final updated = Category(
        id: existing.id,
        name: name,
        type: existing.type,
        iconCode: _selectedIconCode,
        colorValue: _selectedColorValue,
        parentId: existing.parentId,
      );
      await repo.updateCategory(updated);
    } else {
      await repo.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          type: widget.categoryType,
          iconCode: _selectedIconCode,
          colorValue: _selectedColorValue,
          parentId: Value(widget.parentCategory?.id),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final String sheetTitle;
    if (_isEditing) {
      sheetTitle = _isSubcategory ? 'Ubah Subkategori' : 'Ubah Kategori Utama';
    } else {
      sheetTitle = _isSubcategory
          ? 'Tambah Subkategori (${widget.parentCategory!.name})'
          : 'Tambah Kategori Utama';
    }

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
              children: [
                CategoryCircleIcon(
                  iconCode: _selectedIconCode,
                  colorValue: _selectedColorValue,
                  size: 42,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sheetTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Nama',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: _isSubcategory
                    ? 'Contoh: Kopi susu, Parkir motor'
                    : 'Contoh: Makanan & Minuman',
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
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Pilih Warna',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in CategoryIconHelper.availableColors)
                  InkWell(
                    onTap: () => setState(
                      () => _selectedColorValue = color.toARGB32(),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColorValue == color.toARGB32()
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2.2,
                        ),
                      ),
                      child: _selectedColorValue == color.toARGB32()
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Pilih Ikon',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: GridView.builder(
                itemCount: CategoryIconHelper.availableIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final icon = CategoryIconHelper.availableIcons[index];
                  final selected = _selectedIconCode == icon.codePoint;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedIconCode = icon.codePoint),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(_selectedColorValue)
                            : AppColors.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.surfaceBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color:
                            selected ? Colors.white : AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.expense,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Kategori'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
