import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';
import '../providers/order_provider.dart';
import '../helpers/database_helper.dart';
import 'cari_pelanggan_screen.dart';
import 'kasir_screen.dart';
import 'edit_layanan_screen.dart';
import 'owner_screen.dart';
import 'parfum_screen.dart';
import 'printer_screen.dart';
import 'splash_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  static const Color _bgLight = Color(0xFFF8F9FA);
  static const Color _textBlack = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Aplikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textBlack,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('TEMA APLIKASI'),
              _buildThemeSelector(context),

              const SizedBox(height: 20),

              _buildSectionHeader('TOKO & AKUN'),
              _buildModernTile(
                title: 'Profil Toko',
                subtitle: 'Nama, alamat, & informasi bisnis',
                icon: Icons.storefront_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerScreen(),
                    ),
                  );
                },
              ),
              _buildModernTile(
                title: 'Kelola Kasir',
                subtitle: 'Pengaturan akun & hak akses kasir',
                icon: Icons.badge_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KasirScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('KATALOG & OPERASIONAL'),
              _buildModernTile(
                title: 'Kelola Layanan',
                subtitle: 'Tarif & paket cuci',
                icon: Icons.dry_cleaning_rounded,
                iconBg: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFEC4899),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditLayananScreen(),
                    ),
                  );
                },
              ),
              _buildModernTile(
                title: 'Kelola Parfum',
                subtitle: 'Aroma parfum yang tersedia',
                icon: Icons.local_florist_rounded,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF9200),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParfumScreen(),
                    ),
                  );
                },
              ),
              _buildModernTile(
                title: 'Kelola Pelanggan',
                subtitle: 'Database member & riwayat',
                icon: Icons.people_alt_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CariPelangganScreen(),
                    ),
                  );
                },
              ),
              _buildModernTile(
                title: 'Printer Bluetooth',
                subtitle: 'Koneksi & pengaturan cetak struk',
                icon: Icons.print_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrinterScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('SISTEM & AKUN'),
              _buildLogoutTile(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildModernTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: _textBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showLogoutDialog(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
        ),
        title: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFFDC2626),
          ),
        ),
        subtitle: const Text(
          'Akhiri sesi dan kembali ke halaman login',
          style: TextStyle(fontSize: 10, color: Color(0xFFEF4444)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Color(0xFFFCA5A5),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              if (context.mounted) {
                context.read<SettingsProvider>().clearSettings();
                context.read<OrderProvider>().clearState();
              }

              await DatabaseHelper.instance.clearLocalOrders();
              await Supabase.instance.client.auth.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildThemeOption(
            context,
            color: const Color(0xFFEC4899),
            label: 'Pink Tema',
            mode: AppThemeMode.pink,
            isSelected: settings.currentTheme == AppThemeMode.pink,
          ),
          _buildThemeOption(
            context,
            color: const Color(0xFF0284C7),
            label: 'Dark Tema',
            mode: AppThemeMode.dark,
            isSelected: settings.currentTheme == AppThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required Color color,
    required String label,
    required AppThemeMode mode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => context.read<SettingsProvider>().setTheme(mode),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 14,
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _textBlack : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
