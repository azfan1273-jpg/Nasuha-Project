import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  final List<Map<String, dynamic>> _localOrders = [];

  // Menyimpan order lengkap dengan store_id
  Future<void> insertOrder(Map<String, dynamic> order) async {
    _localOrders.add({
      ...order,
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('Order berhasil disimpan lokal: $order');
  }

  // Pengambilan data terisolasi berdasarkan store_id
  Future<List<Map<String, dynamic>>> getLocalOrders(String storeId) async {
    return _localOrders
        .where((order) => order['store_id']?.toString() == storeId)
        .toList();
  }

  // Membersihkan data lokal toko tertentu saat logout
  Future<void> clearLocalOrders({String? storeId}) async {
    if (storeId != null) {
      _localOrders.removeWhere((order) => order['store_id']?.toString() == storeId);
    } else {
      _localOrders.clear();
    }
  }
}
