import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ============================================================================
// COMPONENT DIALOG FORM PENGELUARAN TOKO (FULL HEIGHT & TABLE EXPANDED)
// ============================================================================
class FormPengeluaranDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const FormPengeluaranDialog({required this.onSuccess});

  @override
  State<FormPengeluaranDialog> createState() => FormPengeluaranDialogState();
}

class FormPengeluaranDialogState extends State<FormPengeluaranDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);
  static const Color _yellowInput = Color(0xFFFFF59D);

  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController(
    text: '20/09/2026',
  );

  String _selectedKategori = 'Operasional Outlet';
  bool _isSubmitting = false;

  // Mock data 5 transaksi 1-line (Langsung kelihatan 5 tanpa di-scroll)
  final List<Map<String, String>> _daftarPengeluaran = [
    {
      'tanggal': '02/09/2026',
      'deskripsi': '1. Beli Plastik 25 Ball & Lem 100 Pcs',
      'harga': 'Rp. 25.050.000',
    },
    {
      'tanggal': '03/09/2026',
      'deskripsi': '1. Beli parfume 100 gln',
      'harga': 'Rp. 15.000.000',
    },
    {
      'tanggal': '04/09/2026',
      'deskripsi': '1. Beli Deterjen Matik 10 Can',
      'harga': 'Rp. 2.500.000',
    },
    {
      'tanggal': '05/09/2026',
      'deskripsi': '1. Servis Mesin Cuci LG 2 Unit',
      'harga': 'Rp. 750.000',
    },
    {
      'tanggal': '06/09/2026',
      'deskripsi': '1. Bayar Tagihan Listrik PLN',
      'harga': 'Rp. 1.800.000',
    },
  ];

  @override
  void dispose() {
    _totalController.dispose();
    _catatanController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _simpanPengeluaran() async {
    if (_totalController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final double totalHarga = double.tryParse(_totalController.text.replaceAll('.', '')) ?? 0;

    final payload = {
      'customer_name': 'PENGELUARAN: $_selectedKategori',
      'customer_phone': '-',
      'service_name': _catatanController.text.isEmpty ? _selectedKategori : _catatanController.text,
      'status': 'Pengeluaran',
      'total_price': totalHarga,
      'catatan': _catatanController.text,
      'parfum': '-',
      'discount_percent': 0.0,
    };

    try {
      await supabase.from('orders').insert(payload);
      if (mounted) widget.onSuccess();
    } catch (e) {
      debugPrint('Error simpan pengeluaran: $e');
      if (mounted) widget.onSuccess();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil tinggi penuh layar HP
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Jarak luar makin tipis
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.98, // Penyesuaian 1: Full tinggi layar HP (~98%)
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F5), Color(0xFFFFD1DC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. HEADER TOKO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'NASUHA LAUNDRY',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textBlack),
                                    ),
                                    Text(
                                      'Jl. Mawar No. 12 (Outlet Utama)',
                                      style: TextStyle(fontSize: 10, color: Colors.black54, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, color: Colors.black54),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 2. JUDUL DAFTAR PENGELUARAN
                        Row(
                          children: const [
                            Text('💲 ', style: TextStyle(fontSize: 15)),
                            Text(
                              'Daftar Pengeluaran',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: _textBlack,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Penyesuaian 2: TABEL DIBERSIHKAN DAN DITINGGIKAN UNTUK 5 BARIS (1 LINE)
                        Container(
                          height: 195, // Tinggi pas memuat 5 baris single-line
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            children: [
                              // Header Tabel
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                                ),
                                child: Row(
                                  children: const [
                                    SizedBox(
                                      width: 70,
                                      child: Text('TANGGAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    Text(' | ', style: TextStyle(color: Colors.black38)),
                                    Expanded(
                                      child: Center(
                                        child: Text('DESKRIPSI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    Text(' | ', style: TextStyle(color: Colors.black38)),
                                    SizedBox(
                                      width: 85,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('TOTAL HARGA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Isi Baris Tabel (5 Data Single Line)
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _daftarPengeluaran.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                  itemBuilder: (context, index) {
                                    final item = _daftarPengeluaran[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              item['tanggal']!,
                                              style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                                            ),
                                          ),
                                          const Text(' | ', style: TextStyle(color: Colors.black26)),
                                          Expanded(
                                            child: Text(
                                              item['deskripsi']!,
                                              maxLines: 1, // Kunci 1 Line
                                              overflow: TextOverflow.ellipsis, // Bikin ... jika kepanjangan
                                              style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                                            ),
                                          ),
                                          const Text(' | ', style: TextStyle(color: Colors.black26)),
                                          SizedBox(
                                            width: 85,
                                            child: Text(
                                              item['harga']!,
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. INPUT PENGELUARAN SECTION
                        const Text(
                          'INPUT PENGELUARAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: _textBlack,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tanggal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: _yellowInput,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: TextField(
                                            controller: _tanggalController,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Kategori', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: _yellowInput,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedKategori,
                                              isExpanded: true,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: _textBlack),
                                              items: const [
                                                DropdownMenuItem(value: 'Operasional Outlet', child: Text('Operasional Outlet')),
                                                DropdownMenuItem(value: 'Beli Bahan / Deterjen', child: Text('Beli Bahan / Deterjen')),
                                                DropdownMenuItem(value: 'Gaji Karyawan', child: Text('Gaji Karyawan')),
                                                DropdownMenuItem(value: 'Listrik & Air', child: Text('Listrik & Air')),
                                                DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) setState(() => _selectedKategori = val);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              const Text('Total Pengeluaran', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 4),
                              Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _yellowInput,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _totalController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                  decoration: const InputDecoration(
                                    hintText: '50.000',
                                    hintStyle: TextStyle(color: Colors.black38, fontSize: 11),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(bottom: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              const Text('Catatan Tambahan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _yellowInput,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _catatanController,
                                  maxLines: 3,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                  decoration: const InputDecoration(
                                    hintText: '1. gas 3 kg 100 tabung\n2. bensin 60 liter\n3. pajero sport 1 unit',
                                    hintStyle: TextStyle(color: Colors.black38, fontSize: 10),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. FOOTER (TOTAL PRICE & TOMBOL SIMPAN HIJAU)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black, width: 1.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('TOTAL PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                          SizedBox(height: 2),
                          Text(
                            'Rp. 45.100.000',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: _textBlack),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 38,
                        width: 100,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF86EFAC), // Hijau pastel sesuai SS
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSubmitting ? null : _simpanPengeluaran,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text('Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
