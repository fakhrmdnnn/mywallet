import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utilitas pemformatan angka Rupiah dan tanggal berbahasa Indonesia (id_ID).
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _thousandFormat = NumberFormat.decimalPattern('id_ID');

  static final DateFormat _shortDateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dayMonthFormat = DateFormat('d MMMM', 'id_ID');
  static final DateFormat _dayHeaderFormat =
      DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final DateFormat _fullDateFormat =
      DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  /// Mengubah nominal integer menjadi string berformat "Rp 1.500.000".
  static String currency(int amount) => _rupiahFormat.format(amount);

  /// Mengubah nominal integer menjadi string ribuan tanpa simbol "1.500.000".
  static String thousand(int amount) => _thousandFormat.format(amount);

  /// Mengubah string berformat ribuan kembali menjadi integer murni.
  static int parseDigits(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return int.tryParse(digitsOnly) ?? 0;
  }

  /// Format tanggal ringkas, contoh: "19 Okt 2026".
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format tanggal dan bulan untuk judul laporan, contoh: "18 Oktober".
  static String dayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Format tanggal lengkap untuk pemilih tanggal, contoh: "Senin, 19 Oktober 2026".
  static String fullDate(DateTime date) => _fullDateFormat.format(date);

  /// Label header pengelompokan hari transaksi:
  /// "Hari ini", "Kemarin", atau "Jumat, 16 Okt 2026" untuk tanggal yang lebih lama.
  static String dayGroupHeader(DateTime date, {DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Hari ini';
    }
    if (target == yesterday) {
      return 'Kemarin';
    }
    return _dayHeaderFormat.format(target);
  }

  /// Format jam dan menit dua digit, contoh: "07:00".
  static String time24(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// TextInputFormatter agar ketikan nominal otomatis diberi titik pemisah ribuan (contoh: 1.500.000).
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final parsed = int.tryParse(digitsOnly);
    if (parsed == null) return oldValue;

    final formatted = AppFormatters.thousand(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
