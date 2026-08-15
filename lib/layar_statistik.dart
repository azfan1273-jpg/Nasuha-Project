// lib/layar_statistik.dart
// INI CONTOH LAYAR KEDUA (GAMBAR 2)

import 'package:flutter/material.dart';

class LayarStatistik extends StatelessWidget {
  const LayarStatistik({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema Nasuha
    const Color blushColor = Color(0xFFFCE7F3); // Pink Muda
    const Color darkColor = Color(0xFF374151); // Abu-abu gelap

    return Container(
      color: blushColor, // Warna background beda biar kelihatan bedanya
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ini Layar Statistik / Grafik (Gambar 2)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.bar_chart, size: 100, color: Colors.pinkAccent),
            ),
          ],
        ),
      ),
    );
  }
}
