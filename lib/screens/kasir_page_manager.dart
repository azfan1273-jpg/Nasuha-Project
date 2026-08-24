import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';
import 'kasir_home_screen.dart';
import 'layar_statistik.dart';
import 'login_screen.dart';

// Import file screen & widget tujuan
import 'owner_screen.dart';          // Profil Toko[cite: 2]
import 'kasir_screen.dart';          // Kelola Kasir[cite: 2]
import 'kelola_layanan_screen.dart'; // Daftar Layanan[cite: 2]
import 'parfum_screen.dart';         // Daftar Parfum[cite: 2]
import 'cari_pelanggan_screen.dart'; // Daftar Pelanggan[cite: 2]
import 'printer_screen.dart';        // Printer Bluetooth[cite: 2]
import 'report_screen.dart';         // Laporan Keuangan[cite: 2, 3]

class KasirPageManager extends StatefulWidget {
  const KasirPageManager({Key? key}) : super(key: key);

  @override
  State<KasirPageManager> createState() => _KasirPageManagerState();
}

class _KasirPageManagerState extends State<KasirPageManager> {
  late PageController _pageController;
  int _currentIndex = 0;

  // Buat GlobalKey untuk mengakses State KasirHomeScreen
    final GlobalKey<KasirHomeScreenState> _kasirHomeKey = GlobalKey<KasirHomeScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  
    // 👈 Tambahkan ini agar saat pertama masuk/login, settings & session dipaksa refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
      	// Ambil store_id user yang sedang login
      	context.read<SettingsProvider>().fetchStoreId();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }
  
  		@override
	    Widget build(BuildContext context) {
	      const Color creamLightColor = Color(0xFFFAF5F7);
	      const Color goldAccent = Color(0xFFEC4899);
	      final settings = context.watch<SettingsProvider>();
	    
	      final currentUser = Supabase.instance.client.auth.currentUser;
	      final String emailReal = currentUser?.email ?? 'Belum Login';
	      final String namaTokoReal = settings.namaToko.isEmpty
	          ? 'NASUHA LAUNDRY'
	          : settings.namaToko;
	    
	      return Scaffold(
	        backgroundColor: creamLightColor,
	        drawer: _buildCustomSidebar(context, settings, emailReal, namaTokoReal), // 🔹 1. TAMBAHKAN DRAWER DI SINI
	        body: SafeArea(
	          child: Column(
	            children: [
	              const SizedBox(height: 6),
	    
	              // 1. HEADER TOKO GRADASI (Kepala Utama)
	              _buildTokoHeader(
	                namaToko: namaTokoReal,
	                userRole: settings.userRole,
	                emailToko: emailReal,
	                onRefresh: () {
	                  _kasirHomeKey.currentState?.refreshData();
	                },
	              ),
	              const SizedBox(height: 6),
	    
	              // 2. BANNER PROMO
	              Padding(
	                padding: const EdgeInsets.symmetric(horizontal: 12),
	                child: _buildBannerPromo(settings),
	              ),
	              const SizedBox(height: 8),
	    
	              // 3. TAB BAR NAVIGASI
	              Container(
	                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
	                child: Row(
	                  mainAxisAlignment: MainAxisAlignment.center,
	                  children: [
	                    _buildTabButton(0, 'Beranda Kasir', Icons.home_rounded, goldAccent),
	                    const SizedBox(width: 12),
	                    _buildTabButton(1, 'Laporan & Statistik', Icons.bar_chart_rounded, goldAccent),
	                  ],
	                ),
	              ),
	              const SizedBox(height: 6),
	    
	              // 4. HALAMAN UTAMA (PageView di paling bawah)
	              Expanded(
	                child: PageView(
	                  controller: _pageController,
	                  onPageChanged: _onPageChanged,
	                  children: [
	                    Material(
	                      color: Colors.transparent,
	                      child: KasirHomeScreen(key: _kasirHomeKey),
	                    ),
	                    const Material(
	                      color: Colors.transparent,
	                      child: LayarStatistik(),
	                    ),
	                  ],
	                ),
	              ),
	            ],
	          ),
	        ),
	      );
	    }

  Widget _buildCustomSidebar(
    BuildContext context, 
    SettingsProvider settings, 
    String email, 
    String namaToko,
  ) {
    const Color bgPink = Color(0xFFFFF1F2); // Pink sangat lembut (Clean Modern)
    const Color textDark = Color(0xFF1E293B);
  
    return Drawer(
      backgroundColor: bgPink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. HEADER PROFIL TOKO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFEC4899), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                namaToko,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                settings.userRole.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
  
            // 2. DAFTAR MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildSidebarItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerScreen())); //[cite: 2]
                    },
                  ),
                  
                  // 2. Kelola Kasir
                  _buildSidebarItem(
                    icon: Icons.badge_outlined,
                    title: 'Kelola Kasir',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KasirScreen())); //[cite: 2]
                    },
                  ),
                  
                  // 3. Kelola Layanan
                  _buildSidebarItem(
                    icon: Icons.local_laundry_service_outlined,
                    title: 'Daftar Layanan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KelolaLayananScreen())); //[cite: 2]
                    },
                  ),
                  
                  // 4. Kelola Pelanggan
                  _buildSidebarItem(
                    icon: Icons.groups_outlined,
                    title: 'Daftar Pelanggan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CariPelangganScreen())); //[cite: 2]
                    },
                  ),
                  
                  // 5. Kelola Parfum
                  _buildSidebarItem(
                    icon: Icons.opacity_outlined,
                    title: 'Daftar Parfum',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParfumScreen())); //[cite: 2]
                    },
                  ),
                  
                  _buildSidebarItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Pengaturan Diskon',
                    onTap: () => Navigator.pop(context),
                  ),
  
                  _buildSectionDivider(),
  
                  // 6. Connect Printer
                  _buildSidebarItem(
                    icon: Icons.print_outlined,
                    title: 'Connect Printer',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterScreen())); //[cite: 2]
                    },
                  ),
  
                  _buildSectionDivider(),
  
                  // 7. Laporan Keuangan (Modal Pop-up dialog style)
                  _buildSidebarItem(
                    icon: Icons.assessment_outlined,
                    title: 'Laporan Keuangan',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const ReportScreen(), //
                      );
                    },
                  ),
                  
                  _buildSidebarItem(
                    icon: Icons.analytics_outlined,
                    title: 'Analisis Pelanggan',
                    onTap: () => Navigator.pop(context),
                  ),
  
                  _buildSectionDivider(),
  
                  _buildSidebarItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Premium Akun',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildSidebarItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
  
            // 3. LOGOUT BUTTON
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildSidebarItem(
                icon: Icons.logout_rounded,
                title: 'LogOut Akun',
                textColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // HELPER WIDGET ITEM SIDEBAR DENGAN HOVER & SPASING RAPI
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF334155),
    Color iconColor = const Color(0xFF64748B),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          horizontalTitleGap: 12, // 🔹 Memberikan jarak spasi yang pas antara ikon & teks
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600, // 🔹 Teks tebal & tegak (bukan miring)
              color: textColor,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
  
  // HELPER PEMBATAS SEKSI MENU
  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
    );
  }

  // HELPER WIDGET 1: Header Toko dengan Gradasi Warna
  Widget _buildTokoHeader({
    required String namaToko,
    required String userRole,
    required String emailToko,
    required VoidCallback onRefresh,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF59D), // Yellow / Kuning lembut
            Color(0xFFF8BBD0), // Pink lembut
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // 👈 Tambahkan Expanded di sini agar teks panjang/null tidak bikin overflow/hilang
            child: Row(
              children: [
                Container(
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(), // 🔹 Klik logo toko untuk membuka Drawer
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCE7F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFEC4899),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible( // 👈 Pake Flexible supaya teks nama toko aman dari error layout
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              namaToko.isEmpty ? 'NASUHA LAUNDRY' : namaToko,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              userRole.isEmpty ? 'KASIR' : userRole.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        emailToko.isEmpty ? 'kasir@nasuha.com' : emailToko,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF111827)),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET 2: Banner Promo
  Widget _buildBannerPromo(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: settings.cardDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                color: settings.accentColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promo Cuci Komplit Diskon 10%',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: settings.accentColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Berlaku sampai akhir bulan.',
                    style: TextStyle(
                      fontSize: 7.5,
                      color: settings.textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: settings.accentColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET 3: Tombol Tab
  Widget _buildTabButton(int index, String title, IconData icon, Color activeColor) {
  final isSelected = _currentIndex == index;

  // 🔴 BUNGKUS DENGAN MATERIAL DI SINI
  return Material(
    color: Colors.transparent, // Agar background Container di bawahnya tetap kelihatan
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _currentIndex = index;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
