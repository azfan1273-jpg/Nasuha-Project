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

  // Create Order menggunakan RPC Supabase
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

      // Ringkasan layanan untuk kolom service_name
      final String serviceSummary = items.map((e) => e['service_name']).join(', ');

      // 🟢 PANGGIL RPC SUPABASE (Format NASUHA- & waktu_pelunasan dihandle backend)
      await _supabase.rpc('create_order_with_items', params: {
        'p_store_id': storeId,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_service_summary': serviceSummary,
        'p_total_price': totalAmount,
        'p_estimated_at': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'p_status': 'Pending',
        'p_metode_pembayaran': paymentStatus.toLowerCase() == 'lunas' ? paymentMethod : null,
        'p_items': items,
        'p_created_at': DateTime.now().toIso8601String(),
        'p_parfum': perfume,
        'p_catatan': '-',
      });

      // Refresh data order menggunakan storeId yang sama
      await fetchOrders(storeId);
      return true;
    } catch (e) {
      debugPrint('Error createOrder via RPC: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
