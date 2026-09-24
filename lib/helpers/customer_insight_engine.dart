import 'package:flutter/foundation.dart';
import '../main.dart';

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerInsightEngine {
  // 🟢 Base URL Vercel — sesuaikan kalau endpoint churn beda
  static const String baseUrl = 'https://nasuha-web.vercel.app/api/clay';

  // Timeout default (biar gak nge-hang kalau API lambat)
  static const Duration _timeout = Duration(seconds: 15);

  // ============================================
  // HELPER: Get auth token
  // ============================================
  static String? _getToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  static Map<String, String> _buildHeaders() {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // 1. PREDIKSI PELANGGAN DATANG ESOK HARI
  // ============================================
  /// Endpoint: GET /predict-tomorrow
  static Future<List<Map<String, dynamic>>> fetchTomorrowPredictions({
    String? storeId,
  }) async {
    try {
      final token = _getToken();
      if (token == null) {
        throw Exception("Sesi pengguna tidak ditemukan. Silakan login kembali.");
      }

      final url = Uri.parse('$baseUrl/predict-tomorrow');
      final response = await http
          .get(url, headers: _buildHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('predictions')) {
          final List predictionsList = data['predictions'];
          return List<Map<String, dynamic>>.from(predictionsList);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      } else {
        throw Exception(
          'Gagal memuat data dari Clay Engine (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Error pada CustomerInsightEngine.fetchTomorrowPredictions: $e');
      rethrow;
    }
    return [];
  }

  // ============================================
  // 2. FETCH CHURN RISK (siap ke Python)
  // ============================================
  /// Endpoint: POST /churn-analysis
  ///
  /// Request body:
  /// {
  ///   "store_id": "uuid",
  ///   "limit": 10,
  ///   "offset": 0
  /// }
  ///
  /// Response yang diharapkan:
  /// {
  ///   "data": [
  ///     {
  ///       "customer_code": "NASUHA-560770",
  ///       "customer_name": "Jenifer Lopez",
  ///       "customer_phone": "081234567890",
  ///       "status_base": "Best",
  ///       "contribution_current": 0.52,
  ///       "performance": 3.33,
  ///       "days_since_last_order": 50,
  ///       "churn_reason": "Lama tidak order",
  ///       "solution": "Follow-up WA reminder"
  ///     }
  ///   ],
  ///   "total_count": 1,
  ///   "limit": 10,
  ///   "offset": 0
  /// }
  static Future<Map<String, dynamic>> fetchChurnRisk({
    required String storeId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/churn-analysis');

      final response = await http
          .post(
            url,
            headers: _buildHeaders(),
            body: json.encode({
              'store_id': storeId,
              'limit': limit,
              'offset': offset,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return {
            'data': data['data'] ?? [],
            'total_count': data['total_count'] ?? 0,
            'limit': data['limit'] ?? limit,
            'offset': data['offset'] ?? offset,
          };
        }
      }

      // 🟡 Kalau endpoint belum ada / error — return kosong (graceful)
      debugPrint(
        'Churn endpoint belum siap (Status: ${response.statusCode}). Return empty.',
      );
      return {
        'data': <Map<String, dynamic>>[],
        'total_count': 0,
        'limit': limit,
        'offset': offset,
      };
    } catch (e) {
      // 🟡 Graceful fallback — gak crash kalau endpoint error
      debugPrint('Error fetchChurnRisk: $e');
      return {
        'data': <Map<String, dynamic>>[],
        'total_count': 0,
        'limit': limit,
        'offset': offset,
      };
    }
  }

  // ============================================
  // 3. FETCH CUSTOMER TIER (untuk customer_detail)
  // ============================================
  /// Endpoint: POST /customer-tier
  ///
  /// Request body:
  /// {
  ///   "store_id": "uuid",
  ///   "customer_code": "NASUHA-560770"
  /// }
  ///
  /// Response:
  /// {
  ///   "customer_code": "NASUHA-560770",
  ///   "customer_name": "Jenifer Lopez",
  ///   "tier": "VIP",
  ///   "contribution_percent": 6.67,
  ///   "rfm_score": 12,
  ///   "percentile_rank": 3,
  ///   "reason": "Kontribusi tinggi + sering order"
  /// }
  static Future<Map<String, dynamic>?> fetchCustomerTier({
    required String storeId,
    required String customerCode,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/customer-tier');

      final response = await http
          .post(
            url,
            headers: _buildHeaders(),
            body: json.encode({
              'store_id': storeId,
              'customer_code': customerCode,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      debugPrint(
        'Customer tier endpoint belum siap (Status: ${response.statusCode})',
      );
      return null;
    } catch (e) {
      debugPrint('Error fetchCustomerTier: $e');
      return null;
    }
  }

  // ============================================
  // 4. FETCH TOP CUSTOMERS (untuk insight screen)
  // ============================================
  /// Endpoint: POST /top-customers
  ///
  /// Response:
  /// {
  ///   "total_store_revenue": 1000000000,
  ///   "total_customers": 259,
  ///   "data": [
  ///     {
  ///       "customer_code": "NASUHA-560770",
  ///       "customer_name": "Cici",
  ///       "total_revenue": 5000000,
  ///       "contribution_percent": 0.5,
  ///       "tier": "VVIP",
  ///       "rank": 1
  ///     }
  ///   ]
  /// }
  ///
  /// 🟡 Sementara masih fallback ke RPC — akan migrasi setelah Python siap
  static Future<Map<String, dynamic>?> fetchTopCustomers({
    required String storeId,
    int limit = 20,
  }) async {
    try {
      // 🟢 Sementara: fallback ke Supabase RPC
      // 🟡 Nanti: ganti ke HTTP call ke Python
      final response = await Supabase.instance.client.rpc(
        'get_top_customers',
        params: {
          'p_store_id': storeId,
          'p_limit': limit,
        },
      );

      if (response != null) {
        return {
          'top_customers': response['top_customers'] ?? [],
          'total_store_revenue': response['total_store_revenue'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetchTopCustomers: $e');
      return null;
    }
  }
}
