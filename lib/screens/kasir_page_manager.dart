import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';
import 'kasir_home_screen.dart';
import 'layar_statistik.dart';

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

    // Ambil data user yang sedang login dari Supabase Auth
        final currentUser = Supabase.instance.client.auth.currentUser;
        final String emailReal = currentUser?.email ?? 'Belum Login';
        final String namaTokoReal = settings.namaToko.isEmpty 
            ? 'NASUHA LAUNDRY' 
            : settings.namaToko;

    return Scaffold(
      backgroundColor: creamLightColor, // Background luar (samping)
      body: SafeArea(         
              child: Column(
                children: [
                
                  const SizedBox(height: 6),

                  // 1. HEADER TOKO GRADASI
                  _buildTokoHeader(
                    namaToko: namaTokoReal,
                    userRole: settings.userRole,
                    emailToko: emailReal, // <-- Menggunakan email real dari Supabase Auth
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

                  // 3. TAB BAR NAVIGASI (Di bawah Banner)
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

                  // 4. HALAMAN UTAMA (PageView)
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [
                        KasirHomeScreen(key: _kasirHomeKey),
                        const LayarStatistik(),
                      ],
                    ),
                  ),
                ],
              ),
            ),  
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
          Row(
            children: [
              Container(
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
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        namaToko,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          userRole.toUpperCase(),
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
                    emailToko,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
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
  Widget _buildTabButton(int index, String label, IconData icon, Color activeColor) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
