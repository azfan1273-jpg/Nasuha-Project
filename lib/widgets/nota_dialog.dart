import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../providers/settings_provider.dart';

class NotaDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const NotaDialog({super.key, required this.order});

  @override
  State<NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<NotaDialog> {
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

  // 🟢 Diperbarui: Mencegah teks kepanjangan yang merusak baris (terpotong otomatis dengan rapi)
  String _formatTwoColumns(String left, String right, {int width = 32}) {
    int spaceCount = width - left.length - right.length;
    if (spaceCount < 1) {
      int maxLeft = width - right.length - 1;
      if (maxLeft > 0 && left.length > maxLeft) {
        left = left.substring(0, maxLeft); // Potong teks kiri jika kepanjangan
      }
      spaceCount = 1;
    }
    return '$left${' ' * spaceCount}$right';
  }

  List<Map<String, dynamic>> _getItemsList() {
    final List<Map<String, dynamic>> itemsList = [];
    final dynamic rawItems = widget.order['order_items'] ?? widget.order['items'];
    
    if (rawItems is List && rawItems.isNotEmpty) {
      for (var item in rawItems) {
        if (item is Map) itemsList.add(Map<String, dynamic>.from(item));
      }
    } 
    
    if (itemsList.isEmpty) {
      final String serviceName = (widget.order['service_name'] ?? 'Layanan Laundry').toString();
      final num qty = num.tryParse((widget.order['qty'] ?? widget.order['quantity'] ?? 1).toString()) ?? 1;
      final String unit = (widget.order['unit'] ?? 'Kg').toString();
      
      for (var s in serviceName.split(',')) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) {
          itemsList.add({'service_name': trimmed, 'qty': qty, 'unit': unit});
        }
      }
    }
    return itemsList;
  }

  Future<void> _printReceiptToBluetooth(BuildContext context, bool isCustomerMode) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer tidak terhubung! Hubungkan di menu Printer & Nota.')),
        );
      }
      return;
    }

    final settingsProv = context.read<SettingsProvider>();
    final storeSettings = settingsProv.storeSettings;
    
    final String namaToko = settingsProv.namaToko.isNotEmpty ? settingsProv.namaToko.toUpperCase() : 'NAMA TOKO';
    final String subHeader = storeSettings?['header_nama_toko'] ?? '';
    final String headerHp = storeSettings?['header_hp'] ?? '';
    final String footerNota = storeSettings?['footer_nota'] ?? '';
    
    final bool showNamaKasir = storeSettings?['show_nama_kasir'] ?? true;
    final bool showFooter = storeSettings?['show_footer_nota'] ?? true;
    final String paperSize = storeSettings?['paper_size'] ?? '58 mm';
    
    final int printWidth = (paperSize == '80 mm') ? 48 : 32;

    final String nota = (widget.order['nota_number'] ?? 'LNDR-${(widget.order['id'] ?? 0).toString().padLeft(5, '0')}').toString();
    final String customerName = (widget.order['customer_name'] ?? 'Pelanggan').toString();
    final String kasirName = (widget.order['kasir_name'] ?? widget.order['user_name'] ?? 'Admin').toString();
    final String parfum = (widget.order['parfum'] ?? 'Standard').toString();
    final String paymentStatus = (widget.order['status_pembayaran'] ?? widget.order['payment_status'] ?? 'Belum Lunas').toString();
    final String createdDate = _formatTanggal(widget.order['created_at']);
    final String estDate = _formatTanggal(widget.order['estimated_at']);
    final String notes = (widget.order['catatan'] ?? widget.order['notes'] ?? '-').toString();
    final num totalPrice = num.tryParse(widget.order['total_price']?.toString() ?? '0') ?? 0;
    final num discount = num.tryParse(widget.order['discount']?.toString() ?? '0') ?? 0;
    final num subTotal = totalPrice + discount;

    final List<Map<String, dynamic>> itemsList = _getItemsList();
    final String lineDivider = '-' * printWidth;
    final String doubleDivider = '=' * printWidth;

    StringBuffer sb = StringBuffer();

    // 🟢 INIT PRINTER & FONT (Kunci Perbaikan Tampilan)
    sb.write("\x1B\x40");       // Reset printer ke pengaturan awal
    sb.write("\x1B\x21\x00");   // Normal print mode (matikan mode condensed/kecil)
    sb.write("\x1B\x4D\x00");   // Pilih Font A (12x24) -> Lebih tebal, lebar, dan pas mengisi batas ujung 58mm
    
    sb.writeln("\n");

    if (isCustomerMode) {
      sb.write("\x1B\x61\x01"); // Align Center
      sb.write("\x1D\x21\x11"); // Double size text
      sb.writeln(namaToko);
      sb.write("\x1D\x21\x00"); // Reset size
      
      if (subHeader.isNotEmpty) sb.writeln(subHeader);
      if (headerHp.isNotEmpty && headerHp != '{{HP :}}') sb.writeln("NO. HP: $headerHp");
      
      sb.write("\x1B\x61\x00"); // Align Left
      sb.writeln(lineDivider);
      
      sb.write("\x1B\x61\x01"); // Align Center
      sb.write("\x1B\x45\x01"); // Bold ON
      sb.writeln(customerName.toUpperCase());
      sb.write("\x1B\x45\x00"); // Bold OFF
      sb.writeln(nota);
      sb.write("\x1B\x61\x00"); // Align Left
      
      if (showNamaKasir) {
        sb.writeln(_formatTwoColumns("Kasir:", kasirName, width: printWidth));
      }
      sb.writeln();
      sb.writeln(_formatTwoColumns("Tgl Masuk", createdDate, width: printWidth));
      sb.writeln(_formatTwoColumns("Est. Selesai", estDate, width: printWidth));
      sb.writeln(lineDivider);
      
      for (var item in itemsList) {
        final name = (item['service_name'] ?? item['name'] ?? 'Layanan').toString();
        final unit = (item['unit'] ?? 'Kg').toString();
        final rawQty = num.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
        final formattedQty = (rawQty % 1 == 0) ? rawQty.toInt().toString() : rawQty.toStringAsFixed(2);
        
        // 🟢 Item layanan ditebalkan sedikit agar menonjol dari info lainnya
        sb.write("\x1B\x45\x01"); // Bold ON
        sb.writeln(_formatTwoColumns(name, "$formattedQty $unit", width: printWidth));
        sb.write("\x1B\x45\x00"); // Bold OFF
      }
      sb.writeln(lineDivider);
      
      sb.writeln(_formatTwoColumns("Parfum:", parfum, width: printWidth));
      sb.writeln(_formatTwoColumns("STATUS:", paymentStatus.toUpperCase(), width: printWidth));
      if (notes != '-' && notes.isNotEmpty) {
        sb.writeln("(Ket: $notes)");
      }
      sb.writeln(lineDivider);
      
      sb.writeln(_formatTwoColumns("Sub Total", _formatRupiah(subTotal), width: printWidth));
      sb.writeln(_formatTwoColumns("Discount", _formatRupiah(discount), width: printWidth));
      
      sb.write("\x1B\x45\x01"); // Bold ON untuk Total
      sb.writeln(_formatTwoColumns("TOTAL", _formatRupiah(totalPrice), width: printWidth));
      sb.write("\x1B\x45\x00"); // Bold OFF
      sb.writeln(lineDivider);
      
      sb.write("\x1B\x61\x01"); // Align Center
      if (showFooter && footerNota.isNotEmpty) {
        sb.writeln(footerNota);
        sb.writeln();
      }
      sb.writeln("**** TERIMA KASIH ****");
      sb.write("\x1B\x61\x00"); // Align Left
      sb.writeln("\n\n");
    } else {
      sb.write("\x1B\x61\x01");
      sb.writeln("[ NOTA PRODUKSI / WORKSHOP ]");
      sb.writeln();
      
      sb.write("\x1D\x21\x11");
      sb.writeln(namaToko);
      sb.write("\x1D\x21\x00");
      sb.writeln(nota);
      
      sb.write("\x1B\x45\x01"); // Bold ON
      sb.writeln("Pelanggan: ${customerName.toUpperCase()}");
      sb.write("\x1B\x45\x00"); // Bold OFF
      
      sb.write("\x1B\x61\x00");
      sb.writeln(doubleDivider);
      
      for (var item in itemsList) {
        final name = (item['service_name'] ?? item['name'] ?? 'Layanan').toString();
        final unit = (item['unit'] ?? 'Pcs').toString();
        final rawQty = num.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
        final formattedQty = (rawQty % 1 == 0) ? rawQty.toInt().toString() : rawQty.toStringAsFixed(2);

        sb.write("\x1B\x45\x01"); // Bold ON
        sb.writeln(_formatTwoColumns(name, "[$formattedQty $unit]", width: printWidth));
        sb.write("\x1B\x45\x00"); // Bold OFF
      }
      sb.writeln(doubleDivider);
      
      sb.writeln(_formatTwoColumns("PARFUM:", parfum.toUpperCase(), width: printWidth));
      sb.writeln(_formatTwoColumns("TGL MASUK:", createdDate, width: printWidth));
      sb.writeln(_formatTwoColumns("DEADLINE:", estDate, width: printWidth));
      sb.writeln("CATATAN PRODUKSI:\n$notes");
      sb.writeln("$doubleDivider\n\n");
    }

    bool result = await PrintBluetoothThermal.writeString(
      printText: PrintTextSize(size: 1, text: sb.toString()),
    );

    if (!result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim data ke mesin printer!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sisa widget UI Dialog tetap dipertahankan sama persis...
    final settingsProv = context.watch<SettingsProvider>();
    final storeSettings = settingsProv.storeSettings;

    final String namaTokoHeader = settingsProv.namaToko.isNotEmpty
        ? settingsProv.namaToko.toUpperCase()
        : 'NAMA TOKO';
    final String subHeader = storeSettings?['header_nama_toko'] ?? '';
    final String footerNota = storeSettings?['footer_nota'] ?? '';
    final bool showFooterNota = storeSettings?['show_footer_nota'] ?? true;

    final String nota = (widget.order['nota_number'] ?? 'LNDR-${(widget.order['id'] ?? 0).toString().padLeft(5, '0')}').toString();
    final String customerName = (widget.order['customer_name'] ?? 'Pelanggan').toString();
    final String customerPhone = (widget.order['customer_phone'] ?? '-').toString();
    final String parfum = (widget.order['parfum'] ?? 'Standard').toString();
    final String paymentStatus = (widget.order['status_pembayaran'] ?? widget.order['payment_status'] ?? 'Belum Lunas').toString();
    final String createdDate = _formatTanggal(widget.order['created_at']);
    final String estDate = _formatTanggal(widget.order['estimated_at']);
    final String notes = (widget.order['catatan'] ?? widget.order['notes'] ?? '-').toString();
    final num totalPrice = num.tryParse(widget.order['total_price']?.toString() ?? '0') ?? 0;

    final List<Map<String, dynamic>> itemsList = _getItemsList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: _selectedMode == 'customer'
                  ? _buildCustomerReceipt(
                      namaToko: namaTokoHeader,
                      subHeader: subHeader,
                      footerNota: footerNota,
                      showFooter: showFooterNota,
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
                      namaToko: namaTokoHeader,
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

            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMode == 'customer' ? Colors.blue : Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final isCustomer = _selectedMode == 'customer';
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mengirim ${isCustomer ? 'Nota Customer' : 'Nota Produksi'} ke Printer...',
                      ),
                    ),
                  );
                  await _printReceiptToBluetooth(context, isCustomer);
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

  Widget _buildCustomerReceipt({
    required String namaToko,
    required String subHeader,
    required String footerNota,
    required bool showFooter,
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
    final num discount = num.tryParse(widget.order['discount']?.toString() ?? '0') ?? 0;
    final num subTotal = totalPrice + discount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          namaToko,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
        if (subHeader.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subHeader,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700),
          ),
        ],
        
        const SizedBox(height: 6),
        Text('---------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),

        Text(
          customerName.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          nota,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tgl Masuk', style: TextStyle(fontSize: 10)),
            Text(createdDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Est. Selesai', style: TextStyle(fontSize: 10)),
            Text(estDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),

        Text('---------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),

        ...itemsList.map((item) {
          final String name = (item['service_name'] ?? item['name'] ?? 'Layanan').toString();
          final String unit = (item['unit'] ?? 'Kg').toString();
          final rawQty = num.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
          final formattedQty = (rawQty % 1 == 0) ? rawQty.toInt().toString() : rawQty.toStringAsFixed(2);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 10))),
                Text('$formattedQty $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),

        Text('---------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),

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
            const Text('STATUS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(
              paymentStatus.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: paymentStatus.toLowerCase().contains('lunas') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (notes != '-' && notes.isNotEmpty) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('(Ket: $notes)', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black87)),
          ),
        ],

        Text('---------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sub Total', style: TextStyle(fontSize: 10)),
            Text(_formatRupiah(subTotal), style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Discount', style: TextStyle(fontSize: 10)),
            Text(_formatRupiah(discount), style: const TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(_formatRupiah(totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),

        Text('---------------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),

        if (showFooter && footerNota.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            footerNota,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
        ],

        const SizedBox(height: 4),
        const Text(
          '**** TERIMA KASIH ****',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildProduksiReceipt({
    required String namaToko,
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
        Text(namaToko, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(nota, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text('Pelanggan: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.grey)),

        ...itemsList.map((item) {
          final String name = (item['service_name'] ?? item['name'] ?? 'Layanan').toString();
          final String unit = (item['unit'] ?? 'Pcs').toString();
          final rawQty = num.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
          final formattedQty = (rawQty % 1 == 0) ? rawQty.toInt().toString() : rawQty.toStringAsFixed(2);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(4)),
                  child: Text('$formattedQty $unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
