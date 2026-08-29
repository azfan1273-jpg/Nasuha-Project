import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/database_helper.dart';
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
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _catatanController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedServices = [];
  String _selectedParfum = 'Standard / Original';
  
  bool _isSubmitting = false;
  List<String> _parfums = [];

  @override
      void initState() {
        super.initState();
        _fetchParfums();
        _fetchDiscounts(); // 👈 Tambahkan panggil fetch diskon
      }

  // 🟢 STATE UNTUK DISKON DINAMIS
    List<Map<String, dynamic>> _discountList = [];
    Map<String, dynamic>? _selectedDiscountItem;
  
    
  
    // 🟢 METHOD FETCH DISKON DARI SUPABASE
    Future<void> _fetchDiscounts() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) return;
  
        final profileRes = await supabase
            .from('profiles')
            .select('store_id')
            .eq('id', user.id)
            .maybeSingle();
  
        final String? currentStoreId = profileRes?['store_id']?.toString();

        // JIKA STORE_ID NULL, HENTIKAN PROSES AGAR TIDAK ERROR
        if (currentStoreId == null) return;
  
        final response = await supabase
            .from('discounts')
            .select()
            .eq('store_id', currentStoreId)
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
      final response = await supabase.from('parfums').select('name');
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

  // 1. SUB TOTAL KOTOR (SEBELUM DISKON)
  double get _subtotal {
    double total = 0;
    for (final service in _selectedServices) {
      final price = (service['price'] as num).toDouble();
      final quantity = (service['quantity'] as num).toDouble();
      total += price * quantity;
    }
    return total;
  }

  // 🟢 DISKON PERSEN (JIKA DIPILIH TIPE PERCENT)
  double get _selectedDiscount {
    if (_selectedDiscountItem == null) return 0;
    if (_selectedDiscountItem!['type'] == 'percent') {
      return (_selectedDiscountItem!['value'] as num).toDouble();
    }
    return 0;
  }

  // 🟢 NOMINAL RUPIAH POTONGAN DISKON
  double get _discountAmount {
    if (_selectedDiscountItem == null) return 0;
    final type = _selectedDiscountItem!['type'];
    final value = (_selectedDiscountItem!['value'] as num).toDouble();

    if (type == 'percent') {
      return _subtotal * (value / 100);
    } else {
      // Jika nominal, potongan langsung sebesar value
      return value;
    }
  }

  // TOTAL PRICE BERSIH
  double get _totalPrice => (_subtotal - _discountAmount) < 0 ? 0 : (_subtotal - _discountAmount);
  
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

  Future<void> _searchService() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const DaftarLayananScreen(),
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
        .map((s) => (s['name'] ?? '').toString())
        .join(', ');

    int maxDays = 1;
    for (var s in _selectedServices) {
      final String rawEst = (s['estimation'] ?? s['duration'] ?? '1').toString();
      final String cleanEst = rawEst.replaceAll(RegExp(r'[^0-9]'), ''); 
      final int days = int.tryParse(cleanEst) ?? 1;
      
      if (days > maxDays) maxDays = days;
    }
    
    final DateTime estimatedDate = DateTime.now().add(Duration(days: maxDays));

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User belum login');

      // 1. Ambil store_id dari profiles
      final profileRes = await supabase
          .from('profiles')
          .select('store_id')
          .eq('id', user.id)
          .maybeSingle();

      final String? currentStoreId = profileRes?['store_id']?.toString();

      // 2. Susun Payload Header Order (Lengkap Subtotal & Discount Nominal)
      final Map<String, dynamic> payload = {
        'user_id': user.id,
        'store_id': currentStoreId,
        'customer_name': _selectedCustomer!['name'],
        'customer_phone': _selectedCustomer!['phone'],
        'service_name': serviceNames,
        'status': 'Antrian',
        'subtotal': _subtotal,            // 🟢 SIMPAN SUB TOTAL KOTOR
        'discount': _discountAmount,      // 🟢 SIMPAN NOMINAL DISKON RUPIAH
        'discount_percent': _selectedDiscount,
        'total_price': _totalPrice,       // 🟢 SIMPAN TOTAL BERSIH
        'catatan': _catatanController.text,
        'parfum': _selectedParfum,
        'estimated_at': estimatedDate.toIso8601String(),
      };

      // 3. Insert ke tabel orders Supabase
      final orderResponse = await supabase
          .from('orders')
          .insert(payload)
          .select()
          .single();

      final dynamic orderId = orderResponse['id'];
      final String notaNumber = 'LNDR-${orderId.toString().padLeft(5, '0')}';

      await supabase
          .from('orders')
          .update({'nota_number': notaNumber})
          .eq('id', orderId);

      // 4. Susun Payload Items (Harga Asli)
      final List<Map<String, dynamic>> orderItemsPayload = _selectedServices.map((s) {
        final double price = (s['price'] as num).toDouble();
        final double qty = (s['quantity'] as num).toDouble();
        return {
          'user_id': user.id,
          'store_id': currentStoreId,
          'order_id': orderId,
          'service_name': s['name'] ?? '',
          'qty': qty,
          'price': price,
          'subtotal': price * qty,
          'unit': s['unit'] ?? 'Pcs',
        };
      }).toList();

      // 5. Insert ke order_items Supabase
      await supabase.from('order_items').insert(orderItemsPayload);

      // 6. Simpan ke SQLite Lokal
      try {
        await DatabaseHelper.instance.insertOrder(payload);
      } catch (e) {
        debugPrint('Local SQLite insert skipped: $e');
      }

      // 7. Notifikasi Berhasil & Tutup Dialog
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
              // PELANGGAN
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

              // KERANJANG LAYANAN
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

              // AROMA PARFUM
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

              // CATATAN ORDER
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

              // DISKON / POTONGAN HARGA
              const Text('Diskon / Potongan Harga', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              // 🟢 DROPDOWN DISKON DINAMIS
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

              // 🟢 RINCIAN HARGA LENGKAP & TOMBOL PESAN (LANGKAH NO. 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    // A. SUB TOTAL (KOTOR)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sub Total', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        Text(_formatRupiah(_subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // B. DISCOUNT (NOMINAL RUPIAH)
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

                    // C. TOTAL PRICE BERSIH & TOMBOL PESAN
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
