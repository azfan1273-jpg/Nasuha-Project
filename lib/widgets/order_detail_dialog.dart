import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_method_dialog.dart';

class OrderDetailDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onOrderUpdated;

  const OrderDetailDialog({
    super.key,
    required this.order,
    this.onOrderUpdated,
  });

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

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', order['id']);

      if (context.mounted) {
        Navigator.pop(context);
        onOrderUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status order diperbarui ke $newStatus')),
        );
      }
    } catch (e) {
      debugPrint('Error update status: $e');
    }
  }

  // MENAMBAHKAN PARAMETER method UNTUK MENGISI KOLOM metode_pembayaran DI SUPABASE
   Future<void> _updatePayment(BuildContext context, String method) async {
     try {
       await Supabase.instance.client
           .from('orders')
           .update({
             'status_pembayaran': 'Lunas',
             'metode_pembayaran': method,
           })
           .eq('id', order['id']);
 
       if (context.mounted) {
         Navigator.pop(context);
         onOrderUpdated?.call();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Pembayaran ($method) berhasil dicatat LUNAS!')),
         );
       }
     } catch (e) {
       debugPrint('Error update pembayaran: $e');
     }
   }

  Future<void> _sendWaNotification(BuildContext context) async {
    String rawPhone = (order['customer_phone'] ?? '').toString().trim();
    if (rawPhone.startsWith('0')) {
      rawPhone = '62${rawPhone.substring(1)}';
    }

    final String name = (order['customer_name'] ?? 'Pelanggan').toString();
    final String nota = (order['nota_number'] ?? order['id'] ?? '').toString();
    final String message = 'Halo $name, order laundry Anda dengan nota *$nota* sudah *SELESAI* dan siap diambil. Terima kasih!';

    final Uri url = Uri.parse('https://wa.me/$rawPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka WhatsApp')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launch WA: $e');
    }
  }

	// METHOD BARU: MEMANGGIL STANDALONE DIALOG DAN MENUNGGU HASIL KEMBALIAN (RETURN VALUE)
	  Future<void> _handlePaymentProcess(BuildContext context) async {
	    final String? selectedMethod = await showDialog<String>(
	      context: context,
	      builder: (context) => const PaymentMethodDialog(),
	    );

	    // Jika pengguna menekan KONFIRMASI (selectedMethod tidak null)
	    if (selectedMethod != null && context.mounted) {
	      _updatePayment(context, selectedMethod);
	    }
	  }

  @override
  Widget build(BuildContext context) {
    // Conversion aman agar tidak pemicu Type Error
    final String nota = (order['nota_number'] ?? 'LNDR-${(order['id'] ?? 0).toString().padLeft(5, '0')}').toString();
    final String customerName = (order['customer_name'] ?? 'Pelanggan').toString();
    final String customerPhone = (order['customer_phone'] ?? '-').toString();
    final String parfum = (order['parfum'] ?? 'Standard').toString();
    final String paymentStatus = (order['status_pembayaran'] ?? order['payment_status'] ?? 'Belum Lunas').toString();
    final String createdDate = _formatTanggal(order['created_at']);
    final String estDate = _formatTanggal(order['estimated_at']);
    final String notes = (order['catatan'] ?? order['notes'] ?? 'Tidak ada catatan').toString();
    final num totalPrice = num.tryParse(order['total_price']?.toString() ?? '0') ?? 0;

    // Menarik rincian item dengan proteksi tipe data
    final List<dynamic> itemsFromDb = order['order_items'] is List ? order['order_items'] : [];
    final List<Map<String, dynamic>> itemsList = [];

    if (itemsFromDb.isNotEmpty) {
      for (var item in itemsFromDb) {
        if (item is Map) {
          itemsList.add(Map<String, dynamic>.from(item));
        }
      }
    } else {
      final String rawServices = (order['service_name'] ?? '').toString();
      for (var s in rawServices.split(',')) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) {
          itemsList.add({'service_name': trimmed, 'qty': 1});
        }
      }
    }

    // Penentuan alur status tombol
    final String status = (order['status'] ?? 'ANTRIAN').toString().toUpperCase();
    String actionLabel = 'Proses Order';
    Color actionColor = Colors.orange;
    IconData actionIcon = Icons.play_arrow_rounded;

    if (status == 'PROSES') {
      actionLabel = 'Tandai Selesai Order';
      actionColor = Colors.blue;
      actionIcon = Icons.check_circle;
    } else if (status == 'SELESAI') {
      actionLabel = 'Order Sudah Selesai';
      actionColor = Colors.green;
      actionIcon = Icons.verified;
    } else if (status == 'BATAL' || status == 'CANCEL') {
      actionLabel = 'Order Dibatalkan';
      actionColor = Colors.grey;
      actionIcon = Icons.cancel;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        // DIBERI CONSTRAINT MAX HEIGHT AGAR TIDAK MELUAP/CRASH
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detail Order Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Nota $nota', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Layanan / Items dengan Parsing Satuan Dinamis
                _buildDetailTile(
                  title: 'DAFTAR LAYANAN / ITEM',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: itemsList.isEmpty
                        ? [const Text('-', style: TextStyle(fontSize: 12))]
                        : itemsList.map((item) {
                            String rawName = (item['service_name'] ?? 'Layanan').toString();
                            String displayQty = '';
              
                            // Prioritaskan kolom 'unit' dari database order_items
                            final String itemUnit = (item['unit'] != null && item['unit'].toString().isNotEmpty)
                                ? item['unit'].toString()
                                : 'Pcs';
            
                            if (item.containsKey('qty') && item['qty'] != null) {
                              final num qty = num.tryParse(item['qty'].toString()) ?? 1;
                              final String formattedQty = (qty % 1 == 0) ? qty.toInt().toString() : qty.toString();
                              displayQty = '$formattedQty $itemUnit';
                            }
              
               // 2. Jika format string dari data lama mengandung tanda kurung, misal: "Cuci Komplit (5.55 Kg)"
               if (rawName.contains('(') && rawName.contains(')')) {
                 final parts = rawName.split('(');
                 rawName = parts[0].trim();
                 final insideParen = parts[1].replaceAll(')', '').trim();
                 if (displayQty.isEmpty) {
                   displayQty = insideParen;
                 }
               }
 
               if (displayQty.isEmpty) displayQty = '1 Pcs';
 
               return Padding(
                 padding: const EdgeInsets.symmetric(vertical: 3),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(
                         rawName,
                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                       ),
                     ),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade200,
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                         displayQty,
                         style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                       ),
                     ),
                   ],
                 ),
               );
             }).toList(),
           ),
         ),
              const SizedBox(height: 8),

              // Parfum & Status Bayar
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      title: 'AROMA PARFUM',
                      child: Text(parfum, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailTile(
                      title: 'STATUS PEMBAYARAN',
                      child: Text(
                        paymentStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: paymentStatus.toUpperCase() == 'LUNAS' ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tanggal Masuk & Estimasi
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      title: 'TANGGAL MASUK',
                      child: Text(createdDate, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailTile(
                      title: 'ESTIMASI SELESAI',
                      child: Text(estDate, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Catatan
              _buildDetailTile(
                title: 'CATATAN ORDER',
                child: Text(notes, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),

              // Tombol Main Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: actionColor),
                  onPressed: (status == 'SELESAI' || status == 'BATAL' || status == 'CANCEL')
                      ? null
                      : () {
                          final nextStatus = status == 'PROSES' ? 'SELESAI' : 'PROSES';
                          _updateStatus(context, nextStatus);
                        },
                  icon: Icon(actionIcon, size: 16, color: Colors.white),
                  label: Text(actionLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 6),

              // Tombol WA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                  onPressed: () => _sendWaNotification(context),
                  icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                  label: const Text('Kirim WA Notifikasi Selesai', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 6),

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  onPressed: (status == 'BATAL' || status == 'CANCEL') ? null : () => _updateStatus(context, 'BATAL'),
                  icon: const Icon(Icons.close, size: 14, color: Colors.red),
                  label: const Text('Batalkan Order', style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 12),

              // Footer Total & Bayar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PRICE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(_formatRupiah(totalPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    // MEMANGGIL DIALOG METODE BAYAR DAHULU SEBELUM MENG-UPDATE DATABASE
                    onPressed: paymentStatus.toUpperCase() == 'LUNAS' ? null : () => _handlePaymentProcess(context),
                    child: Text(
                      paymentStatus.toUpperCase() == 'LUNAS' ? 'LUNAS' : 'BAYAR',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
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

  Widget _buildDetailTile({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
