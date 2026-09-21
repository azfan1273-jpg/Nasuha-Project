import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/order_detail_dialog.dart';

class DaftarOrderByStatusScreen extends StatefulWidget {
  final String title;
  final String categoryKey;

  const DaftarOrderByStatusScreen({
    super.key,
    required this.title,
    required this.categoryKey,
  });

  @override
  State<DaftarOrderByStatusScreen> createState() => _DaftarOrderByStatusScreenState();
}

class _DaftarOrderByStatusScreenState extends State<DaftarOrderByStatusScreen> {
  List<Map<String, dynamic>> _currentOrders = [];
  bool _isLoading = true;

  // 🟢 BARU: jumlah order yang tampil di layar (mulai 10, tambah 10 tiap klik tombol)
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // 🟢 BARU: potongan list yang BOLEH tampil (dibatasi _visibleCount)
  List<Map<String, dynamic>> get _visibleOrders {
    if (_currentOrders.length <= _visibleCount) return _currentOrders;
    return _currentOrders.sublist(0, _visibleCount);
  }

  // 🟢 BARU: true kalau masih ada data yang disembunyikan (buat munculin tombol)
  bool get _hasMoreOrders => _currentOrders.length > _visibleCount;

  // 1. TARIK DATA DARI SUPABASE SAAT HALAMAN DIBUKA
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final List<dynamic> data = await supabase.rpc(
        'get_orders_by_dashboard_category',
        params: {
          'p_store_id': storeId,
          'p_category': widget.categoryKey,
        },
      );
      if (mounted) {
        setState(() {
          _currentOrders = data.map((record) {
            final item = Map<String, dynamic>.from(record);
            final name = item['customer_name'] ?? item['nama_pelanggan'] ?? 'Pelanggan';
            item['customer_name'] = name;
            item['customer'] = name;
            return item;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch category orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  // 2. UPDATE STATUS ORDER VIA RPC
  Future<void> _updateStatus(Map<String, dynamic> order, String newStatus, {String? metodePembayaran}) async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) return;
      final orderId = int.tryParse(order['id'].toString());
      if (orderId == null) return;
      await supabase.rpc('update_order_status_by_store', params: {
        'p_order_id': orderId,
        'p_store_id': storeId,
        'p_new_status': newStatus,
        'p_metode_pembayaran': metodePembayaran,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah ke "$newStatus"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      debugPrint('Error update status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. DIALOG PILIH STATUS (DENGAN REDIREKSI WAJIB BAYAR)
  void _showPilihStatusDialog(Map<String, dynamic> order) {
    final List<String> statusList = ['Antrian', 'Proses', 'Selesai', 'Batal'];
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Ubah Status Order #${order['id']}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusList.map((status) {
            final isCurrent = (order['status'] ?? '').toString().toLowerCase() == status.toLowerCase();
            return ListTile(
              title: Text(
                status,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.pink : Colors.black87,
                ),
              ),
              trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.pink) : null,
              onTap: () {
                Navigator.pop(dialogCtx);
                if (!isCurrent) {
                  // 🟢 JIKA DIUBAH KE SELESAI, CEK KETAT STATUS PEMBAYARAN
                  if (status.toLowerCase() == 'selesai') {
                    final String paymentStatus = (order['status_pembayaran'] ??
                            order['payment_status'] ??
                            '')
                        .toString()
                        .trim()
                        .toUpperCase();
                    final String rawPayment = (order['metode_pembayaran'] ??
                            order['payment_method'] ??
                            '')
                        .toString()
                        .trim()
                        .toLowerCase();

                    debugPrint('--- LOG CEK BAYAR ORDER #${order['id']} ---');
                    debugPrint('status_pembayaran: "$paymentStatus"');
                    debugPrint('metode_pembayaran: "$rawPayment"');

                    final validMethods = ['tunai', 'qris', 'transfer', 'debit', 'edc', 'cash', 'qris / transfer'];
                    final bool isLunas = paymentStatus == 'LUNAS' || validMethods.contains(rawPayment);

                    if (!isLunas) {
                      _showPilihMetodePembayaranDialog(order, status);
                      return;
                    }
                  }
                  _updateStatus(order, status);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // 4. DIALOG PILIH METODE PEMBAYARAN
  void _showPilihMetodePembayaranDialog(Map<String, dynamic> order, String newStatus) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text('Tunai'),
              onTap: () {
                Navigator.pop(dialogCtx);
                _updateStatus(order, newStatus, metodePembayaran: 'Tunai');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('QRIS / Transfer'),
              onTap: () {
                Navigator.pop(dialogCtx);
                _updateStatus(order, newStatus, metodePembayaran: 'QRIS / Transfer');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFCE7F3),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: Colors.pink,
              child: _currentOrders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada orderan pada kategori ini.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      // 🟢 UBAH: jumlah yang tampil + 1 slot tambahan buat tombol (kalau masih ada sisa)
                      itemCount: _visibleOrders.length + (_hasMoreOrders ? 1 : 0),
                      itemBuilder: (context, index) {
                        // 🟢 BARU: kalau index kena slot tambahan -> tampilin tombol Muat 10 Lagi
                        if (_hasMoreOrders && index == _visibleOrders.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.pink, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _visibleCount += 10;
                                  });
                                },
                                icon: const Icon(Icons.arrow_downward, color: Colors.pink, size: 18),
                                label: Text(
                                  'Muat 10 Lagi (sisa ${_currentOrders.length - _visibleCount})',
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // 🟢 UBAH: ambil data dari _visibleOrders (bukan _currentOrders)
                        final order = _visibleOrders[index];
                        final num totalPrice = num.tryParse((order['total_price'] ?? order['total'] ?? '0').toString()) ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => OrderDetailDialog(
                                  order: order,
                                  onOrderUpdated: () {
                                    _fetchOrders();
                                  },
                                ),
                              );
                            },
                            title: Text(
                              order['customer_name'] ?? order['nama_pelanggan'] ?? order['customer'] ?? 'Pelanggan',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['service_name'] ?? order['services'] ?? 'Layanan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (order['customer_phone'] != null &&
                                          order['customer_phone'].toString().trim().isNotEmpty &&
                                          order['customer_phone'] != '-')
                                      ? 'No. HP: ${order['customer_phone']}'
                                      : 'Nota: ${order['nota_number'] ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatRupiah(totalPrice),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      order['status'] ?? '-',
                                      style: const TextStyle(fontSize: 10, color: Colors.pink, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.pink),
                                  tooltip: 'Ubah Status',
                                  onPressed: () => _showPilihStatusDialog(order),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
