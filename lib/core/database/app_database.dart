import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Struktur definisi seed kategori utama beserta daftar subkategorinya.
class _CategorySeedGroup {
  final String name;
  final String type;
  final int colorValue;
  final IconData icon;
  final List<({String name, IconData icon})> subcategories;

  const _CategorySeedGroup({
    required this.name,
    required this.type,
    required this.colorValue,
    required this.icon,
    this.subcategories = const [],
  });
}

/// Kelas utama database SQLite lokal menggunakan Drift.
/// Mendukung struktur kategori utama (parentId == null) + subkategori (parentId != null)
/// serta migrasi otomatis dari schemaVersion 1 ke 2 tanpa menghapus transaksi lama.
@DriftDatabase(tables: [Wallets, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await _migrateV1ToV2(m);
        }
      },
      beforeOpen: (details) async {
        // Mengaktifkan foreign key constraint di SQLite agar relasi antar tabel terjaga.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Mengisi dompet "Tunai" serta hierarki kategori utama + subkategori saat pertama kali dibuat.
  Future<void> _seedInitialData() async {
    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'Tunai',
        type: WalletTypes.cash,
        initialBalance: const Value(0),
        colorValue: AppColors.primary.toARGB32(),
      ),
    );

    await _seedCategoriesHierarchy();
  }

  /// Migrasi dari schemaVersion 1 ke 2:
  /// 1. Menambahkan kolom `parent_id` pada tabel `categories`.
  /// 2. Menyimpan daftar kategori lama yang sudah ada.
  /// 3. Menambahkan hierarki kategori utama + subkategori baru.
  /// 4. Memindahkan seluruh transaksi yang memakai kategori lama ke kategori baru yang sesuai.
  /// 5. Menghapus kategori lama tanpa menghilangkan satu pun transaksi.
  Future<void> _migrateV1ToV2(Migrator m) async {
    await m.addColumn(categories, categories.parentId);

    final oldCategories = await select(categories).get();
    final newParentIds = await _seedCategoriesHierarchy();

    if (oldCategories.isEmpty) return;

    for (final oldCat in oldCategories) {
      final targetNewId = _resolveTargetNewCategoryId(oldCat, newParentIds);
      if (targetNewId != null) {
        await (update(transactions)
              ..where((t) => t.categoryId.equals(oldCat.id)))
            .write(
          TransactionsCompanion(categoryId: Value(targetNewId)),
        );
      }
    }

    final oldIds = oldCategories.map((c) => c.id).toList();
    await (delete(categories)..where((c) => c.id.isIn(oldIds))).go();
  }

  /// Menentukan ID kategori utama baru yang paling cocok untuk kategori versi lama.
  int? _resolveTargetNewCategoryId(
    Category oldCat,
    Map<String, int> newParentIds,
  ) {
    if (oldCat.type == CategoryTypes.income) {
      return newParentIds['${CategoryTypes.income}:Pemasukan'];
    }

    switch (oldCat.name.trim().toLowerCase()) {
      case 'makan':
      case 'makanan':
      case 'makanan & minuman':
        return newParentIds['${CategoryTypes.expense}:Makanan & Minuman'];
      case 'transportasi':
        return newParentIds['${CategoryTypes.expense}:Transportasi'];
      case 'tagihan':
      case 'beban keuangan':
        return newParentIds['${CategoryTypes.expense}:Beban Keuangan'];
      case 'hiburan':
      case 'gaya hidup & hiburan':
        return newParentIds['${CategoryTypes.expense}:Gaya Hidup & Hiburan'];
      case 'belanja':
        return newParentIds['${CategoryTypes.expense}:Belanja'];
      default:
        return newParentIds['${CategoryTypes.expense}:Lainnya'];
    }
  }

  /// Menyisipkan seluruh kategori utama beserta subkategorinya dan mengembalikan
  /// peta `"{type}:{name}" -> id` dari kategori utama yang baru dibuat.
  Future<Map<String, int>> _seedCategoriesHierarchy() async {
    const groups = <_CategorySeedGroup>[
      // --- PENGELUARAN ---
      _CategorySeedGroup(
        name: 'Makanan & Minuman',
        type: CategoryTypes.expense,
        colorValue: 0xFFFF3D00,
        icon: Icons.restaurant_rounded,
        subcategories: [
          (name: 'Makan', icon: Icons.restaurant_rounded),
          (name: 'Bahan makanan', icon: Icons.local_grocery_store_rounded),
          (name: 'Kafe & kopi', icon: Icons.local_cafe_rounded),
          (name: 'Jajan', icon: Icons.fastfood_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Belanja',
        type: CategoryTypes.expense,
        colorValue: 0xFF4FC3F7,
        icon: Icons.shopping_bag_rounded,
        subcategories: [
          (name: 'Pakaian', icon: Icons.checkroom_rounded),
          (name: 'Elektronik', icon: Icons.devices_rounded),
          (
            name: 'Kesehatan & kecantikan',
            icon: Icons.medical_services_rounded
          ),
          (name: 'Rumah tangga', icon: Icons.weekend_rounded),
          (name: 'Hadiah', icon: Icons.card_giftcard_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Tempat Tinggal',
        type: CategoryTypes.expense,
        colorValue: 0xFFFFA726,
        icon: Icons.home_rounded,
        subcategories: [
          (name: 'Sewa/kos', icon: Icons.home_rounded),
          (name: 'Listrik', icon: Icons.bolt_rounded),
          (name: 'Air', icon: Icons.water_drop_rounded),
          (name: 'Gas', icon: Icons.local_fire_department_rounded),
          (name: 'Peliharaan', icon: Icons.pets_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Transportasi',
        type: CategoryTypes.expense,
        colorValue: 0xFF78909C,
        icon: Icons.directions_bus_rounded,
        subcategories: [
          (name: 'Angkutan umum', icon: Icons.directions_bus_rounded),
          (name: 'Ojek online & taksi', icon: Icons.local_taxi_rounded),
          (name: 'Perjalanan jauh', icon: Icons.flight_takeoff_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Kendaraan',
        type: CategoryTypes.expense,
        colorValue: 0xFFAA00FF,
        icon: Icons.directions_car_rounded,
        subcategories: [
          (name: 'BBM', icon: Icons.local_gas_station_rounded),
          (name: 'Parkir & tol', icon: Icons.local_parking_rounded),
          (name: 'Servis', icon: Icons.build_rounded),
          (name: 'Pajak & asuransi', icon: Icons.verified_user_rounded),
          (name: 'Cicilan', icon: Icons.receipt_long_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Gaya Hidup & Hiburan',
        type: CategoryTypes.expense,
        colorValue: 0xFF64DD17,
        icon: Icons.person_rounded,
        subcategories: [
          (name: 'Olahraga', icon: Icons.fitness_center_rounded),
          (name: 'Hobi', icon: Icons.sports_esports_rounded),
          (name: 'Streaming', icon: Icons.movie_rounded),
          (name: 'Liburan', icon: Icons.beach_access_rounded),
          (name: 'Donasi', icon: Icons.volunteer_activism_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Komunikasi & PC',
        type: CategoryTypes.expense,
        colorValue: 0xFF536DFE,
        icon: Icons.desktop_windows_rounded,
        subcategories: [
          (name: 'Pulsa & paket data', icon: Icons.phone_android_rounded),
          (name: 'Internet rumah', icon: Icons.wifi_rounded),
          (name: 'Aplikasi & software', icon: Icons.apps_rounded),
          (name: 'Hosting/domain', icon: Icons.language_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Beban Keuangan',
        type: CategoryTypes.expense,
        colorValue: 0xFF00BFA5,
        icon: Icons.monetization_on_rounded,
        subcategories: [
          (name: 'Biaya admin', icon: Icons.account_balance_rounded),
          (name: 'Bunga & cicilan', icon: Icons.percent_rounded),
          (name: 'Pajak', icon: Icons.receipt_long_rounded),
          (name: 'Denda', icon: Icons.gavel_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Investasi',
        type: CategoryTypes.expense,
        colorValue: 0xFFF50057,
        icon: Icons.hub_rounded,
        subcategories: [
          (name: 'Saham', icon: Icons.trending_up_rounded),
          (name: 'Reksa dana', icon: Icons.pie_chart_rounded),
          (name: 'Emas', icon: Icons.diamond_rounded),
          (name: 'Kripto', icon: Icons.currency_bitcoin_rounded),
          (name: 'Deposito', icon: Icons.savings_rounded),
        ],
      ),
      _CategorySeedGroup(
        name: 'Lainnya',
        type: CategoryTypes.expense,
        colorValue: 0xFF9E9E9E,
        icon: Icons.more_horiz_rounded,
      ),

      // --- PEMASUKAN ---
      _CategorySeedGroup(
        name: 'Pemasukan',
        type: CategoryTypes.income,
        colorValue: 0xFFFFCA28,
        icon: Icons.paid_rounded,
        subcategories: [
          (name: 'Gaji', icon: Icons.payments_rounded),
          (name: 'Bonus', icon: Icons.card_giftcard_rounded),
          (name: 'Hadiah', icon: Icons.card_giftcard_rounded),
          (name: 'Penjualan', icon: Icons.storefront_rounded),
          (name: 'Bunga & dividen', icon: Icons.trending_up_rounded),
          (name: 'Lainnya', icon: Icons.more_horiz_rounded),
        ],
      ),
    ];

    final parentIds = <String, int>{};

    for (final group in groups) {
      final parentId = await into(categories).insert(
        CategoriesCompanion.insert(
          name: group.name,
          type: group.type,
          iconCode: group.icon.codePoint,
          colorValue: group.colorValue,
        ),
      );
      parentIds['${group.type}:${group.name}'] = parentId;

      if (group.subcategories.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            categories,
            [
              for (final sub in group.subcategories)
                CategoriesCompanion.insert(
                  name: sub.name,
                  type: group.type,
                  iconCode: sub.icon.codePoint,
                  colorValue: group.colorValue,
                  parentId: Value(parentId),
                ),
            ],
          );
        });
      }
    }

    return parentIds;
  }
}

/// Membuka koneksi file SQLite di direktori dokumen aplikasi perangkat.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mywallet.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
