import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../main.dart';
import '../widgets/buat_order_dialog.dart';

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends State<KasirHomeScreen> {
  int _currentIndex = 0;
  int _orderFilterIndex = 0;

  final List<Map<String, dynamic>> _ordersHariIni = [];

  @override
  void initState() {
    super.initState();
    _loadOrdersFromSupabase();
  }

  Future<void> _loadOrdersFromSupabase() async {
    try {
      final List<dynamic> data = await supabase
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _ordersHariIni.clear();
          _ordersHariIni.addAll(data.map((record) {
            return {
              'id': record['id'].toString(),
              'customer': (record['customer_name'] ?? 'Pelanggan').toString(),
              'total': (record['total'] as num?)?.toDouble() ?? 0.0,
              'status': (record['status'] ?? 'Antrian').toString(),
            };
          }).toList());
        });
      }
    } catch (e) {
      debugPrint('Error load orders Supabase: $e');
    }
  }

  static const Color _bgDark = Color(0xFFFAF5F7);       
  static const Color _cardDark = Color(0xFFFCE7F3);     
  static const Color _goldAccent = Color(0xFFEC4899);   
  static const Color _textBlack = Color(0xFF111827);    

  double get _totalOmsetHariIni {
    return _ordersHariIni.fold(
      0.0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: _bgDark,
      body: Center(
        child: Container(
          width: 390,
          color: _bgDark,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // HEADER TOKO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _cardDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: _goldAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    settings.namaToko,
                                    style: const TextStyle(
                                      color: _textBlack,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _goldAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      settings.userRole,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                settings.emailToko,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: _textBlack, size: 18),
                        onPressed: _loadOrdersFromSupabase,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // BANNER PROMO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.campaign_outlined,
                              color: _goldAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Promo Cuci Komplit Diskon 10%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _goldAccent,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Berlaku sampai akhir bulan.',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _goldAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // TAB VIEW
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildBerandaTab(),
                      _buildOrderTab(),
                      const Center(
                        child: Text('Laporan', style: TextStyle(color: _textBlack)),
                      ),
                      const Center(
                        child: Text('Pengaturan', style: TextStyle(color: _textBlack)),
                      ),
                    ],
                  ),
                ),

                // TOMBOL TRANSAKSI
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BuatOrderDialog(
                            onOrderCreated: () => _loadOrdersFromSupabase(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text(
                        'MENU TRANSAKSI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // BOTTOM NAVBAR
                Container(
                  color: _cardDark,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                      _buildNavItem(1, Icons.shopping_cart_rounded, 'Order'),
                      _buildNavItem(2, Icons.bar_chart_rounded, 'Report'),
                      _buildNavItem(3, Icons.settings_rounded, 'Pengaturan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? _goldAccent : Colors.black45,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? _goldAccent : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // CARD RINGKASAN CUCIAN
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RINGKASAN CUCIAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    // BADGE REALTIME 3D
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFFCE7F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _goldAccent.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.fiber_manual_record,
                            color: Colors.green,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Realtime',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // STATS GRID
                Row(
                  children: [
                    _buildGridStat(
                      'CUCIAN AKTIF',
                      '${_ordersHariIni.where((o) => o['status'] == 'Antrian' || o['status'] == 'Proses').length}',
                      _textBlack,
                      Icons.local_laundry_service,
                    ),
                    const SizedBox(width: 8),
                    _buildGridStat(
                      'HARUS SELESAI',
                      '0',
                      _textBlack,
                      Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGridStat(
                      'TERLAMBAT',
                      '0',
                      _textBlack,
                      Icons.warning_amber_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildGridStat(
                      'SELESAI',
                      '${_ordersHariIni.where((o) => o['status'] == 'Selesai').length}',
                      _textBlack,
                      Icons.check_circle_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // KEUANGAN HARI INI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '💸 KEUANGAN HARI INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    Text(
                      'Hari Ini',
                      style: TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Omset Hari Ini',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    Text(
                      'Rp ${_totalOmsetHariIni.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _goldAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Pengeluaran Hari Ini',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    Text(
                      'Rp 0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // MASUK HARI INI
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '☕ MASUK HARI INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    Text(
                      '${_ordersHariIni.length} Order',
                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ordersHariIni.isEmpty
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.shopping_basket_outlined,
                                color: _goldAccent,
                                size: 30,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Belum Ada Masuk Hari Ini',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _textBlack,
                                ),
                              ),
                              Text(
                                'Transaksi hari ini akan muncul di sini',
                                style: TextStyle(fontSize: 9, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ordersHariIni.length,
                        itemBuilder: (context, index) {
                          final order = _ordersHariIni[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _bgDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['customer'] ?? '-',
                                      style: const TextStyle(
                                        color: _textBlack,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Status: ${order['status']}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rp ${(order['total'] as double).toInt()}',
                                  style: const TextStyle(
                                    color: _goldAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTab() {
    final statusFilter = ['Antrian', 'Proses', 'Selesai', 'Batal'];
    final selectedStatus = statusFilter[_orderFilterIndex];
    final filteredOrders = _ordersHariIni
        .where((o) => (o['status'] ?? 'Antrian').toString().toLowerCase() == selectedStatus.toLowerCase())
        .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: List.generate(statusFilter.length, (index) {
                final isActive = _orderFilterIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _orderFilterIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? _goldAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusFilter[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada orderan di status ini.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['customer'] ?? '-',
                                  style: const TextStyle(
                                    color: _textBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Status: ${order['status']}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${(order['total'] as double).toInt()}',
                              style: const TextStyle(
                                color: _goldAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
    );
  }

  Widget _buildGridStat(
    String title,
    String value,
    Color textColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _bgDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
              ],
            ),
            Icon(icon, size: 18, color: _goldAccent),
          ],
        ),
      ),
    );
  }
}
