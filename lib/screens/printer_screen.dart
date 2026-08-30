import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../main.dart'; // Client Supabase

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _purpleAccent = Color(0xFF9333EA);
  static const Color _textBlack = Color(0xFF111827);

  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  bool _isConnected = false;
  bool _isSearching = false;

  bool _isSaving = false;
  String? _storeId;

  // Form Controllers
  final _headerNamaTokoController = TextEditingController();
  final _headerHpController = TextEditingController();
  final _footerNotaController = TextEditingController();
  final _footerWaController = TextEditingController();
  final _notifikasiWaController = TextEditingController();

  // Switches & Radio States
  bool _showNamaKasir = true;
  bool _showFooterNota = true;
  bool _showFooterNotaWa = true;
  bool _showQrCode = true;
  String _selectedPaperSize = '58 mm';

  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettingsFromProvider();
       // 🟢 BACAKAN REKAMAN PRINTER YANG TERHUBUNG DI PROVIDER
      final savedPrinter = context.read<SettingsProvider>().selectedPrinter;
      if (savedPrinter != null && mounted) {
        setState(() {
          _selectedDevice = savedPrinter;
        });
      }
    });
  }

  @override
  void dispose() {
    _headerNamaTokoController.dispose();
    _headerHpController.dispose();
    _footerNotaController.dispose();
    _footerWaController.dispose();
    _notifikasiWaController.dispose();
    super.dispose();
  }

  // 1. BACA PENGATURAN DARI SETTINGSPROVIDER
  void _loadSettingsFromProvider() {
    final settingsProv = context.read<SettingsProvider>();
    _storeId = settingsProv.storeId;
    final data = settingsProv.storeSettings;

    if (data != null && mounted) {
      setState(() {
        _headerNamaTokoController.text = data['header_nama_toko'] ?? settingsProv.namaToko;
        _headerHpController.text = data['header_hp'] ?? '';
        _footerNotaController.text = data['footer_nota'] ?? '';
        _footerWaController.text = data['footer_wa'] ?? '';
        _notifikasiWaController.text = data['notifikasi_wa'] ?? '';

        _showNamaKasir = data['show_nama_kasir'] ?? true;
        _showFooterNota = data['show_footer_nota'] ?? true;
        _showFooterNotaWa = data['show_footer_wa'] ?? true;
        _showQrCode = data['show_qr_code'] ?? true;
        _selectedPaperSize = data['paper_size'] ?? '58 mm';
      });
    }
  }

  // 2. SIMPAN PENGATURAN KE SUPABASE
  Future<void> _saveSettingsToSupabase() async {
    if (_storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: store_id tidak ditemukan!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'store_id': _storeId,
        'header_nama_toko': _headerNamaTokoController.text,
        'header_hp': _headerHpController.text,
        'footer_nota': _footerNotaController.text,
        'footer_wa': _footerWaController.text,
        'notifikasi_wa': _notifikasiWaController.text,
        'show_nama_kasir': _showNamaKasir,
        'show_footer_nota': _showFooterNota,
        'show_footer_wa': _showFooterNotaWa,
        'show_qr_code': _showQrCode,
        'paper_size': _selectedPaperSize,
      };

      await supabase.from('store_settings').upsert(payload, onConflict: 'store_id');

      if (mounted) {
        await context.read<SettingsProvider>().fetchStoreSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan Nota berhasil disimpan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 3. LOGIKA PRINTER BLUETOOTH DENGAN PRINT_BLUETOOTH_THERMAL
  Future<void> _checkCurrentConnection() async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (mounted) {
      setState(() => _isConnected = isConnected);
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _isSearching = true);

    // Minta Perizinan Runtime Bluetooth & Lokasi
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect]!.isGranted ||
        statuses[Permission.bluetoothScan]!.isGranted) {
      try {
        final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
        setState(() {
          _devices = listResult;
          _isSearching = false;
        });

        if (listResult.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada printer paired. Sambungkan printer terlebih dahulu di Settings Bluetooth HP.')),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    } else {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin Bluetooth ditolak.')),
        );
      }
    }
  }

 Future<void> _connectToDevice(BluetoothInfo device) async {
     try {
       if (_isConnected) {
         await PrintBluetoothThermal.disconnect;
         if (mounted) {
           context.read<SettingsProvider>().setSelectedPrinter(null);
           setState(() {
             _selectedDevice = null;
             _isConnected = false;
           });
         }
       }
 
       final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
 
       if (mounted) {
         if (result) {
           // 🟢 Simpan ke Provider global supaya tidak lupa saat pindah layar
           context.read<SettingsProvider>().setSelectedPrinter(device);
 
           setState(() {
             _selectedDevice = device;
             _isConnected = true;
           });
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Berhasil terhubung ke ${device.name}')),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Gagal terhubung ke ${device.name}')),
           );
         }
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error koneksi: $e')),
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
        title: const Text('Printer & Nota', style: TextStyle(color: _textBlack, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD STATUS PRINTER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.print_rounded, color: _purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Printer', style: TextStyle(fontSize: 10, color: Colors.black45)),
                        Text(
                          _isConnected ? 'Terhubung (${_selectedDevice?.name ?? 'Thermal'})' : 'Belum Terhubung',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isConnected ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _purpleAccent),
                    onPressed: _scanDevices,
                  )
                ],
              ),
            ),

            // LIST PERANGKAT BLUETOOTH
            if (_isSearching)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: _purpleAccent)))
            else if (_devices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isThisConnected = _selectedDevice?.macAdress == device.macAdress && _isConnected;
                    return ListTile(
                      dense: true,
                      title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(device.macAdress, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isThisConnected ? Colors.redAccent : _purpleAccent),
                        onPressed: () => _connectToDevice(device),
                        child: Text(isThisConnected ? 'Putus' : 'Hubungkan', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // INPUT FORM
            const Text(
              'Sub-Header / Slogan Nota (Di Bawah Nama Toko)', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
            const SizedBox(height: 8),
            _buildTextField(_headerNamaTokoController),
            const SizedBox(height: 8),
            _buildTextField(_headerHpController),

            const SizedBox(height: 16),
            const Text('Footer Nota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
            const SizedBox(height: 8),
            _buildTextField(_footerNotaController, maxLines: 4),

            const SizedBox(height: 16),
            const Text('Footer Nota WA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
            const SizedBox(height: 8),
            _buildTextField(_footerWaController, maxLines: 4),

            const SizedBox(height: 16),
            const Text('Notifikasi WA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
            const SizedBox(height: 8),
            _buildTextField(_notifikasiWaController),

            const SizedBox(height: 16),
            _buildSwitch('Nama Kasir', _showNamaKasir, (val) => setState(() => _showNamaKasir = val)),
            _buildSwitch('footer nota', _showFooterNota, (val) => setState(() => _showFooterNota = val)),
            _buildSwitch('footer nota wa', _showFooterNotaWa, (val) => setState(() => _showFooterNotaWa = val)),
            _buildSwitch('QR code pembayaran', _showQrCode, (val) => setState(() => _showQrCode = val)),

            const SizedBox(height: 16),
            const Text('Ukuran Printer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
            RadioListTile<String>(
              dense: true,
              title: const Text('58 mm'),
              value: '58 mm',
              groupValue: _selectedPaperSize,
              activeColor: _purpleAccent,
              onChanged: (val) => setState(() => _selectedPaperSize = val!),
            ),
            RadioListTile<String>(
              dense: true,
              title: const Text('80 mm'),
              value: '80 mm',
              groupValue: _selectedPaperSize,
              activeColor: _purpleAccent,
              onChanged: (val) => setState(() => _selectedPaperSize = val!),
            ),

            const SizedBox(height: 20),

            // TOMBOL SIMPAN SINKRONISASI
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _saveSettingsToSupabase,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SIMPAN PENGATURAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12)),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Switch(value: value, activeColor: _purpleAccent, onChanged: onChanged),
      ],
    );
  }
}
