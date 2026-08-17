import 'package:flutter/material.dart';
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
  
    return Scaffold(
      backgroundColor: Colors.grey.shade900, // Background luar (samping kiri-kanan)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 385), // Lebar maksimal HP
          child: Container(
            color: creamLightColor,
            child: SafeArea(
              child: Column(
                children: [
                  // Indicator Tab Top Bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabButton(0, 'Beranda Kasir', Icons.home_rounded, goldAccent),
                        const SizedBox(width: 12),
                        _buildTabButton(1, 'Laporan & Statistik', Icons.bar_chart_rounded, goldAccent),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: const [
                        KasirHomeScreen(),
                        LayarStatistik(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
