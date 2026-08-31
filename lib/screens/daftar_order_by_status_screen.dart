import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../providers/settings_provider.dart';

class DaftarOrderByStatusScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> orders;

  const DaftarOrderByStatusScreen({
    super.key,
    required this.title,
    required this.orders,
  });

  @override
  State<DaftarOrderByStatusScreen> createState() => _DaftarOrderByStatusScreenState();
}

class _DaftarOrderByStatusScreenState extends State<DaftarOrderByStatusScreen> {
  late List<Map<String, dynamic>> _currentOrders;

  @override
  void initState() {
    super.initState();
    _currentOrders = List<Map<String, dynamic>>.from(widget.orders);
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

 // 🟢 1. TAMBAHKAN PARAMETER OPTIONAL metodePembayaran
   Future<void> _updateStatus(Map<String, dynamic> order, String newStatus, {String? metodePembayaran}) async {
     try {
       final storeId = context.read<SettingsProvider>().storeId;
       if (storeId == null) return;
 
       final orderId = int.tryParse(order['id'].toString());
       if (orderId == null) return;
 
       // 🟢 Wajib melempar p_metode_pembayaran ke RPC
       await supabase.rpc('update_order_status_by_store', params: {
         'p_order_id': orderId,
         'p_store_id': storeId,
         'p_new_status': newStatus,
         'p_metode_pembayaran': metodePembayaran, 
       });
 
       if (mounted) {
         setState(() {
           order['status'] = newStatus;
           if (metodePembayaran != null) {
             order['metode_pembayaran'] = metodePembayaran;
             order['status_pembayaran'] = 'Lunas';
           }
         });
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Status berhasil diubah ke "$newStatus"'),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 2),
           ),
         );
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
 
   // 🟢 2. DIALOG PILIH STATUS
   void _showPilihStatusDialog(Map<String, dynamic> order) {
     final List<String> statusList = ['Proses', 'Siap Ambil', 'Selesai', 'Batal'];
 
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
             final isCurrent = order['status'] == status;
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
                   // Jika status diubah ke Selesai / Pelunasan, tampilkan pilihan pembayaran
                   if (status == 'Selesai') {
                     _showPilihMetodePembayaranDialog(order, status);
                   } else {
                     _updateStatus(order, status);
                   }
                 }
               },
             );
           }).toList(),
         ),
       ),
     );
   }
 
   // 🟢 3. DIALOG PILIH METODE PEMBAYARAN (BARU)
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
      body: _currentOrders.isEmpty
          ? const Center(child: Text('Tidak ada orderan pada kategori ini.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _currentOrders.length,
              itemBuilder: (context, index) {
                final order = _currentOrders[index];
                final num totalPrice = num.tryParse((order['total_price'] ?? order['total'] ?? '0').toString()) ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      order['customer'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(order['services'] ?? '-'),
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
    );
  }
}
