import 'package:flutter/material.dart';

/// Palet warna utama MyWallet dengan tema terang (Light Fintech).
/// Seluruh token warna dipusatkan di sini agar konsisten di seluruh komponen.
class AppColors {
  AppColors._();

  // Warna latar dan permukaan kartu
  static const Color bg = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  // Warna utama dan gradien kartu dompet
  static const Color primary = Color(0xFF10B981);
  static const Color cardGradientStart = Color(0xFF10B981);
  static const Color cardGradientEnd = Color(0xFF0D9488);

  // Warna tab pill aktif dan aksen tautan
  static const Color activeTabPill = Color(0xFFD9F99D);
  static const Color accentLink = Color(0xFFF59E0B);
  static const Color accentLinkText = Color(0xFFD97706);

  // Warna latar ikon pastel untuk grid fitur dan kategori
  static const Color pastelMint = Color(0xFFD1FAE5);
  static const Color pastelIndigo = Color(0xFFE0E7FF);
  static const Color pastelOrange = Color(0xFFFFEDD5);
  static const Color pastelSky = Color(0xFFE0F2FE);

  // Warna semantik transaksi dan status
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFF43F5E);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color warning = Color(0xFFF59E0B);

  // Warna teks dan tombol melayang (floating pill)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color floatingPill = Color(0xFF0F172A);

  // Daftar warna pastel berurutan untuk variasi latar ikon
  static const List<Color> pastelPalette = [
    pastelMint,
    pastelSky,
    pastelOrange,
    pastelIndigo,
  ];
}
