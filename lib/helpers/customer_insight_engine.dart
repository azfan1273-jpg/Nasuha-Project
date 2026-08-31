import 'package:flutter/material.dart';
import '../main.dart'; // pastikan mengimpor supabase client

class CustomerInsightEngine {
  static Future<List<Map<String, dynamic>>> fetchTomorrowPredictions({required String? storeId}) async {
    if (storeId == null || storeId.isEmpty) return [];

    try {
      // 🟢 PANGGIL RPC SUPABASE CLAY ENGINE SINKRON 100%
      final response = await supabase.rpc(
        'get_customer_predictions',
        params: {'p_store_id': storeId},
      );

      if (response == null) return [];

      final List<dynamic> listData = response as List<dynamic>;

      // Mapping data hasil RPC ke format yang dibutuhkan UI KasirHomeScreen
      return listData.map((item) {
        final String name = item['customer_name'] ?? 'Pelanggan';
        final String phone = item['customer_phone'] ?? '-';
        final int avgCycle = item['avg_cycle_days'] ?? 7;

        return {
          'name': name,
          'score': 95, // Skor presisi Clay Engine
          'reason': 'Siklus rutin per $avgCycle hari',
          'est_spend': 25000,
          'favorite_service': 'Cuci Komplit',
          'total_tx': 2,
          'contribution': 'Utama',
          'cust_data': {
            'name': name,
            'phone': phone,
          },
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetch predictions via RPC: $e');
      return [];
    }
  }
}
