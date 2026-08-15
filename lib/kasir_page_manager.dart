// lib/kasir_page_manager.dart

import 'package:flutter/material.dart';
import 'kasir_home_screen.dart'; // Impor layar HOME (Gambar 1)
// Masukkan impor untuk layar kedua di sini (Ganti dengan nama file sebenarnya nanti)
import 'layar_statistik.dart';    // Contoh: Layar kedua (Statistik/Grafik)

class KasirPageManager extends StatefulWidget {
  const KasirPageManager({Key? key}) : super(key: key);

  @override
  State<KasirPageManager> createState() => _KasirPageManagerState();
}

class _KasirPageManagerState extends State<KasirPageManager> {
  // Controller untuk mengendalikan PageView
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller, index dimulai dari 0 (KasirHomeScreen)
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose(); // Wajib di-dispose untuk cegah kebocoran memori
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema Nasuha
    const Color blushColor = Color(0xFFFCE7F3); // Pink Muda / Rose Blush
    const Color creamLightColor = Color(0xFFFAF5F7); // Krem Sangat Muda
    const Color darkColor = Color(0xFF374151); // Abu-abu gelap untuk teks

    return Scaffold(
      backgroundColor: creamLightColor,
      body: PageView(
        controller: _pageController, // Pasang controller
        children: [
          // ==========================================
          // LAYAR 1: HOME (KasirHomeScreen)
          // ==========================================
          // Ini adalah file yang sudah lu upload (Gambar 1)
          const KasirHomeScreen(),

          // ==========================================
          // LAYAR 2: (GANTI DENGAN KONTEN SEBENARNYA)
          // ==========================================
          // Ini adalah layar yang muncul saat digeser ke kiri (Gambar 2)
          // Untuk contoh, gue bikin container sederhana dulu.
          LayarStatistik(),
        ],
      ),
    );
  }
}
