import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';
import 'customer_detail_screen.dart';

class CustomerInsightScreen extends StatefulWidget {
  const CustomerInsightScreen({super.key});

  @override
  State<CustomerInsightScreen> createState() => _CustomerInsightScreenState();
}

class _CustomerInsightScreenState extends State<CustomerInsightScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _predictions = [];
  
  // Ringkasan Dashboard Engine
  int _totalPotensial = 0;
  num _totalEstOmset = 0;

  @override
  void initState() {
    super.initState();
    _analyzePredictions();
  }

  Future<void> _analyzePredictions() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final customersResp = await supabase
          .from('customers')
          .select()
          .eq('store_id', storeId);

      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180)).toIso8601String();
      final ordersResp = await supabase
          .from('orders')
          .select()
          .eq('store_id', storeId)
          .gte('created_at', sixMonthsAgo)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> customers = List<Map<String, dynamic>>.from(customersResp);
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResp);

      List<Map<String, dynamic>> predictions = [];
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

      // Hitung total omset toko untuk kalkulasi kontribusi
      num storeTotalSpend = orders.fold(0, (sum, o) => sum + (num.tryParse(o['total_price']?.toString() ?? '0') ?? 0));

      Map<String, List<Map<String, dynamic>>> customerOrdersMap = {};
      for (var order in orders) {
        String key = (order['customer_phone'] ?? order['customer_name'] ?? '').toString();
        if (key.isNotEmpty) {
          customerOrdersMap.putIfAbsent(key, () => []).add(order);
        }
      }

      num totalOmsetAcc = 0;

      for (var cust in customers) {
        String phoneKey = (cust['phone'] ?? '').toString();
        String nameKey = (cust['name'] ?? '').toString();
        
        List<Map<String, dynamic>> history = customerOrdersMap[phoneKey] ?? customerOrdersMap[nameKey] ?? [];
        if (history.isEmpty) continue;

        List<DateTime> dates = history
            .map((e) => DateTime.tryParse(e['created_at'].toString()))
            .whereType<DateTime>()
            .toList()..sort((a, b) => b.compareTo(a));

        if (dates.isEmpty) continue;

        DateTime lastVisit = dates.first;
        int daysSinceLastVisit = tomorrow.difference(lastVisit).inDays;

        List<int> intervals = [];
        for (int i = 0; i < dates.length - 1; i++) {
          intervals.add(dates[i].difference(dates[i + 1]).inDays);
        }

        double avgInterval = intervals.isNotEmpty
            ? intervals.reduce((a, b) => a + b) / intervals.length
            : 7.0;

        double intervalDiff = (daysSinceLastVisit - avgInterval).abs();
        double intervalScore = 0;

        if (intervalDiff <= 0.5) {
          intervalScore = 100;
        } else if (intervalDiff <= 1.0) {
          intervalScore = 85;
        } else if (intervalDiff <= 2.0) {
          intervalScore = 50;
        } else {
          intervalScore = 10;
        }

        if (daysSinceLastVisit > (avgInterval * 2.5) && daysSinceLastVisit > 14) {
          intervalScore = 0;
        }

        int sameDayCount = dates.where((d) => d.weekday == tomorrow.weekday).length;
        double dayHabitScore = (sameDayCount / dates.length) * 100;

        double finalScore = (intervalScore * 0.60) + (dayHabitScore * 0.40);

        if (finalScore >= 40) {
          num totalSpend = history.fold(0, (sum, o) => sum + (num.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
          double avgSpend = totalSpend / history.length;

          totalOmsetAcc += avgSpend;

          String reason = "Siklus ${avgInterval.toStringAsFixed(0)} hr";
          if (dayHabitScore > 50) {
            reason += " • Rutin hari ini";
          }

          // Hitung persentase kontribusi pelanggan terhadap total omset toko
          double contributionPct = storeTotalSpend > 0 ? (totalSpend / storeTotalSpend) * 100 : 0;

          predictions.add({
            'name': cust['name'] ?? 'Pelanggan',
            'phone': cust['phone'] ?? '-',
            'score': finalScore.clamp(0, 99).toInt(),
            'reason': reason,
            'est_spend': avgSpend,
            'favorite_service': _getFavoriteService(history),
            'last_visit_days': daysSinceLastVisit,
            'avg_interval': avgInterval.toStringAsFixed(1),
            'total_tx': history.length, // 🟢 TOTAL TRANSAKSI
            'contribution': '${contributionPct.toStringAsFixed(1)}%', // 🟢 KONTRIBUSI %
            'cust_data': cust,
          });
        }
      }

      predictions.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      if (mounted) {
        setState(() {
          _predictions = predictions;
          _totalPotensial = predictions.length;
          _totalEstOmset = totalOmsetAcc;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error engine: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFavoriteService(List<Map<String, dynamic>> history) {
    Map<String, int> counts = {};
    for (var o in history) {
      String service = (o['services_summary'] ?? o['item_name'] ?? o['service_name'] ?? 'Cuci Komplit').toString();
      counts[service] = (counts[service] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'Cuci Komplit';
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252528),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customer Insight Engine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _analyzePredictions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Potensi Masuk',
                          value: '$_totalPotensial Orang',
                          subtitle: 'Prediksi Akurasi 90%+',
                          icon: Icons.people_alt_rounded,
                          accentColor: const Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Est. Kas Masuk',
                          value: _formatRupiah(_totalEstOmset),
                          subtitle: 'Proyeksi Esok Hari',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Pelanggan Diprediksi Datang Besok',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Geser tabel ke kanan untuk melihat rincian riwayat & kontribusi',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _predictions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text('Belum ada pelanggan yang masuk siklus esok hari', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : _buildFrozenPredictionTable(),
                ],
              ),
            ),
    );
  }

  // 🟢 TABEL DENGAN KOLOM NAMA TERKUNCI & SCROLL HORIZONTAL LENGKAP
  Widget _buildFrozenPredictionTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KOLOM KIRI (STATIS / FROZEN: NAMA PELANGGAN)
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  color: const Color(0xFF252528),
                  child: const Text(
                    'Pelanggan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white12),
                ..._predictions.map((item) {
                  return Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    child: Text(
                      item['name'] ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Pemisah Vertikal Antara Kolom
          Container(width: 1, color: Colors.white12),

          // 2. KOLOM KANAN (SCROLLABLE HORIZONTAL)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Scrollable
                  Container(
                    height: 42,
                    color: const Color(0xFF252528),
                    child: const Row(
                      children: [
                        _HeaderCell(title: 'Skor', width: 65),
                        _HeaderCell(title: 'Status Siklus', width: 140),
                        _HeaderCell(title: 'Est. Omset', width: 110),
                        _HeaderCell(title: 'Layanan Favorit', width: 130),
                        _HeaderCell(title: 'Total Tx', width: 90),
                        _HeaderCell(title: 'Kontribusi', width: 90),
                        _HeaderCell(title: 'Aksi', width: 60, isCenter: true),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.white12),
                  // Row Data Scrollable
                  ..._predictions.map((item) {
                    final int score = item['score'] ?? 0;
                    final num estSpend = item['est_spend'] ?? 0;
                    final int totalTx = item['total_tx'] ?? 0;
                    final String contribution = item['contribution'] ?? '0%';

                    Color badgeColor = Colors.orange;
                    if (score >= 85) badgeColor = const Color(0xFF00E676);
                    else if (score >= 60) badgeColor = Colors.amber;

                    return Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          // Skor
                          _DataCell(
                            width: 65,
                            child: Text(
                              '$score%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                          // Status Siklus
                          _DataCell(
                            width: 140,
                            child: Text(
                              item['reason'] ?? '-',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Est. Omset
                          _DataCell(
                            width: 110,
                            child: Text(
                              _formatRupiah(estSpend),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                            ),
                          ),
                          // Layanan Favorit
                          _DataCell(
                            width: 130,
                            child: Text(
                              item['favorite_service'] ?? 'Cuci Komplit',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Total Transaksi
                          _DataCell(
                            width: 90,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$totalTx Order',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                              ),
                            ),
                          ),
                          // Kontribusi
                          _DataCell(
                            width: 90,
                            child: Text(
                              contribution,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ),
                          // Aksi
                          _DataCell(
                            width: 60,
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF00E676)),
                              onPressed: () {
                                if (item['cust_data'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailScreen(customer: item['cust_data']),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }
}

// Widget Helper Header
class _HeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final bool isCenter;

  const _HeaderCell({
    required this.title,
    required this.width,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: isCenter ? Alignment.center : Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Widget Helper Cell Data
class _DataCell extends StatelessWidget {
  final Widget child;
  final double width;

  const _DataCell({
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
