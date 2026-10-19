import 'package:flutter/material.dart';

/// Pemetaan kode ikon kategori ke konstanta IconData agar mendukung
/// tree-shaking font ikon Material pada saat kompilasi rilis.
class CategoryIconHelper {
  CategoryIconHelper._();

  /// Daftar konstanta IconData yang tersedia untuk kategori & pemilih ikon.
  static const List<IconData> availableIcons = [
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.directions_bus_rounded,
    Icons.directions_car_rounded,
    Icons.person_rounded,
    Icons.desktop_windows_rounded,
    Icons.monetization_on_rounded,
    Icons.hub_rounded,
    Icons.more_horiz_rounded,
    Icons.paid_rounded,
    Icons.payments_rounded,
    Icons.local_cafe_rounded,
    Icons.local_grocery_store_rounded,
    Icons.fastfood_rounded,
    Icons.checkroom_rounded,
    Icons.devices_rounded,
    Icons.medical_services_rounded,
    Icons.weekend_rounded,
    Icons.card_giftcard_rounded,
    Icons.bolt_rounded,
    Icons.water_drop_rounded,
    Icons.local_fire_department_rounded,
    Icons.pets_rounded,
    Icons.local_taxi_rounded,
    Icons.flight_takeoff_rounded,
    Icons.local_gas_station_rounded,
    Icons.local_parking_rounded,
    Icons.build_rounded,
    Icons.verified_user_rounded,
    Icons.receipt_long_rounded,
    Icons.fitness_center_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.beach_access_rounded,
    Icons.volunteer_activism_rounded,
    Icons.phone_android_rounded,
    Icons.wifi_rounded,
    Icons.apps_rounded,
    Icons.language_rounded,
    Icons.account_balance_rounded,
    Icons.percent_rounded,
    Icons.gavel_rounded,
    Icons.trending_up_rounded,
    Icons.pie_chart_rounded,
    Icons.diamond_rounded,
    Icons.currency_bitcoin_rounded,
    Icons.savings_rounded,
    Icons.storefront_rounded,
    Icons.add_circle_outline_rounded,
    Icons.category_rounded,
  ];

  /// Daftar pilihan warna solid untuk kategori di halaman Kelola Kategori.
  static const List<Color> availableColors = [
    Color(0xFFFF3D00), // Makanan & Minuman
    Color(0xFF4FC3F7), // Belanja
    Color(0xFFFFA726), // Tempat Tinggal
    Color(0xFF78909C), // Transportasi
    Color(0xFFAA00FF), // Kendaraan
    Color(0xFF64DD17), // Gaya Hidup & Hiburan
    Color(0xFF536DFE), // Komunikasi & PC
    Color(0xFF00BFA5), // Beban Keuangan
    Color(0xFFF50057), // Investasi
    Color(0xFFFFCA28), // Pemasukan
    Color(0xFF9E9E9E), // Lainnya
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Ungu
  ];

  static final Map<int, IconData> _iconMap = {
    for (final icon in availableIcons) icon.codePoint: icon,
  };

  /// Mengembalikan konstanta IconData berdasarkan codePoint yang tersimpan di database.
  static IconData fromCodePoint(int codePoint) {
    return _iconMap[codePoint] ?? Icons.category_rounded;
  }
}

/// Widget ikon kategori berbentuk lingkaran warna solid dengan ikon putih di tengah.
/// Digunakan secara konsisten di form transaksi, daftar transaksi, dan halaman Kelola Kategori.
class CategoryCircleIcon extends StatelessWidget {
  final int iconCode;
  final int colorValue;
  final double size;
  final double iconSize;

  const CategoryCircleIcon({
    super.key,
    required this.iconCode,
    required this.colorValue,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CategoryIconHelper.fromCodePoint(iconCode),
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
