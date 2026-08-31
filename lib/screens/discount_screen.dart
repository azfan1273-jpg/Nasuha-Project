import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Instance supabase global
import '../providers/settings_provider.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _primaryPink = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _ketPercentController = TextEditingController();
  final TextEditingController _qtyPercentController = TextEditingController();

  final TextEditingController _ketNominalController = TextEditingController();
  final TextEditingController _qtyNominalController = TextEditingController();

  List<Map<String, dynamic>> _discountsList = [];
  bool _isLoading = false;
  String? _editingId; // Mode edit

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  @override
  void dispose() {
    _ketPercentController.dispose();
    _qtyPercentController.dispose();
    _ketNominalController.dispose();
    _qtyNominalController.dispose();
    super.dispose();
  }

  String _formatRupiah(num value) {
    final number = value.round().toString();
    final chars = number.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).reversed.join());
    }
    return 'Rp ${chunks.reversed.join('.')}';
  }

  // 🟢 1. FETCH DATA DISKON DENGAN RPC
  Future<void> _fetchDiscounts() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await supabase.rpc('get_discounts_by_store', params: {
        'p_store_id': storeId,
      });

      if (mounted) {
        setState(() {
          _discountsList = List<Map<String, dynamic>>.from(response ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetch discounts RPC: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🟢 2. PROSES TAMBAH / UPDATE DISKON DENGAN RPC
  Future<void> _saveDiscount({required String type}) async {
    final isPercent = type == 'percent';
    final ket = isPercent ? _ketPercentController.text.trim() : _ketNominalController.text.trim();
    final qtyStr = isPercent ? _qtyPercentController.text.trim() : _qtyNominalController.text.trim();

    if (ket.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan dan nilai diskon tidak boleh kosong!')),
      );
      return;
    }

    final double qtyVal = double.tryParse(qtyStr.replaceAll(',', '.')) ?? 0;
    if (qtyVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai diskon harus lebih dari 0!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) throw Exception('Store ID null');

      final discountId = _editingId != null ? int.tryParse(_editingId!) : null;

      // Diskon nominal diselaraskan menjadi 'fixed' agar kalkulasi kasir presisi
      final String saveType = isPercent ? 'percent' : 'fixed';

      await supabase.rpc('upsert_discount_by_store', params: {
        'p_id': discountId,
        'p_store_id': storeId,
        'p_title': ket,
        'p_type': saveType,
        'p_value': qtyVal,
      });

      _clearForm();
      await _fetchDiscounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingId != null ? 'Diskon diperbarui!' : 'Diskon berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error save discount RPC: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🟢 3. HAPUS DISKON DENGAN RPC
  Future<void> _deleteDiscount(dynamic id) async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      final intId = int.tryParse(id.toString());
      if (storeId == null || intId == null) return;

      await supabase.rpc('delete_discount_by_store', params: {
        'p_id': intId,
        'p_store_id': storeId,
      });

      await _fetchDiscounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diskon berhasil dihapus'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error delete discount RPC: $e');
    }
  }

  void _clearForm() {
    _ketPercentController.clear();
    _qtyPercentController.clear();
    _ketNominalController.clear();
    _qtyNominalController.clear();
    _editingId = null;
  }

  void _onEditPressed(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['id'].toString();
      final type = (item['type'] ?? '').toString();
      if (type == 'percent') {
        _ketPercentController.text = item['title'] ?? '';
        _qtyPercentController.text = (item['value'] ?? '').toString();
        _ketNominalController.clear();
        _qtyNominalController.clear();
      } else {
        _ketNominalController.text = item['title'] ?? '';
        _qtyNominalController.text = (item['value'] ?? '').toString();
        _ketPercentController.clear();
        _qtyPercentController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: const Text('Pengaturan Diskon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _textBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INPUT FORM DISKON PERSEN (%)
            const Text('Keterangan Diskon Persen (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ketPercentController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Diskon promo grand opening',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyPercentController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '15 %',
                      suffixText: '%',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _saveDiscount(type: 'percent'),
                  icon: const Icon(Icons.add_circle, color: _primaryPink, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // INPUT FORM DISKON NOMINAL (RP)
            const Text('Keterangan Diskon Nominal (Rp)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ketNominalController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Diskon promo layanan Express',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyNominalController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '5000',
                      prefixText: 'Rp ',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _saveDiscount(type: 'fixed'),
                  icon: const Icon(Icons.add_circle, color: _primaryPink, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TABEL DAFTAR DISKON
            const Text('Daftar Diskon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textBlack)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _discountsList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('Belum ada diskon tersimpan', style: TextStyle(color: Colors.grey, fontSize: 11))),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _discountsList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _discountsList[index];
                            final isPercent = item['type'] == 'percent';
                            final String displayQty = isPercent ? '${item['value']}%' : _formatRupiah(item['value'] ?? 0);

                            return ListTile(
                              dense: true,
                              title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text(
                                isPercent ? 'Diskon Persen' : 'Diskon Nominal',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayQty,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _primaryPink),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                    onPressed: () => _onEditPressed(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _deleteDiscount(item['id']),
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
  }
}
