import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/database/tables.dart';
import 'package:mywallet/core/database/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WalletRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'Seed data awal otomatis membuat dompet Tunai serta kategori utama dan subkategori baru',
      () async {
    final wallets = await repo.getAllWallets();
    expect(wallets.length, 1);
    expect(wallets.first.name, 'Tunai');

    final categories = await repo.getAllCategories();
    final mainExpense = categories
        .where((c) => c.type == CategoryTypes.expense && c.parentId == null)
        .toList();
    final mainIncome = categories
        .where((c) => c.type == CategoryTypes.income && c.parentId == null)
        .toList();

    expect(
      mainExpense.map((c) => c.name),
      containsAll(<String>[
        'Makanan & Minuman',
        'Belanja',
        'Tempat Tinggal',
        'Transportasi',
        'Kendaraan',
        'Gaya Hidup & Hiburan',
        'Komunikasi & PC',
        'Beban Keuangan',
        'Investasi',
        'Lainnya',
      ]),
    );
    expect(mainIncome.map((c) => c.name), equals(<String>['Pemasukan']));

    final foodParent =
        mainExpense.firstWhere((c) => c.name == 'Makanan & Minuman');
    final foodSubs =
        categories.where((c) => c.parentId == foodParent.id).toList();
    expect(
      foodSubs.map((c) => c.name),
      containsAll(<String>['Makan', 'Bahan makanan', 'Kafe & kopi', 'Jajan']),
    );
  });

  test(
      'Migrasi v1 ke v2 memindahkan transaksi kategori lama ke kategori baru dan menghapus kategori lama',
      () async {
    final migratedDb = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          // Siapkan skema versi 1 (tanpa kolom parent_id di categories)
          rawDb.execute('''
            CREATE TABLE wallets (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              initial_balance INTEGER NOT NULL DEFAULT 0,
              color_value INTEGER NOT NULL,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
            );
            CREATE TABLE categories (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              icon_code INTEGER NOT NULL,
              color_value INTEGER NOT NULL
            );
            CREATE TABLE transactions (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              wallet_id INTEGER NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
              category_id INTEGER NULL REFERENCES categories (id) ON DELETE SET NULL,
              type TEXT NOT NULL,
              amount INTEGER NOT NULL,
              note TEXT NULL,
              date INTEGER NOT NULL,
              to_wallet_id INTEGER NULL REFERENCES wallets (id) ON DELETE SET NULL
            );
            PRAGMA user_version = 1;
          ''');

          rawDb.execute(
            "INSERT INTO wallets (id, name, type, initial_balance, color_value) VALUES (1, 'Tunai', 'tunai', 0, 123);",
          );
          rawDb.execute('''
            INSERT INTO categories (id, name, type, icon_code, color_value) VALUES
              (1, 'Makan', 'expense', 100, 111),
              (2, 'Tagihan', 'expense', 101, 222),
              (3, 'Hiburan', 'expense', 102, 333),
              (4, 'Kesehatan', 'expense', 103, 444),
              (5, 'Gaji', 'income', 104, 555);
          ''');
          rawDb.execute('''
            INSERT INTO transactions (id, wallet_id, category_id, type, amount, note, date) VALUES
              (10, 1, 1, 'expense', 25000, 'Nasi padang', 1760000000),
              (11, 1, 2, 'expense', 150000, 'Bayar tagihan', 1760000100),
              (12, 1, 3, 'expense', 50000, 'Nonton bioskop', 1760000200),
              (13, 1, 4, 'expense', 80000, 'Vitamin', 1760000300),
              (14, 1, 5, 'income', 5000000, 'Gaji bulanan', 1760000400);
          ''');
        },
      ),
    );
    final migratedRepo = WalletRepository(migratedDb);

    final allTx = await migratedRepo.getAllTransactions();
    expect(allTx.length, 5);

    final allCats = await migratedRepo.getAllCategories();
    final catById = {for (final c in allCats) c.id: c};

    // Pastikan kategori lama (id 1..5) sudah dihapus
    for (final oldId in [1, 2, 3, 4, 5]) {
      expect(catById.containsKey(oldId), isFalse);
    }

    final txById = {for (final t in allTx) t.id: t};
    expect(catById[txById[10]!.categoryId]?.name, 'Makanan & Minuman');
    expect(catById[txById[11]!.categoryId]?.name, 'Beban Keuangan');
    expect(catById[txById[12]!.categoryId]?.name, 'Gaya Hidup & Hiburan');
    expect(catById[txById[13]!.categoryId]?.name, 'Lainnya');
    expect(catById[txById[14]!.categoryId]?.name, 'Pemasukan');

    await migratedDb.close();
  });

  test(
      'Subkategori dijumlahkan ke kategori utama pada laporan harian dan agregasi bulanan',
      () async {
    final targetDate = DateTime(2026, 10, 18);

    final wallets = await repo.getAllWallets();
    final cashId = wallets.first.id;
    final categories = await repo.getAllCategories();

    final foodParent = categories.firstWhere(
      (c) => c.name == 'Makanan & Minuman' && c.parentId == null,
    );
    final makanSub = categories.firstWhere(
      (c) => c.name == 'Makan' && c.parentId == foodParent.id,
    );
    final kopiSub = categories.firstWhere(
      (c) => c.name == 'Kafe & kopi' && c.parentId == foodParent.id,
    );

    await repo.insertTransaction(
      TransactionsCompanion.insert(
        walletId: cashId,
        categoryId: Value(makanSub.id),
        type: TransactionTypes.expense,
        amount: 75000,
        date: DateTime(2026, 10, 18, 9, 0),
      ),
    );
    await repo.insertTransaction(
      TransactionsCompanion.insert(
        walletId: cashId,
        categoryId: Value(kopiSub.id),
        type: TransactionTypes.expense,
        amount: 50000,
        date: DateTime(2026, 10, 18, 13, 0),
      ),
    );

    // Laporan harian menjumlahkan subkategori Makan + Kafe & kopi ke induk Makanan & Minuman
    final activeSummary = await repo.getDailyReportSummary(targetDate);
    expect(activeSummary.notificationTitle, 'Laporan 18 Oktober');
    expect(
      activeSummary.notificationBody,
      'Pengeluaran Rp 125.000 • Pemasukan Rp 0 • Transaksi terbanyak: Makanan & Minuman',
    );

    // Agregasi bulanan per kategori utama juga menjumlahkan ke induk Makanan & Minuman
    final monthlyByParent =
        await repo.getMonthlyTotalsByParentCategory(2026, 10);
    expect(monthlyByParent[foodParent.id], 125000);
  });
}
