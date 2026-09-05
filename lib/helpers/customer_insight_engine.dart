import 'package:flutter/material.dart';
import '../main.dart';

class CustomerInsightEngine {
  static Future<List<Map<String, dynamic>>> fetchTomorrowPredictions({required String? storeId}) async {
    if (storeId == null || storeId.isEmpty) return [];

    try {
      final response = await supabase.rpc(
        'get_customer_predictions',
        params: {'p_store_id': storeId},
      );

      if (response == null) return [];

      final List<dynamic> listData = response as List<dynamic>;

      return listData.map((item) {
        return {
          'name': item['customer_name'] ?? 'Pelanggan',
          'phone': item['customer_phone'] ?? '-',
          'score': item['score'] ?? 80,
          'reason': item['reason'] ?? 'Siklus rutin',
          'est_spend': item['est_spend'] ?? 0,
          'favorite_service': item['favorite_service'] ?? 'Cuci Komplit',
          'total_tx': item['total_tx'] ?? 1,
          'tag': item['tag'] ?? 'Aktif',
          'contribution': item['contribution'] ?? 'Reguler',
          'cust_data': {
            'name': item['customer_name'] ?? 'Pelanggan',
            'phone': item['customer_phone'] ?? '-',
          },
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetch predictions via RPC: $e');
      return [];
    }
  }
}
