import 'package:flutter/material.dart';
import '../main.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerInsightEngine {
  // Masukkan domain resmi Vercel kamu di sini!
  static const String baseUrl = 'https://nasuha-web.vercel.app/api/clay';

  static Future<List<Map<String, dynamic>>> fetchTomorrowPredictions({String? storeId}) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        throw Exception("Sesi pengguna tidak ditemukan. Silakan login kembali.");
      }

      final url = Uri.parse('$baseUrl/predict-tomorrow');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map<String, dynamic> && data.containsKey('predictions')) {
          final List predictionsList = data['predictions'];
          return List<Map<String, dynamic>>.from(predictionsList);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      } else {
        throw Exception('Gagal memuat data dari Clay Engine (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error pada CustomerInsightEngine: $e');
      rethrow;
    }
    return [];
  }
}
