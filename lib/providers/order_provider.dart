import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => _orders;

  // Wajib dipanggil saat User LOGOUT agar state bersih total
  void clearState() {
    _orders = [];
    _isLoading = false;
    notifyListeners();
  }

  // Fetch orders terisolasi menggunakan storeId yang dipass langsung
  Future<void> fetchOrders(String storeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      _orders = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetchOrders di OrderProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Order menggunakan storeId yang dipass langsung
  Future<bool> createOrder({
    required String storeId,
    required String customerName,
    required String customerPhone,
    required String perfume,
    required String paymentStatus,
    required String paymentMethod,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User belum login');

      // Penomoran nota dikombinasikan dengan 4 karakter akhir ID user agar unik
      final String userSuffix = user.id.length >= 4 ? user.id.substring(0, 4).toUpperCase() : 'LNDR';
      final String notaNumber = 'NDR-$userSuffix-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Simpan Header Order
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'store_id': storeId,
            'nota_number': notaNumber,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'status': 'antrian',
            'payment_status': paymentStatus,
            'payment_method': paymentMethod,
            'perfume': perfume,
            'total': totalAmount,
          })
          .select('id')
          .single();

      final int orderId = orderResponse['id'];

      // 2. Simpan Detail Item Order
      final List<Map<String, dynamic>> itemsPayload = items.map((item) {
        return {
          'store_id': storeId,
          'user_id': user.id,
          'order_id': orderId,
          'service_name': item['service_name'],
          'qty': item['qty'],
          'price': item['price'],
          'subtotal': item['subtotal'],
        };
      }).toList();

      await _supabase.from('order_items').insert(itemsPayload);

      // Refresh data order menggunakan storeId yang sama
      await fetchOrders(storeId);
      return true;
    } catch (e) {
      debugPrint('Error createOrder: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
