import 'package:flutter/material.dart';
import '../screens/report_screen.dart';
import 'kelola_layanan_screen.dart';
import 'parfum_screen.dart';
import 'printer_screen.dart';
import 'kasir_screen.dart';
import 'owner_screen.dart';
import 'cari_pelanggan_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _textBlack = Color(0xFF111827);

  Widget _buildSquareCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textBlack),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textBlack),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: Scaffold(
            backgroundColor: _bgDark,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Pengaturan Aplikasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textBlack),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
					  // KATEGORI 1: TOKO & AKUN
					  const Text(
					    'TOKO & AKUN',
					    style: TextStyle(
					      fontSize: 10,
					      fontWeight: FontWeight.bold,
					      color: Colors.black45,
					      letterSpacing: 0.5,
					    ),
					  ),
					  const SizedBox(height: 8),
					  Row(
					    children: [
					      Expanded(
					        child: _buildSquareCard(
					          title: 'Profil Toko',
					          subtitle: 'Nama & Alamat',
					          icon: Icons.storefront_rounded,
					          iconBg: const Color(0xFFE0F2FE),
					          iconColor: const Color(0xFF0284C7),
					          onTap: () {
					            Navigator.push(
					              context,
					              MaterialPageRoute(builder: (context) => const OwnerScreen()),
					            );
					          },
					        ),
					      ),
					      const SizedBox(width: 10),
					      Expanded(
					        child: _buildSquareCard(
					          title: 'Kelola Kasir',
					          subtitle: 'Akun & Akses Kasir',
					          icon: Icons.badge_rounded,
					          iconBg: const Color(0xFFFEF3C7),
					          iconColor: const Color(0xFFD97706),
					          onTap: () {
					            Navigator.push(
					              context,
					              MaterialPageRoute(builder: (context) => const KasirScreen()),
					            );
					          },
					        ),
					      ),
					    ],
					  ),

					  const SizedBox(height: 18),

					  // KATEGORI 2: KATALOG & OPERASIONAL
					  const Text(
					    'KATALOG & OPERASIONAL',
					    style: TextStyle(
					      fontSize: 10,
					      fontWeight: FontWeight.bold,
					      color: Colors.black45,
					      letterSpacing: 0.5,
					    ),
					  ),
					  const SizedBox(height: 8),
					  Row(
					    children: [
					      Expanded(
					        child: _buildSquareCard(
					          title: 'Kelola Layanan',
					          subtitle: 'Tarif & Paket',
					          icon: Icons.dry_cleaning_rounded,
					          iconBg: const Color(0xFFFCE7F3),
					          iconColor: const Color(0xFFEC4899),
					          onTap: () {
					            Navigator.push(
					              context,
					              MaterialPageRoute(builder: (context) => const KelolaLayananScreen()),
					            );
					          },
					        ),
					      ),
					      const SizedBox(width: 10),
					      Expanded(
					        child: _buildSquareCard(
					          title: 'Kelola Parfum',
					          subtitle: 'Aroma Aktif',
					          icon: Icons.local_florist_rounded,
					          iconBg: const Color(0xFFFFF3E0),
					          iconColor: const Color(0xFFFF9200),
					          onTap: () {
					            Navigator.push(
					              context,
					              MaterialPageRoute(builder: (context) => const ParfumScreen()),
					            );
					          },
					        ),
					      ),
					    ],
					  ),
					  const SizedBox(height: 10),
					  _buildWideCard(
					    title: 'Kelola Pelanggan',
					    subtitle: 'Database Member & Transaksi',
					    icon: Icons.people_alt_rounded,
					    iconBg: const Color(0xFFDCFCE7),
					    iconColor: const Color(0xFF16A34A),
					    onTap: () {
					      Navigator.push(
					        context,
					        MaterialPageRoute(builder: (context) => const CariPelangganScreen()),
					      );
					    },
					  ),
					  const SizedBox(height: 10),

					  // 🔹 PRINTER BLUETOOTH DIPINDAHKAN KE SINI (DI BAWAH PELANGGAN)
					  _buildWideCard(
					    title: 'Printer Bluetooth',
					    subtitle: 'Koneksi & Cetak Struk',
					    icon: Icons.print_rounded,
					    iconBg: const Color(0xFFF3E8FF),
					    iconColor: const Color(0xFF9333EA),
					    onTap: () {
					      Navigator.push(
					        context,
					        MaterialPageRoute(builder: (context) => const PrinterScreen()),
					      );
					    },
					  ),
					],               
			      ),
	            ),
	          ),
	        ),
	      ),
	    ),
	  );
    }
  }
