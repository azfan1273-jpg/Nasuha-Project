import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import 'daftar_order_by_status_screen.dart';
import '../helpers/customer_insight_engine.dart';
import 'customer_detail_screen.dart';

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => KasirHomeScreenState();
}

class KasirHomeScreenState extends State<KasirHomeScreen> {
  double _totalOmsetHariIniVal = 0.0;
  double _totalPengeluaranHariIniVal = 0.0;

  int _countMasukHariIni = 0;
  int _countHarusSelesai = 0;
  int _countTerlambat = 0;
  int _countSelesai = 0;

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    await _fetchKeuanganHariIniViaRPC();
    await _fetchSummaryViaRPC();
  }

  Future<void> _fetchSummaryViaRPC() async {
    try {
      final currentStoreId = context.read<SettingsProvider>().storeId;
      if (currentStoreId == null) return;

      final response = await supabase.rpc('get_dashboard_summary', params: {
        'p_store_id': currentStoreId,
      });

      if (mounted && response != null) {
        final data = Map<String, dynamic>.from(response);
        setState(() {
          _countMasukHariIni = num.tryParse(data['masuk_hari_ini']?.toString() ?? '0')?.toInt() ?? 0;
          _countHarusSelesai = num.tryParse(data['harus_selesai']?.toString() ?? '0')?.toInt() ?? 0;
          _countTerlambat = num.tryParse(data['terlambat']?.toString() ?? '0')?.toInt() ?? 0;
          _countSelesai = num.tryParse(data['selesai']?.toString() ?? '0')?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetch summary RPC: $e');
    }
  }

  Future<void> _fetchKeuanganHariIniViaRPC() async {
    try {
      final currentStoreId = context.read<SettingsProvider>().storeId;
      if (currentStoreId == null) return;

      final response = await supabase.rpc('get_financial_report_by_store', params: {
        'p_store_id': currentStoreId,
        'p_filter_periode': 'Hari Ini',
      });

      if (mounted && response != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response);
        setState(() {
          _totalOmsetHariIniVal = num.tryParse(data['total_omset']?.toString() ?? '0')?.toDouble() ?? 0.0;
          _totalPengeluaranHariIniVal = num.tryParse(data['total_pengeluaran']?.toString() ?? '0')?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error fetch keuangan RPC: $e');
    }
  }

  // 🟢 LANGSUNG NAVIGASI INSTAN VIA ROOT NAVIGATOR
  void _bukaDetailOrderByStatus(String title, String categoryKey) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => DaftarOrderByStatusScreen(
          title: title,
          categoryKey: categoryKey,
        ),
      ),
    );
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      color: const Color(0xFFFAF5F7),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshData,
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
      ),
    );
  }

  Widget _buildOrderSummaryCard(SettingsProvider settings) {
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
                'MASUK HARI INI',
                '$_countMasukHariIni',
                Icons.move_to_inbox_rounded,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Order Masuk Hari Ini', 'masuk_hari_ini'),
              ),
              const SizedBox(width: 4),
              _buildGridStat(
                'HARUS SELESAI',
                '$_countHarusSelesai',
                Icons.timer_outlined,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Harus Selesai Hari Ini', 'harus_selesai'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildGridStat(
                'TERLAMBAT',
                '$_countTerlambat',
                Icons.warning_amber_rounded,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Orderan Terlambat', 'terlambat'),
              ),
              const SizedBox(width: 4),
              _buildGridStat(
                'SELESAI',
                '$_countSelesai',
                Icons.check_circle_outline,
                settings,
                onTap: () => _bukaDetailOrderByStatus('Orderan Selesai', 'selesai'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                _formatRupiah(_totalOmsetHariIniVal),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Divider(height: 12, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran Hari Ini',
                style: TextStyle(fontSize: 11, color: settings.textColor),
              ),
              Text(
                _formatRupiah(_totalPengeluaranHariIniVal),
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
    return Container(
      padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: settings.accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'PREDIKSI PELANGGAN BESOK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: settings.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: settings.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Clay Engine 90%+',
                  style: TextStyle(fontSize: 9, color: settings.accentColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: CustomerInsightEngine.fetchTomorrowPredictions(storeId: settings.storeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator(color: settings.accentColor)),
                );
              }

              final predictions = snapshot.data ?? [];

              if (predictions.isEmpty) {
                return Center(
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
                          Icons.analytics_outlined,
                          color: settings.accentColor,
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Belum Ada Prediksi Pelanggan Besok',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: settings.textColor,
                          ),
                        ),
                        Text(
                          'Belum ada pelanggan yang masuk siklus rutin untuk esok hari',
                          style: TextStyle(
                            fontSize: 9,
                            color: settings.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: settings.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: settings.textColor.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 110,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: settings.textColor.withOpacity(0.12), width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.centerLeft,
                            color: settings.textColor.withOpacity(0.05),
                            child: Text(
                              'Pelanggan',
                              style: TextStyle(
                                color: settings.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Divider(height: 1, color: settings.textColor.withOpacity(0.12)),
                          ...predictions.map((item) {
                            return InkWell(
                              onTap: () {
                                if (item['cust_data'] != null) {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailScreen(customer: item['cust_data']),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item['name'] ?? '-',
                                  style: TextStyle(
                                    color: settings.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: 590,
                          child: Column(
                            children: [
                              Container(
                                height: 38,
                                color: settings.textColor.withOpacity(0.05),
                                child: Row(
                                  children: [
                                    SizedBox(width: 60, child: Text('Skor', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 120, child: Text('Status Siklus', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 100, child: Text('Est. Omset', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 110, child: Text('Layanan Favorit', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 70, child: Text('Total Tx', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 80, child: Text('Kontribusi', style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                    SizedBox(width: 50, child: Text('Aksi', textAlign: TextAlign.center, style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: settings.textColor.withOpacity(0.12)),
                              ...predictions.map((item) {
                                final int score = item['score'] ?? 0;
                                final num estSpend = item['est_spend'] ?? 0;
                                final int totalTx = item['total_tx'] ?? 1;
                                final String contribution = item['contribution'] ?? '0%';

                                return InkWell(
                                  onTap: () {
                                    if (item['cust_data'] != null) {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(
                                          builder: (context) => CustomerDetailScreen(customer: item['cust_data']),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: settings.textColor.withOpacity(0.05), width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '$score%',
                                            style: TextStyle(
                                              color: settings.accentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            item['reason'] ?? '-',
                                            style: TextStyle(color: settings.textColor.withOpacity(0.7), fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Rp ${estSpend.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            item['favorite_service'] ?? '-',
                                            style: TextStyle(color: settings.textColor.withOpacity(0.8), fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 70,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$totalTx Tx',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            contribution,
                                            style: TextStyle(color: settings.textColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Icon(Icons.chevron_right_rounded, size: 18, color: settings.accentColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
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
                  refreshData();
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
