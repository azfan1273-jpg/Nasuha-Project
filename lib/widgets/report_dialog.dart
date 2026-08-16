import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  int _selectedTab = 0; // 0: Omset, 1: Pendapatan, 2: Pengeluaran, 3: Net Cash

  static const Color _bgSoft = Color(0xFFFAF5F7); // Warna dasar sama dengan Setting
    static const Color _cardBg = Colors.white;
    static const Color _borderPink = Color(0xFFFCE7F3);
    static const Color _pinkAccent = Color(0xFFEC4899);
    static const Color _textDark = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420, // Kunci lebar selayaknya layar HP
          maxHeight: screenHeight * 0.98,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5F7), // Warna soft gray-pink persis Setting
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  // 1. HEADER TOPOK & TOMBOL CLOSE
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: const [
                            Text(
                              'LAPORAN & STATISTIK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: _textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Nasuha Laundry.Superadmin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close_rounded, color: Colors.black54, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // SEPARATOR DEKORATIF (DOTTED + ARROWS & DIAMOND)
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.maxWidth / 7).floor(),
                                (_) => Container(width: 4, height: 2, color: Colors.purple.shade700),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.purple.shade900),
                            const SizedBox(width: 2),
                            Transform.rotate(
                              angle: 0.785398, // Rotasi 45 Derajat (Bentuk Diamond)
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF9333EA), Color(0xFFF59E0B)],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_back_ios_rounded, size: 10, color: Colors.purple.shade900),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.maxWidth / 7).floor(),
                                (_) => Container(width: 4, height: 2, color: Colors.purple.shade700),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. KARTU OMSET HARI INI & OMSET TOTAL
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Omset Hari ini',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rp. 125.000',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Omset Total',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rp. 45.100.000',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. TITLE JUDUL TAB & IKON GRAFIK POJOK KANAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 48.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTabTitle(_selectedTab),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.purple,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 4. SIDEBAR MENU IKON & KONTEN UTAMA PUTIH
                  Expanded(
                    child: Row(
                      children: [
                        // SIDEBAR MENU (KIRI)
                        Column(
                          children: [
                            _buildSidebarIcon(0, Icons.monetization_on_outlined),
                            const SizedBox(height: 10),
                            _buildSidebarIcon(1, Icons.payments_outlined),
                            const SizedBox(height: 10),
                            _buildSidebarIcon(2, Icons.trending_down_rounded),
                            const SizedBox(height: 10),
                            _buildSidebarIcon(3, Icons.account_balance_wallet_outlined),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // KONTEN UTAMA (KANAN)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Text(
                                  'Area ${_getTabTitle(_selectedTab)}',
                                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. FOOTER (EXPORT TO EXCEL & TOTAL)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA3E635), // Hijau Neon Soft sesuai SS
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Tambahkan fungsi export excel di sini nanti
                        },
                        child: const Text(
                          'EXPORT TO EXCEL',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TOTAL : Rp. 500.000',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Laporan Omset';
      case 1:
        return 'Laporan Pendapatan';
      case 2:
        return 'Laporan Pengeluaran';
      case 3:
        return 'Piutang';
      default:
        return 'Laporan Omset';
    }
  }

  Widget _buildSidebarIcon(int index, IconData icon) {
    final bool isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black87,
          size: 22,
        ),
      ),
    );
  }
}
