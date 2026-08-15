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
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final PageController _pageController = PageController();
  final List<Map<String, dynamic>> _ordersHariIni = [];

  @override
  void initState() {
    super.initState();
    _loadOrdersFromSupabase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

                // Header Toko
                _buildHeader(settings),

                const SizedBox(height: 12),

                // Banner Promo
                _buildBannerPromo(),

                const SizedBox(height: 12),

                // Swipeable Dashboard Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildBerandaTab(),
                      _buildDashboardPage2(),
                    ],
                  ),
                ),

                // Tombol Menu Transaksi
                _buildTransactionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET COMPONENTS
  // ============================================================================

  Widget _buildHeader(SettingsProvider settings) {
    return Padding(
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
    );
  }

  Widget _buildBannerPromo() {
    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  Widget _buildBerandaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildOrderSummaryCard(),
          const SizedBox(height: 10),
          _buildFinancialSummaryCard(),
          const SizedBox(height: 10),
          _buildTodayOrdersCard(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final activeCount = _ordersHariIni
        .where((o) => o['status'] == 'Antrian' || o['status'] == 'Proses')
        .length;
    final doneCount =
        _ordersHariIni.where((o) => o['status'] == 'Selesai').length;

    return Container(
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
          Row(
            children: [
              _buildGridStat(
                'CUCIAN AKTIF',
                '$activeCount',
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
                '$doneCount',
                _textBlack,
                Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
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
    );
  }

  Widget _buildTodayOrdersCard() {
    return Container(
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
    );
  }

  Widget _buildDashboardPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AKTIVITAS LAUNDRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _textBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withOpacity(0.16),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Hari Ini',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildActivityBar(
                  'Aila Nasuha',
                  '1 Order',
                  'Est selesai • 17/09/2026',
                  'Rp. 77.500',
                ),
                const SizedBox(height: 8),
                _buildActivityBar(
                  'Yumna Nasuha',
                  '5 Order',
                  'Est selesai • 17/09/2026',
                  'Rp. 155.500',
                ),
                const SizedBox(height: 8),
                _buildActivityBar(
                  'Nasuha Claymithree',
                  '3 Order',
                  'Est selesai • 17/09/2026',
                  'Rp. 95.500',
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Konten halaman berikutnya',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(
    String customer,
    String orderCount,
    String estimate,
    String total,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4B8), Color(0xFFFFC7E8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estimate,
                  style: const TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: _textBlack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                orderCount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total,
                style: const TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: _textBlack,
                ),
              ),
            ],
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

  Widget _buildTransactionButton() {
    return Padding(
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
    );
  }
}
