import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/database_helper.dart';
import '../screens/cari_pelanggan_screen.dart';
import '../screens/cari_layanan_screen.dart';

final supabase = Supabase.instance.client;

class FormOrderDialog extends StatefulWidget {
  final String type;
  final VoidCallback onOrderSuccess;

  const FormOrderDialog({
    super.key,
    required this.type,
    required this.onOrderSuccess,
  });

  @override
  State<FormOrderDialog> createState() => FormOrderDialogState();
}

class FormOrderDialogState extends State<FormOrderDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _catatanController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedServices = [];
  String _selectedParfum = 'Standard / Original';
  double _selectedDiscount = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  String _formatRupiah(double value) {
    final number = value.round().toString();
    final chars = number.split('').reversed.toList();
    final chunks = <String>[];

    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).reversed.join());
    }

    return 'Rp ${chunks.reversed.join('.')}';
  }

  double get _subtotal {
    double total = 0;
    for (final service in _selectedServices) {
      final price = (service['price'] as num).toDouble();
      final quantity = (service['quantity'] as num).toDouble();
      total += price * quantity;
    }
    return total;
  }

  double get _discountAmount => _subtotal * _selectedDiscount / 100;
  double get _totalPrice => _subtotal - _discountAmount;

	  Future<void> _searchCustomer() async {
	    final result = await Navigator.push<Map<String, dynamic>>(
	      context,
	      MaterialPageRoute(
	        builder: (context) => const CariPelangganScreen(),
	      ),
	    );
	  
	    if (result != null) {
	      setState(() => _selectedCustomer = result);
	    }
	  }
        
  Future<double?> _showQtyDialog(Map<String, dynamic> service) async {
    final qtyController = TextEditingController(text: '1');
    final unit = service['unit'] ?? 'Kg';

    return showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          service['name'] ?? 'Jumlah Order',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textBlack),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Harga: ${_formatRupiah((service['price'] as num).toDouble())} / $unit',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Jumlah / Qty ($unit)',
                hintText: 'Contoh: 2.5 atau 3',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final qty = double.tryParse(qtyController.text.replaceAll(',', '.'));
              if (qty != null && qty > 0) {
                Navigator.pop(dialogCtx, qty);
              }
            },
            child: const Text('TAMBAHKAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _searchService() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CariLayananScreen(),
      ),
    );
  
    if (result != null) {
      setState(() {
        final double qtyToAdd = (result['quantity'] as num).toDouble();
        final idx = _selectedServices.indexWhere((element) => element['name'] == result['name']);
        if (idx >= 0) {
          _selectedServices[idx]['quantity'] = (_selectedServices[idx]['quantity'] as num).toDouble() + qtyToAdd;
        } else {
          _selectedServices.add(result);
        }
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null || _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pelanggan dan minimal 1 layanan!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final String serviceNames = _selectedServices
        .map((s) => "${s['name']} (${s['quantity']} ${s['unit']})")
        .join(', ');

    final Map<String, dynamic> payload = {
      'customer_name': _selectedCustomer!['name'],
      'customer_phone': _selectedCustomer!['phone'],
      'service_name': serviceNames,
      'status': 'Baru',
      'total_price': _totalPrice,
      'catatan': _catatanController.text,
      'parfum': _selectedParfum,
      'discount_percent': _selectedDiscount,
    };

    try {
      await supabase.from('orders').insert(payload);

      try {
        await DatabaseHelper.instance.insertOrder(payload);
      } catch (e) {
        debugPrint('Local SQLite insert skipped: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Berhasil Disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onOrderSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submit order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       color: const Color(0xFFF5F0F7),
       child: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Text('Pelanggan', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
			    const SizedBox(height: 5),
			     Container(
			       height: 58,
			       padding: const EdgeInsets.symmetric(horizontal: 12),
			       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
			       child: Row(
			         children: [
			           Expanded(
			             child: _selectedCustomer == null
		                 ? const Text('Pilih pelanggan...', style: TextStyle(color: Colors.black38, fontSize: 12))
		                 : Column(
		                     mainAxisAlignment: MainAxisAlignment.center,
		                     crossAxisAlignment: CrossAxisAlignment.start,
		                     children: [
		                       Text(_selectedCustomer!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
		                       const SizedBox(height: 2),
		                       Text(_selectedCustomer!['phone'] ?? '', style: const TextStyle(color: Colors.black45, fontSize: 10)),
		                     ],
		                   ),
		                 ),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: _searchCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              ),
                              child: const Text('CARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daftar Layanan (Keranjang)', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                        TextButton.icon(
                          onPressed: _searchService,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF159A9C),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: const Text('+ Tambah Layanan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(minHeight: 90, maxHeight: 220),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: _selectedServices.isEmpty
                          ? InkWell(
                              onTap: _searchService,
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Text(
                                  'Belum ada layanan.\nTekan "+ Tambah Layanan"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black38, fontSize: 11),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _selectedServices.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 7),
                              itemBuilder: (context, index) {
                                final item = _selectedServices[index];
                                final price = (item['price'] as num).toDouble();
                                final qty = (item['quantity'] as num).toDouble();
                                final itemTotal = price * qty;
                                final unit = item['unit'] ?? 'Kg';

                                final String formattedQty = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text('${_formatRupiah(price)} / $unit', style: const TextStyle(fontSize: 9, color: Colors.black45)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        margin: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Qty: $formattedQty $unit',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Text(_formatRupiah(itemTotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.only(left: 6),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.close_rounded, size: 17, color: Colors.black38),
                                        onPressed: () => setState(() => _selectedServices.removeAt(index)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Aroma Parfum', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedParfum,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          style: const TextStyle(color: _textBlack, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'Standard / Original', child: Text('Standard / Original')),
                            DropdownMenuItem(value: 'Sakura', child: Text('Sakura')),
                            DropdownMenuItem(value: 'Lavender', child: Text('Lavender')),
                            DropdownMenuItem(value: 'Melati', child: Text('Melati')),
                            DropdownMenuItem(value: 'Ocean Fresh', child: Text('Ocean Fresh')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedParfum = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Catatan Order', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _catatanController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Luntur, Jangan Terlalu Panas, Baju warna putih dipisah',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 10),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldAccent)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Diskon / Potongan Harga', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: _selectedDiscount,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          style: const TextStyle(color: _textBlack, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Tanpa Diskon (0%)')),
                            DropdownMenuItem(value: 5, child: Text('Diskon 5%')),
                            DropdownMenuItem(value: 10, child: Text('Diskon 10%')),
                            DropdownMenuItem(value: 15, child: Text('Diskon 15%')),
                            DropdownMenuItem(value: 20, child: Text('Diskon 20%')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDiscount = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL PRICE', style: TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(
                                _formatRupiah(_totalPrice),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textBlack),
                              ),
                              if (_selectedDiscount > 0)
                                Text(
                                  'Subtotal ${_formatRupiah(_subtotal)} • Diskon ${_selectedDiscount.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 8, color: Colors.black38),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 44,
                          width: 120,
                          child: ElevatedButton(
                            onPressed: (_selectedCustomer == null || _selectedServices.isEmpty || _isSubmitting)
                                ? null
                                : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black12,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('PESAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
    );
  }
}
