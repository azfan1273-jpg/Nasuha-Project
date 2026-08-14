import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  // Penampung data lokal sementara untuk mode offline
  final List<Map<String, dynamic>> _localOrders = [];

  Future<void> insertOrder(Map<String, dynamic> order) async {
    _localOrders.add(order);
    debugPrint('Order berhasil disimpan lokal: $order');
  }

  Future<List<Map<String, dynamic>>> getLocalOrders() async {
    return List.from(_localOrders);
  }

  Future<void> clearLocalOrders() async {
    _localOrders.clear();
  }
}
