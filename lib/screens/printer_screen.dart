import 'package:flutter/material.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _purpleAccent = Color(0xFF9333EA);
  static const Color _textBlack = Color(0xFF111827);

  bool _isSearching = false;
  String? _connectedDevice;

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
              title: const Text('Printer Bluetooth', style: TextStyle(color: _textBlack, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.print_rounded, color: _purpleAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status Printer', style: TextStyle(fontSize: 10, color: Colors.black45)),
                              Text(
                                _connectedDevice ?? 'Belum Terhubung',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _connectedDevice != null ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('PERANGKAT TERSEDIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          _isSearching ? 'Mencari printer Bluetooth...' : 'Tekan "Cari Printer" untuk memindai.',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 18),
                      label: const Text('Cari Printer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() => _isSearching = !_isSearching);
                      },
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
}
