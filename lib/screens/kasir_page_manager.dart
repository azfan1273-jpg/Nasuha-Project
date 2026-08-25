import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Jangan lupa install url_launcher
import '../providers/settings_provider.dart';
import 'kasir_home_screen.dart';
import 'layar_statistik.dart';

import 'owner_screen.dart';
import 'kasir_screen.dart';
import 'kelola_layanan_screen.dart';
import 'parfum_screen.dart';
import 'cari_pelanggan_screen.dart';
import 'printer_screen.dart';
import 'report_screen.dart';

class KasirPageManager extends StatefulWidget {
  const KasirPageManager({Key? key}) : super(key: key);

  @override
  State<KasirPageManager> createState() => _KasirPageManagerState();
}

class _KasirPageManagerState extends State<KasirPageManager> {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<KasirHomeScreenState> _kasirHomeKey = GlobalKey<KasirHomeScreenState>();

  // State untuk Broadcast Announcement dari Developer
  Map<String, dynamic>? _announcement;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsProvider>().fetchStoreId();
        _fetchDeveloperAnnouncement();
      }
    });
  }

  // 📡 METODE TARIK PENGUMUMAN DEV DARI SUPABASE
  Future<void> _fetchDeveloperAnnouncement() async {
    try {
      final res = await Supabase.instance.client
          .from('app_announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

        print('📡 Data Pengumuman: $res'); // Cek di terminal Flutter kamu

      if (res != null && mounted) {
        setState(() {
          _announcement = res;
        });
      }
    } catch (e) {
      print('❌ Error Pengumuman: $e');// Handle silently jika tabel belum dibuat
    }
  }

  // 🔗 METODE BUKA LINK OUTSIDE APP
  Future<void> _openAnnouncementUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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

    // 1. NAMA TOKO: Fallback diubah menjadi 'Nama Toko'
    final String namaTokoReal = settings.namaToko.isEmpty
        ? 'Nama Toko'
        : settings.namaToko;

    return Scaffold(
      backgroundColor: creamLightColor,
      drawer: _buildCustomSidebar(context, settings, emailReal, namaTokoReal),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // HEADER TOKO
            _buildTokoHeader(
              namaToko: namaTokoReal,
              userRole: settings.userRole,
              emailToko: emailReal,
              onRefresh: () {
                _kasirHomeKey.currentState?.refreshData();
                _fetchDeveloperAnnouncement();
              },
            ),
            const SizedBox(height: 6),

            // 2. BANNER PENGUMUMAN BROADCAST DEV (Dinamis + Link Clickable)
            if (_announcement != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildBannerAnnouncement(settings),
              ),
            const SizedBox(height: 8),

            // 3. TAB BAR NAVIGASI (Mentok Kiri)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTabButton(0, 'Beranda Kasir', Icons.home_rounded, goldAccent),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Order Status', Icons.bar_chart_rounded, goldAccent),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 4. HALAMAN UTAMA
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

  // WIDGET BANNER BROADCAST DEV
  Widget _buildBannerAnnouncement(SettingsProvider settings) {
    final title = _announcement?['title'] ?? 'Pengumuman Aplikasi';
    final subtitle = _announcement?['subtitle'] ?? 'Klik untuk info selengkapnya';
    final linkUrl = _announcement?['link_url'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: linkUrl.isNotEmpty ? () => _openAnnouncementUrl(linkUrl) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: settings.cardDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: settings.accentColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: settings.accentColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: settings.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: settings.accentColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  children: [
                    Text(
                      'INFO',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.open_in_new_rounded, size: 9, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER TOKO
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
          colors: [Color(0xFFFFF59D), Color(0xFFF8BBD0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCE7F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFEC4899), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              namaToko, // 🟢 Tampil 'Nama Toko' jika data belum terisi
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              userRole.isEmpty ? 'KASIR' : userRole.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        emailToko,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 11),
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

  // TAB BUTTON
  Widget _buildTabButton(int index, String title, IconData icon, Color activeColor) {
    final isSelected = _currentIndex == index;
    return Material(
      color: Colors.transparent,
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
              Icon(icon, size: 18, color: isSelected ? activeColor : Colors.grey),
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

  // SIDEBAR DRAWER (Sesuai kode kamu)
  Widget _buildCustomSidebar(BuildContext context, SettingsProvider settings, String email, String namaToko) {
    const Color bgPink = Color(0xFFFFF1F2);
    const Color textDark = Color(0xFF1E293B);

    return Drawer(
      backgroundColor: bgPink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEC4899), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                settings.userRole.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildSidebarItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.badge_outlined,
                    title: 'Kelola Kasir',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KasirScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.local_laundry_service_outlined,
                    title: 'Daftar Layanan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KelolaLayananScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.groups_outlined,
                    title: 'Daftar Pelanggan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CariPelangganScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.opacity_outlined,
                    title: 'Daftar Parfum',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParfumScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Pengaturan Diskon',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildSectionDivider(),
                  _buildSidebarItem(
                    icon: Icons.print_outlined,
                    title: 'Connect Printer',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterScreen()));
                    },
                  ),
                  _buildSectionDivider(),
                  _buildSidebarItem(
                    icon: Icons.assessment_outlined,
                    title: 'Laporan Keuangan',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const ReportScreen());
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
          horizontalTitleGap: 12,
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
    );
  }
}
