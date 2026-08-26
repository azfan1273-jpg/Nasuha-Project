import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import '../widgets/order_detail_dialog.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({Key? key}) : super(key: key);

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final List<Map<String, dynamic>> _allOrders = [];
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'PENDING';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // AMBIL DATA TERISOLASI BERDASARKAN STORE_ID
    Future<void> _fetchOrders() async {
      if (!mounted) return;
      setState(() => _isLoading = true);
  
      try {
        // 1. Ambil store_id langsung dari SettingsProvider
        final currentStoreId = context.read<SettingsProvider>().storeId;
  
        if (currentStoreId == null) {
          debugPrint('Log: store_id tidak ditemukan');
          return;
        }
  
        // 2. Ambil data orders berdasarkan store_id
        final List<dynamic> data = await supabase
            .from('orders')
            .select('*, order_items(*)')
            .eq('store_id', currentStoreId)
            .order('created_at', ascending: false);
  
        if (mounted) {
          setState(() {
            _allOrders.clear();
            _allOrders.addAll(List<Map<String, dynamic>>.from(data));
          });
        }
      } catch (e) {
        debugPrint('Error fetch orders: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

  // HITUNG JUMLAH ORDER UNTUK COUNTER TAB
  int _countOrdersByStatus(String filterKey) {
    return _allOrders.where((order) {
      final status = (order['status'] ?? 'BARU').toString().toUpperCase();
      switch (filterKey) {
        case 'PENDING':
          return status == 'ANTRIAN' || status == 'BARU' || status == 'PENDING';
        case 'PREPARED':
          return status == 'PROSES' || status == 'PREPARED';
        case 'DELIVERED':
          return status == 'SELESAI' || status == 'DELIVERED';
        default:
          return false;
      }
    }).length;
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _allOrders.where((order) {
      final name = (order['customer_name'] ?? '').toString().toLowerCase();
      final phone = (order['customer_phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(query) || phone.contains(query);

      if (!matchesSearch) return false;

      final status = (order['status'] ?? 'BARU').toString().toUpperCase();

      switch (_selectedFilter) {
        case 'PENDING':
          return status == 'ANTRIAN' || status == 'BARU' || status == 'PENDING';
        case 'PREPARED':
          return status == 'PROSES' || status == 'PREPARED';
        case 'DELIVERED':
          return status == 'SELESAI' || status == 'DELIVERED';
        default:
          return true;
      }
    }).toList();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: settings.bgDark,
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // SEARCH BAR TOP
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13, color: settings.textColor),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search orders',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.black45),
                      prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // HORIZONTAL TAB FILTER (PENDING, PREPARED, DELIVERED)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('PENDING', 'Pending', settings),
                      _buildTabButton('PREPARED', 'Prepared', settings),
                      _buildTabButton('DELIVERED', 'Delivered', settings),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // LIST ORDER DATA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: settings.accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? const Center(
                          child: Text(
                            '(Belum Ada Data)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black38,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          color: settings.accentColor,
                          child: ListView.builder(
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final item = _filteredOrders[index];
                              return _buildOrderCardBar(item);
                            },
                          ),
                        ),
            ),
          ),
          
          // TOMBOL MENU TRANSAKSI
          _buildTransactionButton(settings),
        ],
      ),
    );
  }

  Widget _buildTabButton(String filterKey, String label, SettingsProvider settings) {
    final bool isSelected = _selectedFilter == filterKey;
    final int count = _countOrdersByStatus(filterKey);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filterKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardBar(Map<String, dynamic> item) {
    final String customerName = (item['customer_name'] ?? item['nama_pelanggan'] ?? 'Pelanggan').toString();
    final num totalPrice = num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;

    int serviceCount = 0;
    if (item['order_items'] is List && (item['order_items'] as List).isNotEmpty) {
      serviceCount = (item['order_items'] as List).length;
    } else if (item['service_name'] != null && item['service_name'].toString().isNotEmpty) {
      serviceCount = item['service_name'].toString().split(',').length;
    }
    final String serviceText = '$serviceCount layanan';

    String estText = 'Est: -';
    final dynamic rawEst = item['estimated_at'] ?? item['estimasi_selesai'] ?? item['estimasi'];
    
    if (rawEst != null && rawEst.toString().isNotEmpty && rawEst.toString() != 'null') {
      try {
        final targetDate = DateTime.parse(rawEst.toString());
        estText = 'Est: ${_formatTanggal(targetDate.toIso8601String())}';
      } catch (_) {}
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => OrderDetailDialog(
            order: item,
            onOrderUpdated: _fetchOrders,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionButton(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: settings.accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BuatOrderDialog(
                onOrderCreated: _fetchOrders,
              ),
            );
          },
          icon: const Icon(Icons.list_alt_rounded, size: 20),
          label: const Text(
            'MENU TRANSAKSI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
