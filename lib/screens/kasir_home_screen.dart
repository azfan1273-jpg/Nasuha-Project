import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import 'login_screen.dart';
import '../screens/report_screen.dart';
import 'daftar_order_by_status_screen.dart';

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => KasirHomeScreenState();
}

class KasirHomeScreenState extends State<KasirHomeScreen> {
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

  // HELPER FUNCTION PENGECEK TERLAMBAT
  bool _isTerlambat(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return false;
    try {
      final est = DateTime.parse(rawDate).toLocal();
      final now = DateTime.now();
      // Bandingkan apakah tanggal estimasi lebih kecil dari tanggal hari ini (00:00)
      final todayStart = DateTime(now.year, now.month, now.day);
      return est.isBefore(todayStart);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrdersFromSupabase();
  }

  // Method publik yang bisa dipanggil dari KasirPageManager
  Future<void> refreshData() async {
    await _loadOrdersFromSupabase();
  }

  // AMBIL DATA TERISOLASI BERDASARKAN STORE_ID
  Future<void> _loadOrdersFromSupabase() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Ambil store_id dari profiles milik user yang sedang login
      final profileRes = await supabase
          .from('profiles')
          .select('store_id')
          .eq('id', user.id)
          .maybeSingle();

      final String? currentStoreId = profileRes?['store_id']?.toString();

      if (currentStoreId == null) {
        debugPrint('Log: store_id tidak ditemukan');
        return;
      }

      // 2. Filter query Supabase hanya untuk toko ini
      final List<dynamic> data = await supabase
          .from('orders')
          .select('*')
          .eq('store_id', currentStoreId) // <-- ISOLASI DATA STORE ID
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
              'estimated_at': record['estimated_at'],
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

  // Getter Total Omset
  double get _totalOmsetHariIni {
    double total = 0.0;
    for (var item in _ordersHariIni) {
      if (item['status'] != 'Pengeluaran' && _isHariIni(item['created_at'])) {
        total += (item['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  // Getter Total Pengeluaran
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
      width: double.infinity,
      color: const Color(0xFFFAF5F7),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrdersFromSupabase,
              color: settings.accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _buildOrderSummaryCard(settings),
                    const SizedBox(height: 10),
                    _buildFinancialSummaryCard(settings),
                    const SizedBox(height: 10),
                    _buildTodayOrdersCard(settings),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          _buildTransactionButton(settings),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(SettingsProvider settings) {
    final cucianAktifList = _ordersHariIni
        .where((o) => o['status'] != 'Selesai' && o['status'] != 'Pengeluaran')
        .toList();

    final harusSelesaiList = _ordersHariIni
        .where((o) => o['status'] != 'Selesai' && _isHariIni(o['estimated_at']))
        .toList();

    final terlambatList = _ordersHariIni
        .where((o) => o['status'] != 'Selesai' && _isTerlambat(o['estimated_at']))
        .toList();

    final selesaiList = _ordersHariIni
        .where((o) => o['status'] == 'Selesai')
        .toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: settings.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RINGKASAN CUCIAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: settings.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: settings.bgDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.green,
                      size: 8,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Realtime',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: settings.textColor,
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
                '${cucianAktifList.length}',
                Icons.local_laundry_service,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Cucian Aktif', cucianAktifList),
              ),
              const SizedBox(width: 4),
              _buildGridStat(
                'HARUS SELESAI',
                '${harusSelesaiList.length}',
                Icons.timer_outlined,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Harus Selesai Hari Ini', harusSelesaiList),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildGridStat(
                'TERLAMBAT',
                '${terlambatList.length}',
                Icons.warning_amber_rounded,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Orderan Terlambat', terlambatList),
              ),
              const SizedBox(width: 4),
              _buildGridStat(
                'SELESAI',
                '${selesaiList.length}',
                Icons.check_circle_outline,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Orderan Selesai', selesaiList),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _bukaDetailOrderByStatus(String title, List<Map<String, dynamic>> orders) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaftarOrderByStatusScreen(
          title: title,
          orders: orders,
        ),
      ),
    );

    _loadOrdersFromSupabase();
  }

  Widget _buildFinancialSummaryCard(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: settings.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KEUANGAN HARI INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: settings.textColor,
                ),
              ),
              Text(
                'Hari Ini',
                style: TextStyle(
                  fontSize: 9,
                  color: settings.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Omset Hari Ini',
                style: TextStyle(fontSize: 10, color: settings.textColor),
              ),
              Text(
                _formatRupiah(_totalOmsetHariIni),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran Hari Ini',
                style: TextStyle(fontSize: 11, color: settings.textColor),
              ),
              Text(
                _formatRupiah(_totalPengeluaranHariIni),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOrdersCard(SettingsProvider settings) {
    final daftarMasukHariIni = _ordersHariIni
        .where((item) =>
            item['status'] != 'Pengeluaran' &&
            _isHariIni(item['created_at']))
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: settings.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MASUK HARI INI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: settings.textColor,
            ),
          ),
          const SizedBox(height: 12),
          daftarMasukHariIni.isEmpty
              ? Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: settings.bgDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          color: settings.accentColor,
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Belum Ada Masuk Hari Ini',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: settings.textColor,
                          ),
                        ),
                        Text(
                          'Tekan "MENU TRANSAKSI" untuk buat order',
                          style: TextStyle(
                            fontSize: 9,
                            color: settings.textColor.withOpacity(0.6),
                          ),
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
                        color: settings.bgDark,
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
                                  style: TextStyle(
                                    color: settings.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order['services'] ?? '-',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: settings.textColor.withOpacity(0.6),
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
                              Text(
                                _formatRupiah(order['total'] ?? 0),
                                style: TextStyle(color: settings.textColor),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: settings.cardDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order['status'] ?? 'Baru',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: settings.accentColor,
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
    IconData icon,
    SettingsProvider settings, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: settings.bgDark,
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
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: settings.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: settings.textColor,
                      ),
                    ),
                  ],
                ),
                Icon(icon, size: 15, color: settings.accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionButton(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: settings.accentColor,
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
