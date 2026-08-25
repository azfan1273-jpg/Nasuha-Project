import 'package:flutter/material.dart';

class NotaDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const NotaDialog({super.key, required this.order});

  @override
  State<NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<NotaDialog> {
  // Mode nota: 'customer' atau 'produksi'
  String _selectedMode = 'customer';

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatTanggal(dynamic rawDate) {
    if (rawDate == null) return '-';
    final String str = rawDate.toString().trim();
    if (str.isEmpty || str == 'null') return '-';
    try {
      final dt = DateTime.parse(str);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return str;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nota = (widget.order['nota_number'] ?? 'LNDR-${(widget.order['id'] ?? 0).toString().padLeft(5, '0')}').toString();
    final String customerName = (widget.order['customer_name'] ?? 'Pelanggan').toString();
    final String customerPhone = (widget.order['customer_phone'] ?? '-').toString();
    final String parfum = (widget.order['parfum'] ?? 'Standard').toString();
    final String paymentStatus = (widget.order['status_pembayaran'] ?? widget.order['payment_status'] ?? 'Belum Lunas').toString();
    final String createdDate = _formatTanggal(widget.order['created_at']);
    final String estDate = _formatTanggal(widget.order['estimated_at']);
    final String notes = (widget.order['catatan'] ?? widget.order['notes'] ?? '-').toString();
    final num totalPrice = num.tryParse(widget.order['total_price']?.toString() ?? '0') ?? 0;

    // Items List
    final List<dynamic> itemsFromDb = widget.order['order_items'] is List ? widget.order['order_items'] : [];
    final List<Map<String, dynamic>> itemsList = [];

    if (itemsFromDb.isNotEmpty) {
      for (var item in itemsFromDb) {
        if (item is Map) itemsList.add(Map<String, dynamic>.from(item));
      }
    } else {
      final String rawServices = (widget.order['service_name'] ?? '').toString();
      for (var s in rawServices.split(',')) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) itemsList.add({'service_name': trimmed, 'qty': 1});
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Dialog
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Cetak Nota Thermal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. DUA PILIHAN TAB TOMBOL
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 'customer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'customer' ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Nota Customer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedMode == 'customer' ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 'produksi'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'produksi' ? Colors.orange : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Nota Produksi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedMode == 'produksi' ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. KERTAS PREVIEW NOTA THERMAL (58mm Style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9), // Warna kertas struk
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: _selectedMode == 'customer'
                  ? _buildCustomerReceipt(
                      nota: nota,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      parfum: parfum,
                      createdDate: createdDate,
                      estDate: estDate,
                      notes: notes,
                      totalPrice: totalPrice,
                      paymentStatus: paymentStatus,
                      itemsList: itemsList,
                    )
                  : _buildProduksiReceipt(
                      nota: nota,
                      customerName: customerName,
                      parfum: parfum,
                      createdDate: createdDate,
                      estDate: estDate,
                      notes: notes,
                      itemsList: itemsList,
                    ),
            ),
            const SizedBox(height: 16),

            // 3. TOMBOL EKSEKUSI CETAK
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMode == 'customer' ? Colors.blue : Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mengirim ${_selectedMode == 'customer' ? 'Nota Customer' : 'Nota Produksi'} ke Printer...',
                      ),
                    ),
                  );
                  // LOGIKA PRINT BLUETOOTH DI PANGGIL DI SINI NANTI
                },
                icon: const Icon(Icons.print, color: Colors.white, size: 18),
                label: Text(
                  'Cetak ${_selectedMode == 'customer' ? 'Nota Customer' : 'Nota Produksi'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUILDER PREVIEW NOTA CUSTOMER (LENGKAP WITH PRICE)
  Widget _buildCustomerReceipt({
    required String nota,
    required String customerName,
    required String customerPhone,
    required String parfum,
    required String createdDate,
    required String estDate,
    required String notes,
    required num totalPrice,
    required String paymentStatus,
    required List<Map<String, dynamic>> itemsList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('NASUHA LAUNDRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('Nota Transaksi Pelanggan', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 6),
        const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nota: $nota', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(createdDate, style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Plg: $customerName', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(customerPhone, style: const TextStyle(fontSize: 10)),
          ],
        ),
        const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),

        // Items
        ...itemsList.map((item) {
          final String name = (item['service_name'] ?? 'Layanan').toString();
          final String unit = (item['unit'] ?? 'Pcs').toString();
          final String qty = (item['qty'] ?? 1).toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 10))),
                Text('$qty $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),

        const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Parfum:', style: TextStyle(fontSize: 10)),
            Text(parfum, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Est. Selesai:', style: TextStyle(fontSize: 10)),
            Text(estDate, style: const TextStyle(fontSize: 10)),
          ],
        ),
        if (notes != '-') ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Ket: $notes', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic)),
          ),
        ],
        const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STATUS: ${paymentStatus.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(_formatRupiah(totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('*** Terima Kasih ***', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic)),
      ],
    );
  }

  // BUILDER PREVIEW NOTA PRODUKSI (SIMPLE TAG UNTUK DIPENITI / DITEMPEL)
  Widget _buildProduksiReceipt({
    required String nota,
    required String customerName,
    required String parfum,
    required String createdDate,
    required String estDate,
    required String notes,
    required List<Map<String, dynamic>> itemsList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: Colors.black,
          child: const Text('[ NOTA PRODUKSI / WORKSHOP ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(nota, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text('Pelanggan: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.grey)),

        // Items Produksi
        ...itemsList.map((item) {
          final String name = (item['service_name'] ?? 'Layanan').toString();
          final String unit = (item['unit'] ?? 'Pcs').toString();
          final String qty = (item['qty'] ?? 1).toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(4)),
                  child: Text('$qty $unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),

        const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PARFUM:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(parfum.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TGL MASUK:', style: TextStyle(fontSize: 10)),
            Text(createdDate, style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DEADLINE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(estDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Text(
            'CATATAN PRODUKSI:\n$notes',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
