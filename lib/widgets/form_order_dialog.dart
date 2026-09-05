import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';
import '../screens/cari_pelanggan_screen.dart';
import '../screens/daftar_layanan_screen.dart';

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
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _catatanController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedServices = [];
  String _selectedParfum = 'Standard / Original';
  
  bool _isSubmitting = false;
  List<String> _parfums = [];

  List<Map<String, dynamic>> _discountList = [];
  Map<String, dynamic>? _selectedDiscountItem;

  DateTime _selectedOrderDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchParfums();
      _fetchDiscounts();
    });
  }

  Future<void> _selectOrderDate(BuildContext context) async {
    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 31));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedOrderDate.isBefore(minDate) ? minDate : _selectedOrderDate,
      firstDate: minDate,
      lastDate: now,
    );

    if (picked != null) {
      final isBackdate = picked.year != now.year ||
          picked.month != now.month ||
          picked.day != now.day;

      if (isBackdate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perhatian: Transaksi dicatat pada tanggal mundur (${picked.day}/${picked.month}/${picked.year}).',
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _selectedOrderDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );
      });
    }
  }

  Future<void> _fetchDiscounts() async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) return;

      final response = await supabase
          .from('discounts')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _discountList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetch discounts: $e');
    }
  }

  Future<void> _fetchParfums() async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) return;

      final response = await supabase
          .from('parfums')
          .select('name')
          .eq('store_id', storeId);

      if (mounted) {
        setState(() {
          _parfums = List<String>.from(response.map((e) => e['name'] as String));
          if (_parfums.isNotEmpty && !_parfums.contains(_selectedParfum)) {
            _selectedParfum = _parfums.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetch parfum: $e');
    }
  }

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

  double get _selectedDiscount {
    if (_selectedDiscountItem == null) return 0;
    if (_selectedDiscountItem!['type'] == 'percent') {
      return (_selectedDiscountItem!['value'] as num).toDouble();
    }
    return 0;
  }

  double get _discountAmount {
    if (_selectedDiscountItem == null) return 0;
    final type = _selectedDiscountItem!['type'];
    final value = (_selectedDiscountItem!['value'] as num).toDouble();

    if (type == 'percent') {
      return _subtotal * (value / 100);
    } else {
      return value;
    }
  }

  double get _totalPrice => (_subtotal - _discountAmount) < 0 ? 0 : (_subtotal - _discountAmount);
  
  Future<void> _searchCustomer() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CariPelangganScreen(
        	isSelectionMode: true,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedCustomer = result);
    }
  }

  Future<void> _searchService() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const DaftarLayananScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        // Mengambil quantity yang dikirimkan dari DaftarLayananScreen (hasil dialog input user)
        final double qtyToAdd = (result['quantity'] as num?)?.toDouble() ?? 1.0;
        
        // Buat salinan map agar data aman dan key quantity/unit terdefinisi dengan benar
        final Map<String, dynamic> newItem = Map<String, dynamic>.from(result);
        newItem['quantity'] = qtyToAdd;
        newItem['unit'] = newItem['unit'] ?? 'Kg';

        final idx = _selectedServices.indexWhere((element) => element['name'] == newItem['name']);
        if (idx >= 0) {
          // Jika layanan sudah ada di keranjang, tambahkan quantity-nya
          _selectedServices[idx]['quantity'] = (_selectedServices[idx]['quantity'] as num).toDouble() + qtyToAdd;
        } else {
          // Jika belum ada, masukkan item baru ke keranjang
          _selectedServices.add(newItem);
        }
      });
    }
  }

  // DIALOG UBAH QTY/BERAT LANGSUNG DI KERANJANG
  Future<void> _editQuantity(int index) async {
    final item = _selectedServices[index];
    final TextEditingController qtyController = TextEditingController(
      text: item['quantity'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Qty ${item['name']}'),
        content: TextField(
          controller: qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Jumlah / Berat (misal: 1.5)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyController.text) ?? item['quantity'];
              setState(() {
                _selectedServices[index]['quantity'] = newQty;
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
        .map((s) => (s['name'] ?? '').toString())
        .join(', ');

    int maxDays = 1;
    for (var s in _selectedServices) {
      final String rawEst = (s['estimation'] ?? s['duration'] ?? '1').toString();
      final String cleanEst = rawEst.replaceAll(RegExp(r'[^0-9]'), ''); 
      final int days = int.tryParse(cleanEst) ?? 1;
      
      if (days > maxDays) maxDays = days;
    }
    
    final DateTime estimatedDate = _selectedOrderDate.add(Duration(days: maxDays));

    try {
      final String? currentStoreId = context.read<SettingsProvider>().storeId;
      if (currentStoreId == null) throw Exception('ID Toko tidak ditemukan');

      final List<Map<String, dynamic>> itemsPayload = _selectedServices.map((s) {
        final double price = (s['price'] as num).toDouble();
        final double qty = (s['quantity'] as num).toDouble();
        return {
          'service_name': s['name'] ?? '',
          'price': price,
          'qty': qty, 
          'subtotal': price * qty,
          'unit': s['unit'] ?? 'Kg',
        };
      }).toList();

      await supabase.rpc('create_order_with_items', params: {
        'p_store_id': currentStoreId,
        'p_customer_name': _selectedCustomer!['name'],
        'p_customer_phone': _selectedCustomer!['phone'] ?? '-',
        'p_service_summary': serviceNames,
        'p_total_price': _totalPrice,
        'p_estimated_at': estimatedDate.toIso8601String(),
        'p_status': 'Antrian',
        'p_metode_pembayaran': null,
        'p_items': itemsPayload,
        'p_created_at': _selectedOrderDate.toIso8601String(),
        'p_parfum': _selectedParfum,
        'p_catatan': _catatanController.text,
      });

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
      debugPrint('Error submit order via RPC: $e');
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
              const Text(
                'Tanggal Transaksi',
                style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: () => _selectOrderDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: _goldAccent),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedOrderDate.day.toString().padLeft(2, '0')}/${_selectedOrderDate.month.toString().padLeft(2, '0')}/${_selectedOrderDate.year}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack),
                          ),
                        ],
                      ),
                      const Text(
                        'Ubah Tanggal',
                        style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
                  const Text(
                    'Daftar Layanan (Keranjang)',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  InkWell(
                    onTap: _searchService,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE91E63), 
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded, 
                            size: 15, 
                            color: Color(0xFFE91E63),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tambah Layanan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                    ),
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

                          final String formattedQty = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);

                          return InkWell(
                            onTap: () => _editQuantity(index),
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
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
                                        Text('${_formatRupiah(price)} / $unit (Ketuk ubah qty)', style: const TextStyle(fontSize: 9, color: Colors.black45)),
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
                    items: _parfums.map((parfum) {
                      return DropdownMenuItem<String>(
                        value: parfum,
                        child: Text(parfum),
                      );
                    }).toList(),
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
                  child: DropdownButton<Map<String, dynamic>?>(
                    value: _selectedDiscountItem,
                    isExpanded: true,
                    hint: const Text('Pilih Diskon / Tanpa Diskon', style: TextStyle(color: Colors.black38, fontSize: 12)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    style: const TextStyle(color: _textBlack, fontSize: 12),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>?>(
                        value: null,
                        child: Text('Tanpa Diskon (0%)'),
                      ),
                      ..._discountList.map((item) {
                        final isPercent = item['type'] == 'percent';
                        final String valText = isPercent 
                            ? '${item['value']}%' 
                            : _formatRupiah((item['value'] as num).toDouble());
                        return DropdownMenuItem<Map<String, dynamic>?>(
                          value: item,
                          child: Text('${item['title']} ($valText)'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedDiscountItem = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sub Total', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        Text(_formatRupiah(_subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount (${_selectedDiscount.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        Text(
                          '- ${_formatRupiah(_discountAmount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('TOTAL PRICE', style: TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(_totalPrice),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
