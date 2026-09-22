import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isPremium = false;
  String _planType = 'free';
  DateTime? _endDate;
  bool _isLoading = false;

  // Getter buat dipakai di UI
  bool get isPremium => _isPremium;
  String get planType => _planType;
  DateTime? get endDate => _endDate;
  bool get isLoading => _isLoading;

  // Fungsi buat ngecek status premium user
  Future<void> checkSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _isPremium = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Ambil data dari tabel subscriptions
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle(); // maybeSingle = kalau gak ada data, return null (gak error)

      if (response != null) {
        _planType = response['plan_type'] ?? 'free';
        final status = response['status'];
        final endDateStr = response['end_date'];

        if (status == 'active' && endDateStr != null) {
          _endDate = DateTime.parse(endDateStr);
          // Cek apakah masih berlaku
          if (_endDate!.isAfter(DateTime.now())) {
            _isPremium = true;
          } else {
            _isPremium = false; // Udah expired
          }
        } else {
          _isPremium = false;
        }
      } else {
        // User belum pernah subscribe
        _isPremium = false;
        _planType = 'free';
      }
    } catch (e) {
      debugPrint('Error check subscription: $e');
      _isPremium = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi buat upload bukti transfer (Manual Payment)
  Future<bool> uploadPaymentProof({
    required String planType,
    required String proofUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Upsert = Insert kalau belum ada, Update kalau udah ada
      await _supabase.from('subscriptions').upsert({
        'user_id': user.id,
        'plan_type': planType,
        'status': 'pending',
        'proof_of_payment': proofUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error upload proof: $e');
      return false;
    }
  }
}
