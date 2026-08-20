import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> createOrder({
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

      final String notaNumber = 'NDR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // 1. Simpan Header Order
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
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
          'order_id': orderId,
          'service_name': item['service_name'],
          'qty': item['qty'],
          'price': item['price'],
          'subtotal': item['subtotal'],
        };
      }).toList();

      await _supabase.from('order_items').insert(itemsPayload);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error createOrder: $e');
      return false;
    }
  }
}
