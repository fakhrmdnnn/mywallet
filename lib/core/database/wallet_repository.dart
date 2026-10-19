import 'package:drift/drift.dart';

import '../utils/formatters.dart';
import 'app_database.dart';
import 'tables.dart';

/// Ringkasan laporan harian untuk ditampilkan pada notifikasi pagi dan halaman Statistik.
class DailyReportSummary {
  final DateTime date;
  final int totalExpense;
  final int totalIncome;
  final int transactionCount;
  final String? topCategoryName;

  const DailyReportSummary({
    required this.date,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    this.topCategoryName,
  });

  /// Judul notifikasi, contoh: "Laporan 18 Oktober".
  String get notificationTitle => 'Laporan ${AppFormatters.dayMonth(date)}';

  /// Isi notifikasi sesuai kondisi apakah ada pengeluaran/pemasukan pada hari tersebut.
  String get notificationBody {
    if (totalExpense == 0 && totalIncome == 0) {
      return 'Kemarin tidak ada pengeluaran \u{1F389}';
    }
    final expText = 'Pengeluaran ${AppFormatters.currency(totalExpense)}';
    final incText = 'Pemasukan ${AppFormatters.currency(totalIncome)}';
    final topText = topCategoryName != null
        ? ' • Transaksi terbanyak: $topCategoryName'
        : '';
    return '$expText • $incText$topText';
  }
}

/// Ringkasan total pemasukan dan pengeluaran dalam satu bulan.
class MonthlySummary {
  final int totalIncome;
  final int totalExpense;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
  });

  int get netCashflow => totalIncome - totalExpense;
}

/// Model gabungan data dompet beserta saldo akhirnya yang sudah dihitung.
class WalletWithBalance {
  final Wallet wallet;
  final int currentBalance;

  const WalletWithBalance({
    required this.wallet,
    required this.currentBalance,
  });
}

/// Repository untuk mengelola operasi database (wallets, categories, transactions)
/// serta perhitungan saldo, arus kas bulanan, dan agregasi per kategori utama.
class WalletRepository {
  final AppDatabase _db;

  const WalletRepository(this._db);

  // --- CRUD Wallets ---

  Future<List<Wallet>> getAllWallets() => _db.select(_db.wallets).get();

  Stream<List<Wallet>> watchAllWallets() => _db.select(_db.wallets).watch();

  Future<Wallet?> getWalletById(int id) {
    return (_db.select(_db.wallets)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertWallet(WalletsCompanion wallet) {
    return _db.into(_db.wallets).insert(wallet);
  }

  Future<bool> updateWallet(Wallet wallet) {
    return _db.update(_db.wallets).replace(wallet);
  }

  Future<int> deleteWallet(int id) {
    return (_db.delete(_db.wallets)..where((w) => w.id.equals(id))).go();
  }

  // --- CRUD Categories (Kategori Utama & Subkategori) ---

  Future<List<Category>> getAllCategories() => _db.select(_db.categories).get();

  Stream<List<Category>> watchAllCategories() =>
      _db.select(_db.categories).watch();

  Stream<List<Category>> watchCategoriesByType(String type) {
    return (_db.select(_db.categories)..where((c) => c.type.equals(type)))
        .watch();
  }

  /// Memantau hanya kategori utama (`parentId == null`) berdasarkan tipe.
  Stream<List<Category>> watchMainCategoriesByType(String type) {
    return (_db.select(_db.categories)
          ..where((c) => c.type.equals(type) & c.parentId.isNull()))
        .watch();
  }

  /// Memantau daftar subkategori dari sebuah kategori utama (`parentId == parentCategoryId`).
  Stream<List<Category>> watchSubcategories(int parentCategoryId) {
    return (_db.select(_db.categories)
          ..where((c) => c.parentId.equals(parentCategoryId)))
        .watch();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  /// Mengembalikan ID kategori utama (induk) dari suatu kategori.
  /// Jika kategori tersebut adalah subkategori (`parentId != null`), maka mengembalikan `parentId`.
  static int resolveParentCategoryId(
    int categoryId,
    Map<int, Category> categoryById,
  ) {
    final cat = categoryById[categoryId];
    if (cat == null) return categoryId;
    return cat.parentId ?? cat.id;
  }

  // --- CRUD Transactions & Stream Terbaru ---

  Future<List<TransactionEntry>> getAllTransactions() {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Memantau daftar transaksi terbaru secara reaktif, diurutkan dari tanggal terbaru.
  Stream<List<TransactionEntry>> watchRecentTransactions({int limit = 20}) {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .watch();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) {
    return _db.into(_db.transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionEntry entry) {
    return _db.update(_db.transactions).replace(entry);
  }

  Future<int> deleteTransaction(int id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // --- Perhitungan Saldo per Dompet ---

  /// Menghitung saldo akhir sebuah dompet dengan rumus:
  /// initialBalance + pemasukan - pengeluaran - transfer keluar + transfer masuk.
  Future<int> calculateWalletBalance(int walletId) async {
    final wallet = await getWalletById(walletId);
    if (wallet == null) return 0;

    final relatedTransactions = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.walletId.equals(walletId) | t.toWalletId.equals(walletId),
          ))
        .get();

    return _computeBalanceFromList(wallet, relatedTransactions);
  }

  /// Memantau perubahan saldo sebuah dompet secara reaktif setiap ada perubahan transaksi.
  Stream<int> watchWalletBalance(int walletId) {
    final query = _db.select(_db.wallets).join([
      leftOuterJoin(
        _db.transactions,
        _db.transactions.walletId.equalsExp(_db.wallets.id) |
            _db.transactions.toWalletId.equalsExp(_db.wallets.id),
      ),
    ])
      ..where(_db.wallets.id.equals(walletId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      final wallet = rows.first.readTable(_db.wallets);
      final txList = rows
          .map((r) => r.readTableOrNull(_db.transactions))
          .whereType<TransactionEntry>()
          .toList();
      return _computeBalanceFromList(wallet, txList);
    });
  }

  /// Memantau seluruh dompet beserta saldo terkininya setiap ada perubahan dompet atau transaksi.
  Stream<List<WalletWithBalance>> watchAllWalletsWithBalance() {
    final query = _db.select(_db.wallets).join([
      leftOuterJoin(
        _db.transactions,
        _db.transactions.walletId.equalsExp(_db.wallets.id) |
            _db.transactions.toWalletId.equalsExp(_db.wallets.id),
      ),
    ]);

    return query.watch().map((rows) {
      final walletMap = <int, Wallet>{};
      final txMap = <int, TransactionEntry>{};

      for (final row in rows) {
        final wallet = row.readTable(_db.wallets);
        walletMap[wallet.id] = wallet;

        final tx = row.readTableOrNull(_db.transactions);
        if (tx != null) {
          txMap[tx.id] = tx;
        }
      }

      final allTx = txMap.values.toList();
      return walletMap.values.map((w) {
        final balance = _computeBalanceFromList(w, allTx);
        return WalletWithBalance(wallet: w, currentBalance: balance);
      }).toList();
    });
  }

  int _computeBalanceFromList(
    Wallet wallet,
    Iterable<TransactionEntry> transactions,
  ) {
    var balance = wallet.initialBalance;

    for (final tx in transactions) {
      if (tx.type == TransactionTypes.income && tx.walletId == wallet.id) {
        balance += tx.amount;
      } else if (tx.type == TransactionTypes.expense &&
          tx.walletId == wallet.id) {
        balance -= tx.amount;
      } else if (tx.type == TransactionTypes.transfer) {
        if (tx.walletId == wallet.id) {
          balance -= tx.amount;
        }
        if (tx.toWalletId == wallet.id) {
          balance += tx.amount;
        }
      }
    }

    return balance;
  }

  // --- Perhitungan Total Pemasukan & Pengeluaran per Bulan ---

  /// Menghitung total pemasukan dan pengeluaran pada tahun dan bulan tertentu.
  /// Transaksi transfer antar dompet tidak dihitung sebagai pemasukan/pengeluaran.
  Future<MonthlySummary> getMonthlySummary(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final startOfNextMonth = DateTime(year, month + 1, 1);

    final monthlyTx = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startOfMonth) &
                t.date.isSmallerThanValue(startOfNextMonth),
          ))
        .get();

    return _computeMonthlySummary(monthlyTx);
  }

  /// Memantau total pemasukan dan pengeluaran bulanan secara reaktif.
  Stream<MonthlySummary> watchMonthlySummary(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final startOfNextMonth = DateTime(year, month + 1, 1);

    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startOfMonth) &
                t.date.isSmallerThanValue(startOfNextMonth),
          ))
        .watch()
        .map(_computeMonthlySummary);
  }

  /// Menghitung total nominal per kategori utama (induk) pada bulan tertentu.
  /// Transaksi yang memakai subkategori otomatis dijumlahkan ke kategori induknya.
  Future<Map<int, int>> getMonthlyTotalsByParentCategory(
    int year,
    int month, {
    String type = TransactionTypes.expense,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final startOfNextMonth = DateTime(year, month + 1, 1);

    final monthlyTx = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.type.equals(type) &
                t.date.isBiggerOrEqualValue(startOfMonth) &
                t.date.isSmallerThanValue(startOfNextMonth),
          ))
        .get();
    final categories = await getAllCategories();
    final catById = {for (final c in categories) c.id: c};

    final totals = <int, int>{};
    for (final tx in monthlyTx) {
      if (tx.categoryId == null) continue;
      final parentId = resolveParentCategoryId(tx.categoryId!, catById);
      totals[parentId] = (totals[parentId] ?? 0) + tx.amount;
    }
    return totals;
  }

  MonthlySummary _computeMonthlySummary(Iterable<TransactionEntry> txList) {
    var income = 0;
    var expense = 0;

    for (final tx in txList) {
      if (tx.type == TransactionTypes.income) {
        income += tx.amount;
      } else if (tx.type == TransactionTypes.expense) {
        expense += tx.amount;
      }
    }

    return MonthlySummary(totalIncome: income, totalExpense: expense);
  }

  // --- Laporan Harian (Daily Report) ---

  /// Menghitung ringkasan transaksi pada satu tanggal tertentu (00:00 hingga 23:59:59).
  /// Digunakan oleh background worker Workmanager maupun pratinjau laporan harian.
  Future<DailyReportSummary> getDailyReportSummary(DateTime targetDate) async {
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final dayTransactions = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startOfDay) &
                t.date.isSmallerThanValue(startOfNextDay),
          ))
        .get();

    final categories = await getAllCategories();
    return _computeDailySummary(startOfDay, dayTransactions, categories);
  }

  /// Memantau ringkasan transaksi harian secara reaktif.
  Stream<DailyReportSummary> watchDailyReportSummary(DateTime targetDate) {
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final txQuery = (_db.select(_db.transactions)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(startOfDay) &
            t.date.isSmallerThanValue(startOfNextDay),
      ));

    return txQuery.watch().asyncMap((txList) async {
      final categories = await getAllCategories();
      return _computeDailySummary(startOfDay, txList, categories);
    });
  }

  DailyReportSummary _computeDailySummary(
    DateTime day,
    Iterable<TransactionEntry> txList,
    Iterable<Category> categories,
  ) {
    final catById = {for (final c in categories) c.id: c};

    var totalExpense = 0;
    var totalIncome = 0;
    var count = 0;

    // Menyimpan frekuensi dan total nominal per kategori utama (subkategori dijumlahkan ke induknya).
    final categoryCount = <int, int>{};
    final categoryAmount = <int, int>{};

    for (final tx in txList) {
      if (tx.type == TransactionTypes.expense) {
        totalExpense += tx.amount;
        count++;
        if (tx.categoryId != null) {
          final parentId = resolveParentCategoryId(tx.categoryId!, catById);
          categoryCount[parentId] = (categoryCount[parentId] ?? 0) + 1;
          categoryAmount[parentId] =
              (categoryAmount[parentId] ?? 0) + tx.amount;
        }
      } else if (tx.type == TransactionTypes.income) {
        totalIncome += tx.amount;
        count++;
        if (tx.categoryId != null && totalExpense == 0) {
          final parentId = resolveParentCategoryId(tx.categoryId!, catById);
          categoryCount[parentId] = (categoryCount[parentId] ?? 0) + 1;
          categoryAmount[parentId] =
              (categoryAmount[parentId] ?? 0) + tx.amount;
        }
      }
    }

    String? topCategoryName;
    if (categoryCount.isNotEmpty) {
      int? bestCategoryId;
      for (final cid in categoryCount.keys) {
        if (bestCategoryId == null) {
          bestCategoryId = cid;
          continue;
        }
        final currentCount = categoryCount[cid]!;
        final bestCount = categoryCount[bestCategoryId]!;
        if (currentCount > bestCount ||
            (currentCount == bestCount &&
                (categoryAmount[cid] ?? 0) >
                    (categoryAmount[bestCategoryId] ?? 0))) {
          bestCategoryId = cid;
        }
      }
      if (bestCategoryId != null) {
        topCategoryName = catById[bestCategoryId]?.name;
      }
    }

    return DailyReportSummary(
      date: day,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      transactionCount: count,
      topCategoryName: topCategoryName,
    );
  }
}
