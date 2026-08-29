import 'dart:math' as math;
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  
  import '../providers/settings_provider.dart';
  import 'kasir_page_manager.dart';
  import 'login_screen.dart';
  
  // final supabase = Supabase.instance.client;
  
  
  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});
  
    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }
  
  class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
  
    @override
    void initState() {
      super.initState();
  
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true);
  
      _checkAuthAndNavigate();
    }
  
    Future<void> _checkAuthAndNavigate() async {
      // 🟢 1. TUNGGU ANIMASI MESIN CUCI SELAMA 3 DETIK
      await Future.delayed(const Duration(seconds: 3));
  
      if (!mounted) return;
  
      // 🟢 2. CEK SESSION SUPABASE
      final session = Supabase.instance.client.auth.currentSession;
  
      if (session == null) {
        // Jika belum login / habis logout -> Arahkan ke LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Jika sudah login -> Fetch store_id dulu baru ke KasirPageManager
        final settingsProvider = context.read<SettingsProvider>();
        if (settingsProvider.storeId == null) {
          await settingsProvider.fetchStoreId();
        }
  
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KasirPageManager()),
        );
      }
    }
  
    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F7), // Background senada dengan tema
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🟢 ANIMASI MESIN CUCI GOYANG
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Goyang rotasi halus sebesar -0.05 sampai 0.05 radian
                final double rotation = math.sin(_controller.value * math.pi) * 0.05;
                return Transform.rotate(
                  angle: rotation,
                  child: child,
                );
              },
              child: _buildFrontLoadingWashingMachine(),
            ),
            const SizedBox(height: 32),

            // 🟢 TULISAN JUDUL APLIKASI
            const Text(
              'LNDR',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC4899), // Warna pink khas
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Kasir Laundry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 WIDGET CUSTOM MESIN CUCI FRONT LOADING
  Widget _buildFrontLoadingWashingMachine() {
    return Container(
      width: 120,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEC4899), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol / Panel Atas
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEC4899),
                    shape: BoxShape.circle,
                  ),
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Pintu Mesin Cuci Front Loading (Lingkaran Kaca)
          Positioned(
            bottom: 16,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withOpacity(0.15),
                border: Border.all(color: const Color(0xFFEC4899), width: 3),
              ),
              child: Center(
                // Kaca/Air di dalam pintu
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(0.3),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
