import 'package:drift/drift.dart';

/// Konstanta tipe dompet agar konsisten di seluruh aplikasi.
class WalletTypes {
  WalletTypes._();
  static const String cash = 'tunai';
  static const String bank = 'bank';
  static const String eWallet = 'e-wallet';
}

/// Konstanta tipe kategori transaksi.
class CategoryTypes {
  CategoryTypes._();
  static const String income = 'income';
  static const String expense = 'expense';
}

/// Konstanta tipe transaksi.
class TransactionTypes {
  TransactionTypes._();
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';
}

/// Tabel daftar dompet (tunai, rekening bank, e-wallet).
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // 'tunai', 'bank', atau 'e-wallet'
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  IntColumn get colorValue => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Tabel kategori pemasukan dan pengeluaran (mendukung kategori utama & subkategori).
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // 'income' atau 'expense'
  IntColumn get iconCode => integer()();
  IntColumn get colorValue => integer()();

  // Bernilai null untuk kategori utama (induk), atau berisi id kategori induk untuk subkategori.
  IntColumn get parentId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.cascade)();
}

/// Tabel catatan transaksi (pemasukan, pengeluaran, dan transfer antar dompet).
/// Menggunakan @DataClassName('TransactionEntry') agar tidak bentrok dengan
/// class internal `Transaction` milik paket Drift.
@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Dompet asal transaksi (atau dompet sumber saat transfer).
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.cascade)();

  // Kategori bernilai null jika transaksi bertipe 'transfer'.
  IntColumn get categoryId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();

  // Tipe transaksi: 'income', 'expense', atau 'transfer'.
  TextColumn get type => text()();

  // Nominal disimpan sebagai integer (Rupiah penuh) untuk menghindari galat desimal floating-point.
  IntColumn get amount => integer()();

  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();

  // Dompet tujuan khusus untuk transaksi bertipe 'transfer'.
  @ReferenceName('incomingTransfers')
  IntColumn get toWalletId => integer()
      .nullable()
      .references(Wallets, #id, onDelete: KeyAction.setNull)();
}
