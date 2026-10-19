import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/database/database_providers.dart';
import 'package:mywallet/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Pemilihan kategori utama + subkategori di form transaksi dan halaman Kelola Kategori berfungsi',
      (WidgetTester tester) async {
    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await inMemoryDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: const MyWalletApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Saat aplikasi pertama dibuka, dialog penjelasan izin notifikasi tampil.
    if (find.text('Izinkan Notifikasi Harian').evaluate().isNotEmpty) {
      await tester.tap(find.text('Izinkan'));
      await tester.pumpAndSettle();
    }

    // 2. Ketuk tombol melayang pill "Catat" di tengah bawah untuk menambah transaksi.
    await tester.tap(find.byTooltip('Catat Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.text('Makanan & Minuman'), findsOneWidget);

    // 3. Ketuk kategori utama "Makanan & Minuman" untuk membuka bottom sheet subkategori, lalu pilih "Kafe & kopi".
    await tester.ensureVisible(find.text('Makanan & Minuman'));
    await tester.tap(find.text('Makanan & Minuman'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih subkategori (opsional)'), findsOneWidget);
    expect(find.text('Kafe & kopi'), findsOneWidget);

    await tester.tap(find.text('Kafe & kopi'));
    await tester.pumpAndSettle();

    // 4. Masukkan nominal 35000 dan simpan pengeluaran.
    await tester.enterText(find.byType(TextField).first, '35000');
    await tester.pump();
    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle();

    // 5. Verifikasi transaksi tampil dengan subkategori "Kafe & kopi" di bawah header "Hari ini".
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Kafe & kopi'), findsOneWidget);
    expect(find.text('- Rp 35.000'), findsWidgets);

    // 6. Buka menu Lainnya -> Kelola Kategori, lalu buka "Makanan & Minuman" untuk melihat subkategorinya.
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Kategori'), findsOneWidget);

    await tester.tap(find.text('Kelola Kategori'));
    await tester.pumpAndSettle();
    expect(find.text('Makanan & Minuman'), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);

    await tester.tap(find.text('Makanan & Minuman'));
    await tester.pumpAndSettle();
    expect(find.text('Bahan makanan'), findsOneWidget);
    expect(find.text('Tambah Subkategori'), findsOneWidget);

    // Bersihkan pohon widget dan jalankan timer cleanup stream Drift.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
