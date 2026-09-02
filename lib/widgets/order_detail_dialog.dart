import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_method_dialog.dart';
import 'nota_dialog.dart';

class OrderDetailDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onOrderUpdated;

  const OrderDetailDialog({
    super.key,
    required this.order,
    this.onOrderUpdated,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  late Map<String, dynamic> _currentOrder;
  bool _isLoadingItems = false;
  List<dynamic> _fetchedItems = [];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _fetchOrderItemsIfNeeded();
  }

  Future<void> _fetchOrderItemsIfNeeded() async {
    final existingItems = _currentOrder['order_items'] ?? _currentOrder['items'];
    if (existingItems is List && existingItems.isNotEmpty) {
      setState(() => _fetchedItems = existingItems);
      return;
    }

    setState(() => _isLoadingItems = true);
    try {
      final orderId = _currentOrder['id'];
      final response = await Supabase.instance.client
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);

      if (mounted && response != null) {
        setState(() {
          _fetchedItems = response;
          _currentOrder['order_items'] = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetch order items mandiri: $e');
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
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
          .eq('id', _currentOrder['id']);

      if (context.mounted) {
        widget.onOrderUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status order diperbarui ke $newStatus')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error update status: $e');
    }
  }

  Future<void> _updatePayment(BuildContext context, String method) async {
    try {
      final orderId = int.tryParse(_currentOrder['id'].toString());
      if (orderId == null) return;

      await Supabase.instance.client.rpc('update_order_status_by_store', params: {
        'p_order_id': orderId,
        'p_store_id': _currentOrder['store_id']?.toString() ?? '',
        'p_new_status': _currentOrder['status'] ?? 'Selesai',
        'p_metode_pembayaran': method,
      });

      if (context.mounted) {
        widget.onOrderUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran ($method) berhasil dicatat LUNAS!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error update pembayaran: $e');
    }
  }

  Future<void> _sendWaNotification(BuildContext context) async {
    String rawPhone = (_currentOrder['customer_phone'] ?? '').toString().trim();
    if (rawPhone.startsWith('0')) {
      rawPhone = '62${rawPhone.substring(1)}';
    }
    final String name = (_currentOrder['customer_name'] ?? 'Pelanggan').toString();
    final String nota = (_currentOrder['nota_number'] ?? _currentOrder['id'] ?? '').toString();
    final String message = 'Halo $name, order laundry Anda dengan nota *$nota* sudah *SELESAI* dan siap diambil. Terima kasih!';
    final Uri url = Uri.parse('https://wa.me/$rawPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launch WA: $e');
    }
  }

  Future<void> _handlePaymentProcess(BuildContext context) async {
    final String? selectedMethod = await showDialog<String>(
      context: context,
      builder: (context) => const PaymentMethodDialog(),
    );

    if (selectedMethod != null && context.mounted) {
      _updatePayment(context, selectedMethod);
    }
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => NotaDialog(order: _currentOrder),
    );
  }

  void _showKonfirmasiBatalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Batalkan Transaksi?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan orderan ini? Status akan diubah menjadi "BATAL".',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _updateStatus(context, 'BATAL');
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nota = (_currentOrder['nota_number'] ?? 'LNDR-${(_currentOrder['id'] ?? 0).toString().padLeft(5, '0')}').toString();
    final String customerName = (_currentOrder['customer_name'] ?? _currentOrder['customer'] ?? 'Pelanggan').toString();
    final String customerPhone = (_currentOrder['customer_phone'] ?? '-').toString();
    final String parfum = (_currentOrder['parfum'] ?? 'Standard').toString();
    
    final String paymentStatus = (_currentOrder['status_pembayaran'] ?? _currentOrder['payment_status'] ?? 'Belum Lunas').toString().trim();
    final bool isLunas = paymentStatus.toUpperCase() == 'LUNAS';

    final String createdDate = _formatTanggal(_currentOrder['created_at']);
    final String estDate = _formatTanggal(_currentOrder['estimated_at']);
    final String notes = (_currentOrder['catatan'] ?? _currentOrder['notes'] ?? 'Tidak ada catatan').toString();
    final num totalPrice = num.tryParse((_currentOrder['total_price'] ?? _currentOrder['total'] ?? '0').toString()) ?? 0;

    final List<Map<String, dynamic>> itemsList = [];
    if (_fetchedItems.isNotEmpty) {
      for (var item in _fetchedItems) {
        if (item is Map) {
          itemsList.add(Map<String, dynamic>.from(item));
        }
      }
    } else {
      final String rawServices = (_currentOrder['services'] ?? _currentOrder['service_name'] ?? '').toString();
      for (var s in rawServices.split(',')) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) {
          itemsList.add({'service_name': trimmed, 'qty': 1, 'unit': 'Kg'});
        }
      }
    }

    final String status = (_currentOrder['status'] ?? 'ANTRIAN').toString().toUpperCase();
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
    } else if (status == 'BATAL') {
      actionLabel = 'Order Dibatalkan';
      actionColor = Colors.grey;
      actionIcon = Icons.cancel;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Order Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.blue),
            tooltip: 'Cetak Struk',
            onPressed: () => _showPrintDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No. HP: $customerPhone',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Nota: $nota',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showPrintDialog(context),
                    icon: const Icon(Icons.print, color: Colors.blue),
                    tooltip: 'Cetak Struk',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailTile(
              title: 'DAFTAR LAYANAN / ITEM',
              child: _isLoadingItems
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: itemsList.isEmpty
                          ? [const Text('-', style: TextStyle(fontSize: 12))]
                          : itemsList.map((item) {
                              final String rawName = (item['service_name'] ?? item['name'] ?? 'Layanan').toString();
                              final String itemUnit = (item['unit'] != null && item['unit'].toString().isNotEmpty)
                                  ? item['unit'].toString()
                                  : 'Kg';

                              final num rawQty = num.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
                              final String formattedQty = (rawQty % 1 == 0) ? rawQty.toInt().toString() : rawQty.toStringAsFixed(2);
                              final String displayQty = '$formattedQty $itemUnit';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rawName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        displayQty,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailTile(
                    title: 'AROMA PARFUM',
                    child: Text(parfum, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDetailTile(
                    title: 'STATUS PEMBAYARAN',
                    child: Text(
                      paymentStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLunas ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDetailTile(
                    title: 'TANGGAL MASUK',
                    child: Text(createdDate, style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDetailTile(
                    title: 'ESTIMASI SELESAI',
                    child: Text(estDate, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDetailTile(
              title: 'CATATAN ORDER',
              child: Text(notes, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 20),
            
            // 1. Tombol Utama Status Order
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (status == 'SELESAI' || status == 'BATAL')
                    ? null
                    : () {
                        final nextStatus = status == 'PROSES' ? 'SELESAI' : 'PROSES';
                        _updateStatus(context, nextStatus);
                      },
                icon: Icon(actionIcon, size: 18, color: Colors.white),
                label: Text(
                  actionLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Tombol WhatsApp
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _sendWaNotification(context),
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: const Text('Kirim WA Notifikasi Selesai', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),

            // 3. Tombol Batalkan Order
            if (status != 'BATAL' && status != 'SELESAI') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showKonfirmasiBatalDialog(context),
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  label: const Text(
                    'Batalkan Order',
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      // 🟢 TOTAL PRICE & BAYAR DIBIKIN FIXED DI PALING BAWAH
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL PRICE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(_formatRupiah(totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLunas ? Colors.grey : const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isLunas ? null : () => _handlePaymentProcess(context),
                child: Text(
                  isLunas ? 'LUNAS' : 'BAYAR',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
