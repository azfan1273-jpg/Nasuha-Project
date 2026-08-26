import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../main.dart'; // Sesuaikan lokasi import supabase client kamu

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

  bool _isLoading = false;
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
    _loadSettingsFromSupabase();
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

  // 🔹 1. BACA PENGATURAN DARI TABEL store_settings SUPABASE
  Future<void> _loadSettingsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Ambil store_id dari profile user
      final profile = await supabase
          .from('profiles')
          .select('store_id')
          .eq('id', user.id)
          .maybeSingle();

      _storeId = profile?['store_id']?.toString();

      if (_storeId != null) {
        // Fetch dari tabel store_settings
        final data = await supabase
            .from('store_settings')
            .select('*')
            .eq('store_id', _storeId!)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _headerNamaTokoController.text = data['header_nama_toko'] ?? '{{nama toko}}';
            _headerHpController.text = data['header_hp'] ?? '{{HP :}}';
            _footerNotaController.text = data['footer_nota'] ?? '';
            _footerWaController.text = data['footer_wa'] ?? '';
            _notifikasiWaController.text = data['notifikasi_wa'] ?? '-';

            _showNamaKasir = data['show_nama_kasir'] ?? true;
            _showFooterNota = data['show_footer_nota'] ?? true;
            _showFooterNotaWa = data['show_footer_wa'] ?? true;
            _showQrCode = data['show_qr_code'] ?? true;
            _selectedPaperSize = data['paper_size'] ?? '58 mm';
          });
        }
      }
    } catch (e) {
      debugPrint("Error load store_settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 2. SIMPAN / UPSERT PENGATURAN KE SUPABASE
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

      // Upsert: update jika store_id ada, insert jika belum ada row
      await supabase.from('store_settings').upsert(payload, onConflict: 'store_id');

      if (mounted) {
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

  // 🔹 LOGIKA BLUETOOTH PRINTER
  Future<void> _checkCurrentConnection() async {
    bool? isConnected = await _bluetooth.isConnected;
    if (isConnected == true) {
      setState(() => _isConnected = true);
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _isSearching = true);
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      if (_isConnected) await _bluetooth.disconnect();
      await _bluetooth.connect(device);
      setState(() {
        _selectedDevice = device;
        _isConnected = true;
      });
    } catch (_) {}
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _purpleAccent))
          : SingleChildScrollView(
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
                          final isThisConnected = _selectedDevice?.address == device.address && _isConnected;
                          return ListTile(
                            dense: true,
                            title: Text(device.name ?? 'Device', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  const Text('Header Nota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack)),
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
