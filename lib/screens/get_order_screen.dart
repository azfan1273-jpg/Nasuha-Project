import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

class GetOrderScreen extends StatefulWidget {
  const GetOrderScreen({super.key});

  @override
  State<GetOrderScreen> createState() => _GetOrderScreenState();
}

class _GetOrderScreenState extends State<GetOrderScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    _loadOnlineOrders();
  }

  Future<void> _loadOnlineOrders() async {
    setState(() => _isLoading = true);
    
    try {
      // note: Ambil storeId dari SettingsProvider untuk mencegah kebocoran data antar toko
      final storeId = context.read<SettingsProvider>().storeId;
      
      if (storeId == null || storeId.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store ID tidak ditemukan. Silakan login ulang.')),
          );
        }
        return;
      }

      // note: Tambahkan .eq('store_id', storeId) agar hanya menarik pesanan untuk toko ini saja
      final data = await Supabase.instance.client
          .from('online_orders')
          .select()
          .eq('store_id', storeId) 
          .eq('status', _filterStatus)
          .order('created_at', ascending: false);
      
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: $e')),
        );
      }
    }
  }

  Future<void> _prosesPesanan(Map<String, dynamic> order) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proses Pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${order['customer_name']}'),
            Text('Layanan: ${order['service_name']}'),
            Text('Parfum: ${order['parfum'] ?? '-'}'),
            if (order['notes'] != null && order['notes'].isNotEmpty)
              Text('Catatan: ${order['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final now = DateTime.now();
      // GANTI INI:
      // final orderCode = 'NSH-${now.year}${now.month.toString().padLeft(2, '0')}...';
      
      // JADI INI (Pake Inisial Nama Pelanggan):
      final customerName = order['customer_name']?.toString() ?? 'PEL';
      final cleanName = customerName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
      final prefix = cleanName.length >= 3 
          ? cleanName.substring(cleanName.length - 3) 
          : cleanName.padRight(3, 'X');
          
      final orderCode = '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';      
	  final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
	  final discount = (order['discount'] as num?)?.toDouble() ?? 0.0;
	  final totalPrice = (subtotal - discount).round(); // ✅ ROUND FINAL
	  
	  
      await Supabase.instance.client.from('orders').insert({
        'order_code': orderCode,
        'customer_name': order['customer_name'],
        'customer_phone': order['customer_phone'],
        'service_name': order['service_name'],
        'parfum': order['parfum'] ?? '',
        'notes': order['notes'] ?? '',
        'status': 'Antrian',
        'subtotal': subtotal.round(),      // ✅ ROUND
        'discount': discount.round(),       // ✅ ROUND
        'total_price': totalPrice,          // ✅ SUDAH DI-ROUND
        'status_pembayaran': 'Belum Lunas',
        'store_id': order['store_id'],
        'created_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client
          .from('online_orders')
          .update({'status': 'PROCESSED'})
          .eq('id', order['id']);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pesanan berhasil diproses!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadOnlineOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pesanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return Scaffold(
      // note: AppBar disesuaikan dengan tema - lebih kecil dan warnanya pakai accentColor dengan opacity
      appBar: AppBar(
        title: const Text('Pesanan Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: settings.accentColor.withOpacity(0.15),
        elevation: 0,
        foregroundColor: settings.textColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: settings.accentColor),
            onPressed: _loadOnlineOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs - disesuaikan dengan tema
          Container(
            padding: const EdgeInsets.all(12),
            color: settings.cardDark,
            child: Row(
              children: ['PENDING', 'Semua'].map((status) {
                final isSelected = _filterStatus == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _filterStatus = status);
                        _loadOnlineOrders();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? settings.accentColor : settings.bgDark,
                        foregroundColor: isSelected ? Colors.white : settings.textColor,
                        elevation: 0,
                      ),
                      child: Text(status),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // List Pesanan
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: settings.accentColor))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: settings.textColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesanan masuk',
                              style: TextStyle(
                                color: settings.textColor.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadOnlineOrders(),
                        color: settings.accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              color: settings.cardDark,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: settings.accentColor.withOpacity(0.2),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: settings.accentColor,
                                  ),
                                ),
                                title: Text(
                                  order['customer_name'] ?? 'Tanpa Nama',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: settings.textColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order['service_name']}',
                                      style: TextStyle(color: settings.textColor.withOpacity(0.7)),
                                    ),
                                    if (order['parfum'] != null)
                                      Text(
                                        'Parfum: ${order['parfum']}',
                                        style: TextStyle(color: settings.textColor.withOpacity(0.7)),
                                      ),
                                    Text(
                                      '📱 ${order['customer_phone']}',
                                      style: TextStyle(color: settings.textColor.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _prosesPesanan(order),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: settings.accentColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Proses'),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
