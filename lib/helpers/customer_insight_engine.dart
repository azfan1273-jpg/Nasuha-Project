import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerInsightEngine {
  /// Memproses seluruh data pelanggan dan riwayat transaksi untuk memprediksi potensi esok hari
  static Future<List<Map<String, dynamic>>> fetchTomorrowPredictions() async {
    final supabase = Supabase.instance.client;

    try {
      // 1. Fetch data pelanggan & transaksi dari Supabase
      final customersResp = await supabase.from('customers').select();
      final ordersResp = await supabase.from('orders').select().order('created_at', ascending: false);

      final List<Map<String, dynamic>> customers = List<Map<String, dynamic>>.from(customersResp);
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(ordersResp);

      List<Map<String, dynamic>> predictions = [];
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

      // Grouping order berdasarkan nomor handphone/nama pelanggan
      Map<String, List<Map<String, dynamic>>> customerOrdersMap = {};
      for (var order in orders) {
        String key = (order['customer_phone'] ?? order['customer_name'] ?? '').toString();
        if (key.isNotEmpty) {
          customerOrdersMap.putIfAbsent(key, () => []).add(order);
        }
      }

      for (var cust in customers) {
        String phoneKey = (cust['phone'] ?? '').toString();
        String nameKey = (cust['name'] ?? '').toString();
        
        List<Map<String, dynamic>> history = customerOrdersMap[phoneKey] ?? customerOrdersMap[nameKey] ?? [];

        if (history.isEmpty) continue; // Skip jika belum pernah ada riwayat

        // Urutkan riwayat berdasarkan tanggal paling baru
        List<DateTime> dates = history
            .map((e) => DateTime.tryParse(e['created_at'].toString()))
            .whereType<DateTime>()
            .toList()..sort((a, b) => b.compareTo(a));

        if (dates.isEmpty) continue;

        DateTime lastVisit = dates.first;
        int daysSinceLastVisit = tomorrow.difference(lastVisit).inDays;

        // --- 1. SIKLUS INTERVAL HARI ---
        List<int> intervals = [];
        for (int i = 0; i < dates.length - 1; i++) {
          intervals.add(dates[i].difference(dates[i + 1]).inDays);
        }

        double avgInterval = intervals.isNotEmpty
            ? intervals.reduce((a, b) => a + b) / intervals.length
            : 7.0; // Default 7 hari

        double intervalDiff = (daysSinceLastVisit - avgInterval).abs();
        double intervalScore = 0;

        if (intervalDiff <= 0.5) {
          intervalScore = 100; // Pas persis dengan siklus rutin
        } else if (intervalDiff <= 1.0) {
          intervalScore = 85;
        } else if (intervalDiff <= 2.0) {
          intervalScore = 50;
        } else {
          intervalScore = 10;
        }

        // Penalty jika sudah melampaui masa aktif normal (dormant)
        if (daysSinceLastVisit > (avgInterval * 2.5) && daysSinceLastVisit > 14) {
          intervalScore = 0;
        }

        // --- 2. HABIT HARI (DAY OF WEEK) ---
        int sameDayCount = dates.where((d) => d.weekday == tomorrow.weekday).length;
        double dayHabitScore = (sameDayCount / dates.length) * 100;

        // --- 3. SKOR AKURASI AKHIR ---
        double finalScore = (intervalScore * 0.60) + (dayHabitScore * 0.40);

        // Hanya tampilkan jika skor potensi cukup signifikan (>= 40%)
        if (finalScore >= 40) {
          num totalSpend = history.fold(0, (sum, o) => sum + (num.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
          double avgSpend = totalSpend / history.length;

          // Alasan Prediksi Engine
          String reason = "Rutin per ${avgInterval.toStringAsFixed(0)} hari";
          if (dayHabitScore > 50) {
            reason += " & Sering di hari ini";
          }

          predictions.add({
            'name': cust['name'] ?? 'Pelanggan',
            'phone': cust['phone'] ?? '-',
            'score': finalScore.clamp(0, 99).toInt(), // Max 99%
            'reason': reason,
            'est_spend': avgSpend,
            'favorite_service': _getFavoriteService(history),
            'cust_data': cust,
          });
        }
      }

      // Urutkan dari skor tertinggi ke rendah
      predictions.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      return predictions;
    } catch (e) {
      return [];
    }
  }

  static String _getFavoriteService(List<Map<String, dynamic>> history) {
    Map<String, int> counts = {};
    for (var o in history) {
      String service = (o['services_summary'] ?? o['item_name'] ?? 'Cuci Komplit').toString();
      counts[service] = (counts[service] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'Cuci Komplit';
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
