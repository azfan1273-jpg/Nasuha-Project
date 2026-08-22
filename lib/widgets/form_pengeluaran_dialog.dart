import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Formatter Khusus untuk Format Rupiah Otomatis Saat Pengetikan
class RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    final double value = double.parse(cleanText);
    final String formatted = _formatNumber(value.toInt());

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _formatNumber(int number) {
    final String str = number.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }
}

class FormPengeluaranDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const FormPengeluaranDialog({super.key, required this.onSuccess});

  @override
  State<FormPengeluaranDialog> createState() => _FormPengeluaranDialogState();
}

class _FormPengeluaranDialogState extends State<FormPengeluaranDialog> {
  static const Color _textBlack = Color(0xFF111827);
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _bgBg = Color(0xFFFAF5F7);

  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _filterPeriode = '7 Hari';

  List<Map<String, dynamic>> _kategoriList = [];
  String _selectedKategori = 'Operasional Outlet';

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> get _filteredDaftarPengeluaran {
    if (_filterPeriode == 'Semua') return _daftarPengeluaran;

    final now = DateTime.now();
    return _daftarPengeluaran.where((item) {
      final rawDate = item['expense_date'] ?? item['created_at'];
      if (rawDate == null) return false;

      final date = DateTime.tryParse(rawDate.toString());
      if (date == null) return false;

      if (_filterPeriode == '7 Hari') {
        final difference = now.difference(date).inDays;
        return difference >= 0 && difference <= 7;
      } else if (_filterPeriode == 'Bulan Ini') {
        return date.month == now.month && date.year == now.year;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _daftarPengeluaran = [];
  double _totalPengeluaran = 0.0;

  @override
  void initState() {
    super.initState();
    _setInitialDate();
    _fetchKategori();
    _fetchPengeluaran();
  }

  void _setInitialDate() {
    _tanggalController.text =
        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  }

  @override
  void dispose() {
    _totalController.dispose();
    _catatanController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatTanggalItem(dynamic rawDate) {
    if (rawDate == null) return '-';
    try {
      final DateTime dt = DateTime.parse(rawDate.toString());
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return rawDate.toString();
    }
  }

  Future<void> _fetchPengeluaran() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('expenses')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      double totalSum = 0;
      for (var item in data) {
        totalSum += (item['amount'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _daftarPengeluaran = data;
          _totalPengeluaran = totalSum;
        });
      }
    } catch (e) {
      debugPrint('Error fetch pengeluaran: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchKategori() async {
    try {
      final response = await supabase
          .from('expense_categories')
          .select()
          .order('id', ascending: true);

      if (mounted) {
        setState(() {
          _kategoriList = List<Map<String, dynamic>>.from(response);
          if (_kategoriList.isNotEmpty) {
            final names =
                _kategoriList.map((e) => e['name'].toString()).toList();
            if (!names.contains(_selectedKategori)) {
              _selectedKategori = names.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetch kategori: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  InputDecoration _getInputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      fillColor: Colors.white,
      filled: true,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryPink, width: 1.5),
      ),
    );
  }

  void _showKelolaKategoriDialog() {
    final TextEditingController newKategoriCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kelola Kategori',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textBlack),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newKategoriCtrl,
                            style: const TextStyle(fontSize: 12),
                            decoration:
                                _getInputDecoration('Kategori baru...'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final val = newKategoriCtrl.text.trim();
                            if (val.isNotEmpty) {
                              await supabase
                                  .from('expense_categories')
                                  .insert({'name': val});
                              newKategoriCtrl.clear();
                              await _fetchKategori();
                              setDialogState(() {});
                            }
                          },
                          child: const Text('Tambah',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _kategoriList.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final item = _kategoriList[index];
                          return ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(
                              item['name'].toString(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 18, color: Colors.blue),
                                  onPressed: () {
                                    final editCtrl = TextEditingController(
                                      text: item['name'].toString(),
                                    );
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Edit Kategori',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        content: TextField(
                                          controller: editCtrl,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: _getInputDecoration(
                                              'Nama Kategori'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: _primaryPink),
                                            onPressed: () async {
                                              final newText =
                                                  editCtrl.text.trim();
                                              if (newText.isNotEmpty) {
                                                await supabase
                                                    .from('expense_categories')
                                                    .update({'name': newText})
                                                    .eq('id', item['id']);

                                                Navigator.pop(ctx);
                                                await _fetchKategori();
                                                setDialogState(() {});
                                              }
                                            },
                                            child: const Text('Simpan',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.red),
                                  onPressed: () async {
                                    if (_kategoriList.length > 1) {
                                      await supabase
                                          .from('expense_categories')
                                          .delete()
                                          .eq('id', item['id']);

                                      await _fetchKategori();
                                      setDialogState(() {});
                                    }
                                  },
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
            );
          },
        );
      },
    );
  }

  void _showEditPengeluaranDialog(Map<String, dynamic> item) {
    final int initialPrice = (item['amount'] as num?)?.toInt() ?? 0;
    final TextEditingController editTotalCtrl = TextEditingController(
      text: RupiahFormatter._formatNumber(initialPrice),
    );
    final TextEditingController editCatatanCtrl = TextEditingController(
      text: item['notes'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Pengeluaran',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textBlack)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pengeluaran',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: editTotalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RupiahFormatter(),
                ],
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                decoration: _getInputDecoration('0'),
              ),
              const SizedBox(height: 12),
              const Text('Catatan / Deskripsi',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: editCatatanCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: _getInputDecoration('Catatan...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await supabase.from('expenses').delete().eq('id', item['id']);
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchPengeluaran();
                }
              },
              child: const Text('Hapus Data',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final rawTotal = editTotalCtrl.text.replaceAll('.', '').trim();
                final double totalHarga = double.tryParse(rawTotal) ?? 0;

                await supabase.from('expenses').update({
                  'amount': totalHarga,
                  'notes': editCatatanCtrl.text.trim(),
                }).eq('id', item['id']);

                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchPengeluaran();
                }
              },
              child: const Text('Update',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _simpanPengeluaran() async {
    final String rawTotal = _totalController.text.replaceAll('.', '').trim();
    final double totalHarga = double.tryParse(rawTotal) ?? 0.0;

    if (totalHarga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pengeluaran harus diisi!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await supabase.from('expenses').insert({
        'category': _selectedKategori,
        'amount': totalHarga,
        'notes': _catatanController.text.trim(),
        'expense_date': _selectedDate.toIso8601String().split('T')[0],
        'created_at': _selectedDate.toIso8601String(),
      });

      _totalController.clear();
      _catatanController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengeluaran berhasil disimpan!')),
        );
        widget.onSuccess();
      }

      await _fetchPengeluaran();
    } catch (e) {
      debugPrint('Error simpan pengeluaran: $e');
      if (mounted) {
        String errMsg = e.toString();
        if (e is PostgrestException) {
          errMsg = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengeluaran: $errMsg')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER DAFTAR PENGELUARAN & FILTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pengeluaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterPeriode,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textBlack),
                      items: const [
                        DropdownMenuItem(
                            value: '7 Hari', child: Text('7 Hari Terakhir')),
                        DropdownMenuItem(
                            value: 'Bulan Ini', child: Text('Bulan Ini')),
                        DropdownMenuItem(
                            value: 'Semua', child: Text('Semua Data')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterPeriode = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // TABEL DAFTAR PENGELUARAN
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 80,
                          child: Text('TANGGAL',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                        ),
                        Expanded(
                          child: Text('DESKRIPSI',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                        ),
                        SizedBox(
                          width: 90,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('TOTAL',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _primaryPink),
                            ),
                          )
                        : _daftarPengeluaran.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada catatan pengeluaran',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                      fontStyle: FontStyle.italic),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _filteredDaftarPengeluaran.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final item =
                                      _filteredDaftarPengeluaran[index];
                                  final dateStr = _formatTanggalItem(
                                      item['expense_date'] ??
                                          item['created_at']);
                                  final descStr = item['notes'] ?? '-';
                                  final priceVal =
                                      (item['amount'] as num?) ?? 0;
                                  final categoryStr = (item['category'] ?? '')
                                      .toString()
                                      .trim();

                                  return InkWell(
                                    onTap: () =>
                                        _showEditPengeluaranDialog(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(dateStr,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black87)),
                                                if (categoryStr.isNotEmpty)
                                                  Text(
                                                    categoryStr,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        color:
                                                            Colors.grey.shade600,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              descStr,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 90,
                                            child: Text(
                                              _formatRupiah(priceVal),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _textBlack),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

            // SUB-TOTAL PENGELUARAN
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total Pengeluaran: ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  Text(
                    _formatRupiah(_totalPengeluaran),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // CARD FORM INPUT PENGELUARAN
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INPUT PENGELUARAN BARU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textBlack,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // INPUT TANGGAL
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(10),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: _tanggalController,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  decoration: _getInputDecoration(
                                    'DD/MM/YYYY',
                                    suffixIcon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 18,
                                        color: Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // DROPDOWN KATEGORI
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kategori',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Container(
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedKategori,
                                  isExpanded: true,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _textBlack),
                                  items: _kategoriList.map((kat) {
                                    final String name = kat['name'];
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedKategori = val);
                                    }
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

                  // TOTAL PENGELUARAN INPUT
                  const Text('Total Pengeluaran (Rp)',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      RupiahFormatter(),
                    ],
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: _getInputDecoration('Contoh: 17.500'),
                  ),
                  const SizedBox(height: 10),

                  // CATATAN TAMBAHAN
                  const Text('Catatan Tambahan',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _catatanController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11),
                    decoration:
                        _getInputDecoration('Detail / Deskripsi pengeluaran'),
                  ),
                  const SizedBox(height: 10),

                  // TOMBOL "+ KATEGORI"
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textBlack,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showKelolaKategoriDialog,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 16),
                    label: const Text(
                      'Kelola Kategori',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _simpanPengeluaran,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SIMPAN PENGELUARAN',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
