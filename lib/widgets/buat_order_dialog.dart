import 'package:flutter/material.dart';

class BuatOrderDialog extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const BuatOrderDialog({super.key, required this.onOrderCreated});

  @override
  State<BuatOrderDialog> createState() => _BuatOrderDialogState();
}

class _BuatOrderDialogState extends State<BuatOrderDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final List<Map<String, String>> _topCustomers = [];

  void _showFormOrder(BuildContext context, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _FormOrderDialog(
        type: type,
        onOrderSuccess: () {
          Navigator.pop(dialogContext); // Tutup Form Order
          Navigator.pop(context); // Tutup Menu Transaksi
          widget.onOrderCreated(); // Refresh Callback
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _bgDark,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textBlack, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons (IN & OUT)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      title: 'Buat Orders',
                      subtitle: 'Cucian Masuk',
                      icon: Icons.add_shopping_cart_rounded,
                      colors: [const Color(0xFF34D399), const Color(0xFF059669)],
                      shadowColor: Colors.green.shade600,
                      onTap: () => _showFormOrder(context, 'IN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      title: 'Pengeluaran',
                      subtitle: 'Biaya Toko',
                      icon: Icons.account_balance_wallet_rounded,
                      colors: [const Color(0xFFFB923C), const Color(0xFFE11D48)],
                      shadowColor: Colors.deepOrange.shade600,
                      onTap: () => _showFormOrder(context, 'OUT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 12),

              // Top Customers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Top Customers',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textBlack,
                    ),
                  ),
                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ],
              ),
              const SizedBox(height: 10),

              // List Top Customers
              SizedBox(
                height: 180,
                child: _topCustomers.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data pelanggan',
                          style: TextStyle(fontSize: 11, color: Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _topCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _topCustomers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _cardDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _goldAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _textBlack,
                                          ),
                                        ),
                                        Text(
                                          customer['orders'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    customer['status'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: _goldAccent,
                                    ),
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
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 95,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENT DIALOG FORM TRANSAKSI
// ============================================================================
class _FormOrderDialog extends StatefulWidget {
  final String type;
  final VoidCallback onOrderSuccess;

  const _FormOrderDialog({
    required this.type,
    required this.onOrderSuccess,
  });

  @override
  State<_FormOrderDialog> createState() => _FormOrderDialogState();
}

class _FormOrderDialogState extends State<_FormOrderDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _catatanController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedServices = [];
  String _selectedParfum = 'Standard / Original';
  double _selectedDiscount = 0;

  // Mock Data
  final List<Map<String, dynamic>> _customers = [
    {'name': 'Aila Nasuha', 'phone': '0812xxxx', 'address': 'Jl. Mawar'},
    {'name': 'Bu Ratna', 'phone': '081234567890', 'address': 'Jl. Mawar'},
    {'name': 'Pak Hendra', 'phone': '082233445566', 'address': 'Jl. Melati'},
    {'name': 'Siti Nurhaliza', 'phone': '083344556677', 'address': 'Jl. Kenanga'},
  ];

  final List<Map<String, dynamic>> _services = [
    {'name': 'Setrika', 'unit': 'Kg', 'price': 4000.0},
    {'name': 'Cuci Kering', 'unit': 'Kg', 'price': 7000.0},
    {'name': 'Cuci Lipat', 'unit': 'Kg', 'price': 6000.0},
    {'name': 'Cuci Setrika', 'unit': 'Kg', 'price': 10000.0},
    {'name': 'Cuci Selimut', 'unit': 'Pcs', 'price': 15000.0},
    {'name': 'Cuci Bed Cover', 'unit': 'Pcs', 'price': 25000.0},
    {'name': 'Cuci Sepatu', 'unit': 'Pcs', 'price': 20000.0},
  ];

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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (searchContext) {
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSearchState) {
            final keyword = searchController.text.toLowerCase().trim();
            final filtered = _customers.where((c) {
              final name = c['name'].toString().toLowerCase();
              final phone = c['phone'].toString().toLowerCase();
              return name.contains(keyword) || phone.contains(keyword);
            }).toList();

            return AlertDialog(
              backgroundColor: _bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Cari Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: _textBlack)),
              content: SizedBox(
                width: 400,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) => setSearchState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Nama / No. HP',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: const CircleAvatar(
                              backgroundColor: _cardDark,
                              child: Icon(Icons.person_rounded, color: _goldAccent),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['phone']} • ${item['address']}'),
                            onTap: () => Navigator.pop(searchContext, item),
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

    if (result != null) {
      setState(() => _selectedCustomer = result);
    }
  }

  Future<void> _searchService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (searchContext) {
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSearchState) {
            final keyword = searchController.text.toLowerCase().trim();
            final filtered = _services.where((s) => s['name'].toString().toLowerCase().contains(keyword)).toList();

            return AlertDialog(
              backgroundColor: _bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Tambah Layanan', style: TextStyle(fontWeight: FontWeight.bold, color: _textBlack)),
              content: SizedBox(
                width: 400,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) => setSearchState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari layanan...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.local_laundry_service_rounded, color: _goldAccent),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${_formatRupiah((item['price'] as num).toDouble())} / ${item['unit']}'),
                            trailing: const Icon(Icons.add_circle_outline_rounded, color: _goldAccent),
                            onTap: () => Navigator.pop(searchContext, item),
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

    if (result != null) {
      setState(() {
        final idx = _selectedServices.indexWhere((element) => element['name'] == result['name']);
        if (idx >= 0) {
          _selectedServices[idx]['quantity'] = (_selectedServices[idx]['quantity'] as num).toDouble() + 1;
        } else {
          _selectedServices.add({...result, 'quantity': 1.0});
        }
      });
    }
  }

  void _submitOrder() {
    if (_selectedCustomer == null || _selectedServices.isEmpty) return;

    final orderData = {
      'customer_name': _selectedCustomer!['name'],
      'customer_phone': _selectedCustomer!['phone'],
      'services': _selectedServices,
      'catatan': _catatanController.text,
      'parfum': _selectedParfum,
      'discount_percent': _selectedDiscount,
      'subtotal': _subtotal,
      'discount_amount': _discountAmount,
      'total': _totalPrice,
      'type': widget.type,
    };

    debugPrint('ORDER BARU: $orderData');
    widget.onOrderSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470, maxHeight: 760),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0F7),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Form Transaksi',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textBlack),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 2. Pelanggan Section
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
                                    Text(_selectedCustomer!['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(_selectedCustomer!['phone'], style: const TextStyle(color: Colors.black45, fontSize: 10)),
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

                  // 3. Service Cart Section
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
                                          Text(item['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text('${_formatRupiah(price)} / ${item['unit']}', style: const TextStyle(fontSize: 9, color: Colors.black45)),
                                        ],
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

                  // 4. Aroma Parfum
                  const Text('Aroma Parfum', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
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

                  // 5. Catatan Order
                  const Text('Catatan Order', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _catatanController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Luntur, Jangan Terlalu Panas, Baju warna putih dipisah',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. Diskon
                  const Text('Diskon / Potongan Harga', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
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
                  const SizedBox(height: 14),

                  // 7. Footer Total & Action Button
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
                        height: 42,
                        width: 105,
                        child: ElevatedButton(
                          onPressed: (_selectedCustomer == null || _selectedServices.isEmpty) ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.black12,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('PESAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
