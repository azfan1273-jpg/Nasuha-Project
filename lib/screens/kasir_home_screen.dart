import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import 'login_screen.dart';
import '../widgets/toko_header_widget.dart';

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

  final List<Map<String, dynamic>> _ordersHariIni = [];
  bool _isLoading = false;

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

	// HELPER FUNCTION PENGECEK TANGGAL HARI INI
	bool _isHariIni(String? rawDate) {
	  if (rawDate == null || rawDate.isEmpty) return false;
	  try {
	    final dt = DateTime.parse(rawDate).toLocal();
	    final now = DateTime.now();
	    return dt.year == now.year &&
	        dt.month == now.month &&
	        dt.day == now.day;
	  } catch (_) {
	    return false;
	  }
	}

  @override
  void initState() {
    super.initState();
    _loadOrdersFromSupabase();
  }

  Future<void> _loadOrdersFromSupabase() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

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
              'customer': record['customer_name'] ?? 'Pelanggan',
              'services': record['service_name'] ?? 'Layanan',
              'status': record['status'] ?? 'Baru',
              'total': (record['total_price'] as num?)?.toDouble() ?? 0.0,
              'created_at': record['created_at'],
            };
          }));
        });
      }
    } catch (e) {
      debugPrint('Log: Gagal memuat data Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 1. Getter Total Omset
  double get _totalOmsetHariIni {
    double total = 0.0;
    for (var item in _ordersHariIni) {
      if (item['status'] != 'Pengeluaran' && _isHariIni(item['created_at'])) {
        total += (item['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  // 🔹 2. Getter Total Pengeluaran
  double get _totalPengeluaranHariIni {
    double total = 0.0;
    for (var item in _ordersHariIni) {
      if (item['status'] == 'Pengeluaran' && _isHariIni(item['created_at'])) {
        total += (item['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
          
    return Container(
      color: _bgDark,
      child: Column(
        children: [
          const SizedBox(height: 10),
          TokoHeaderWidget(
            namaToko: settings.namaToko,
            userRole: settings.userRole,
            emailToko: settings.emailToko,
            isLoading: _isLoading,
            onRefresh: _loadOrdersFromSupabase,
          ),
          const SizedBox(height: 10),
          _buildBannerPromo(),
          const SizedBox(height: 10),
  
          // 🔹 1. RINGKASAN CUCIAN (STATIS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildOrderSummaryCard(),
          ),
          const SizedBox(height: 10),
  
          // 🔹 2. KEUANGAN HARI INI (STATIS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildFinancialSummaryCard(),
          ),
          const SizedBox(height: 10),
  
          // 🔹 3. MASUK HARI INI (DINAMIS / AREA SCROLL)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrdersFromSupabase,
              color: _goldAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTodayOrdersCard(), // 👈 Hanya widget ini di area scroll
              ),
            ),
          ),
  
          _buildTransactionButton(),
        ],
      ),
    );
  }

  Widget _buildBannerPromo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: _goldAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Promo Cuci Komplit Diskon 10%',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: _goldAccent,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Berlaku sampai akhir bulan.',
                      style: TextStyle(fontSize: 7.5, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _goldAccent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 7.5,
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

  Widget _buildOrderSummaryCard() {
    final activeCount = _ordersHariIni
        .where((o) => o['status'] == 'Baru' || o['status'] == 'Proses')
        .length;
    final doneCount =
        _ordersHariIni.where((o) => o['status'] == 'Selesai').length;

    return Container(
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 6),
          Row(
            children: [
              _buildGridStat(
                'CUCIAN AKTIF',
                '$activeCount',
                _textBlack,
                Icons.local_laundry_service,
              ),
              const SizedBox(width: 4),
              _buildGridStat(
                'HARUS SELESAI',
                '0',
                _textBlack,
                Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildGridStat(
                'TERLAMBAT',
                '0',
                _textBlack,
                Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 4),
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Omset Hari Ini',
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
              Text(_formatRupiah(_totalOmsetHariIni)),
            ],
          ),
          const Divider(height: 16, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengeluaran Hari Ini',
                style: TextStyle(fontSize: 11, color: Colors.black87),
              ),
              Text(_formatRupiah(_totalPengeluaranHariIni)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOrdersCard() {
    final daftarMasukHariIni = _ordersHariIni
            .where((item) =>
                item['status'] != 'Pengeluaran' &&
                _isHariIni(item['created_at'])) // 👈 Filter tanggal hari ini
            .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '☕ MASUK HARI INI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textBlack,
            ),
          ),
          const SizedBox(height: 12),
          daftarMasukHariIni.isEmpty
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
                          'Tekan "MENU TRANSAKSI" untuk buat order',
                          style: TextStyle(fontSize: 9, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: daftarMasukHariIni.length,
                  itemBuilder: (context, index) {
                    final order = daftarMasukHariIni[index];
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
                          Expanded(
                            child: Column(
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
                                const SizedBox(height: 2),
                                Text(
                                  order['services'] ?? '-',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatRupiah(order['total'] ?? 0)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order['status'] ?? 'Baru',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: _goldAccent,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildGridStat(
    String title,
    String value,
    Color textColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _bgDark,
          borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
              ],
            ),
            Icon(icon, size: 15, color: _goldAccent),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BuatOrderDialog(
                onOrderCreated: () {
                  _loadOrdersFromSupabase();
                },
              ),
            );
          },
          icon: const Icon(Icons.list_alt_rounded, size: 22),
          label: const Text(
            'MENU TRANSAKSI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
