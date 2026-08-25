import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _purpleAccent = Color(0xFF9333EA);
  static const Color _textBlack = Color(0xFF111827);

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
  }

  // 🔹 Cek apakah printer sudah terhubung sebelumnya
  Future<void> _checkCurrentConnection() async {
    bool? isConnected = await _bluetooth.isConnected;
    if (isConnected == true) {
      setState(() {
        _isConnected = true;
      });
    }
  }

  // 🔹 Trigger aktifkan Bluetooth & Cari perangkat paired
  Future<void> _scanDevices() async {
    setState(() => _isSearching = true);
    try {
      // Mengambil daftar perangkat Bluetooth yang sudah ter-pair di HP
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Error scan bluetooth: $e");
      setState(() => _isSearching = false);
    }
  }

  // 🔹 Hubungkan ke Printer yang dipilih
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      if (_isConnected) {
        await _bluetooth.disconnect();
      }
      await _bluetooth.connect(device);
      setState(() {
        _selectedDevice = device;
        _isConnected = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terhubung ke ${device.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal terhubung: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Card Status Printer
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
                          _isConnected
                              ? 'Terhubung (${_selectedDevice?.name ?? 'Printer Thermal'})'
                              : 'Belum Terhubung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
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

            // List Perangkat Bluetooth
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator(color: _purpleAccent))
                    : _devices.isEmpty
                        ? const Center(
                            child: Text(
                              'Tekan "Cari Printer" untuk memindai.',
                              style: TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _devices.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final isThisConnected = _selectedDevice?.address == device.address && _isConnected;

                              return ListTile(
                                leading: Icon(
                                  Icons.bluetooth_rounded,
                                  color: isThisConnected ? Colors.green : Colors.grey,
                                ),
                                title: Text(
                                  device.name ?? 'Perangkat Tak Dikenal',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  device.address ?? '',
                                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isThisConnected ? Colors.redAccent : _purpleAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _connectToDevice(device),
                                  child: Text(
                                    isThisConnected ? 'Putus' : 'Hubungkan',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Cari / Scan
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
                onPressed: _scanDevices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
