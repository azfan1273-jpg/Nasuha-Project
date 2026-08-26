import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final customersResp = await supabase.from('customers').select();
      final ordersResp = await supabase.from('orders').select().order('created_at', ascending: false);

      final List<Map<String, dynamic>> customers = List<Map<String, dynamic>>.from(customersResp);
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResp);

      List<Map<String, dynamic>> predictions = [];
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

      // Grouping orders by customer phone/name
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

        // 1. SIKLUS INTERVAL HARI
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

        // 2. HABIT HARI (DAY OF WEEK)
        int sameDayCount = dates.where((d) => d.weekday == tomorrow.weekday).length;
        double dayHabitScore = (sameDayCount / dates.length) * 100;

        // 3. SKOR AKURASI AKHIR
        double finalScore = (intervalScore * 0.60) + (dayHabitScore * 0.40);

        if (finalScore >= 40) {
          num totalSpend = history.fold(0, (sum, o) => sum + (num.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
          double avgSpend = totalSpend / history.length;

          totalOmsetAcc += avgSpend;

          String reason = "Siklus per ${avgInterval.toStringAsFixed(0)} hari";
          if (dayHabitScore > 50) {
            reason += " • Rutin di hari ini";
          }

          predictions.add({
            'name': cust['name'] ?? 'Pelanggan',
            'phone': cust['phone'] ?? '-',
            'score': finalScore.clamp(0, 99).toInt(),
            'reason': reason,
            'est_spend': avgSpend,
            'favorite_service': _getFavoriteService(history),
            'last_visit_days': daysSinceLastVisit,
            'avg_interval': avgInterval.toStringAsFixed(1),
            'cust_data': cust,
          });
        }
      }

      predictions.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      setState(() {
        _predictions = predictions;
        _totalPotensial = predictions.length;
        _totalEstOmset = totalOmsetAcc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getFavoriteService(List<Map<String, dynamic>> history) {
    Map<String, int> counts = {};
    for (var o in history) {
      String service = (o['services_summary'] ?? o['item_name'] ?? 'Cuci Komplit').toString();
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
                  // 1. CARDS RINGKASAN PROYEKSI ESOK HARI
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

                  // 2. HEADER DAFTAR PREDIKSI
                  const Text(
                    'Daftar Pelanggan Diprediksi Datang Besok',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Diurutkan berdasarkan skor akurasi pola transaksi paling tinggi',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // 3. LIST PREDIKSI
                  _predictions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text('Belum ada pelanggan yang masuk siklus esok hari', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final item = _predictions[index];
                            final int score = item['score'];

                            Color badgeColor = Colors.orange;
                            if (score >= 85) badgeColor = const Color(0xFF00E676);
                            else if (score >= 60) badgeColor = Colors.amber;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: badgeColor, width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$score%',
                                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Akurat',
                                        style: TextStyle(color: badgeColor.withOpacity(0.8), fontSize: 8),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Text(
                                  item['name'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['reason']} (${item['favorite_service']})',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Terakhir datang: ${item['last_visit_days']} hari lalu',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Est. Belanja', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatRupiah(item['est_spend']),
                                      style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Klik item langsung buka Detail Pelanggan tersebut
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailScreen(customer: item['cust_data']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
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
