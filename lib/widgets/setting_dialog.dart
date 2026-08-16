import 'package:flutter/material.dart';
import 'kelola_owner_dialog.dart';
import 'kelola_kasir_dialog.dart';
import 'kelola_layanan_dialog.dart';
import 'kelola_parfum_dialog.dart';
import 'kelola_pelanggan_dialog.dart';
import 'kelola_printer_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Jika pakai Supabase
import '../screens/login_screen.dart'; // Arahkan ke file login kamu

class SettingDialog extends StatelessWidget {
  const SettingDialog({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // 1. Logout dari Supabase (jika menggunakannya)
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
  
              if (!context.mounted) return;
  
              // 2. Clear tumpukan layar & tendang langsung ke LoginScreen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()), // Sesuaikan nama class Login kamu
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.95,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5F7),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Scaffold(
              backgroundColor: const Color(0xFFFAF5F7),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                automaticallyImplyLeading: false,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setting & Kelola POS',
                      style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Nasuha Laundry • Superadmin',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KATEGORI 1: PENGGUNA
                    const Text(
                      'AKSES & PENGGUNA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSquareCard(
                            title: 'Kelola Owner',
                            subtitle: 'Profil & Hak Akses',
                            icon: Icons.admin_panel_settings_rounded,
                            iconBg: const Color(0xFFFCE7F3),
                            iconColor: const Color(0xFFEC4899),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const KelolaOwnerDialog(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSquareCard(
                            title: 'Kelola Kasir',
                            subtitle: '3 Akun Kasir Aktif',
                            icon: Icons.badge_rounded,
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0284C7),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const KelolaKasirDialog(),
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
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSquareCard(
                            title: 'Kelola Layanan',
                            subtitle: 'Tarif & Paket',
                            icon: Icons.dry_cleaning_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const KelolaLayananDialog(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSquareCard(
                            title: 'Kelola Parfum',
                            subtitle: '5 Aroma Aktif',
                            icon: Icons.local_florist_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const KelolaParfumDialog(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildWideCard(
                      title: 'Kelola Pelanggan',
                      subtitle: 'Database 128 Member & Transaksi',
                      icon: Icons.people_alt_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const KelolaPelangganDialog(),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // KATEGORI 3: PERANGKAT & SESI
                    const Text(
                      'HARDWARE & SESI',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildWideCard(
                      title: 'Kelola Printer',
                      subtitle: 'RPP02N Bluetooth (Terhubung 🟢)',
                      icon: Icons.print_rounded,
                      iconBg: const Color(0xFFFCE7F3),
                      iconColor: const Color(0xFFEC4899),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const KelolaPrinterDialog(),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // TOMBOL LOGOUT
                    InkWell(
                      onTap: () => _showLogoutConfirmation(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log Out / Keluar Sesi',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                                Text(
                                  'Keluar dari akun Nasuha Laundry',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF991B1B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSquareCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE7F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9.5, color: Colors.black45),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE7F3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
