import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsProvider with ChangeNotifier {
  // --- STORE & PROFILE DATA ---
  String _namaToko = '';
  String _userRole = '';
  String _emailToko = '';
  String? _storeId;

  Map<String, dynamic>? _storeSettings;
  bool _isLoading = false;

  // Getters Data Store
  String get namaToko => _namaToko;
  String get userRole => _userRole;
  String get emailToko => _emailToko;
  String? get storeId => _storeId;
  Map<String, dynamic>? get storeSettings => _storeSettings;
  bool get isLoading => _isLoading;

  // --- GETTER WARNA UTUH (UNTUK MENCEGAH ERROR UI) ---
  Color get bgDark => const Color(0xFFFAF5F7);
  Color get cardDark => const Color(0xFFFCE7F3);
  Color get accentColor => const Color(0xFFEC4899);
  Color get textColor => const Color(0xFF111827);

  // 🔹 1. FUNGSI FETCH STORE ID & PROFILE (KODE UTAMA KAMU)
  Future<void> fetchStoreId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('Log: User belum login / null');
        return;
      }
  
      // Ambil store_id dari profiles
      final response = await Supabase.instance.client
          .from('profiles')
          .select('store_id, nama_toko')
          .eq('id', user.id)
          .maybeSingle();
  
      if (response != null) {
        // Cast response ke Map biar gak kena error TypeError _JsonMap
        final Map<String, dynamic> data = Map<String, dynamic>.from(response);
        
        _storeId = data['store_id']?.toString();
        _namaToko = data['nama_toko']?.toString() ?? '';
        notifyListeners();
  
        // Cek apakah storeId beneran ketemu
        if (_storeId != null && _storeId!.isNotEmpty) {
          await fetchStoreSettings();
        }/* else {
          debugPrint('Log: store_id di tabel profiles masih kosong/null');
        }*/
      } else {
        debugPrint('Log: Profile user tidak ditemukan di database');
      }
    } catch (e) {
      debugPrint('Error fetching store_id: $e');
    }
  }

  // 🔹 2. FUNGSI FETCH DATA PENGATURAN TOKO (PRINTER & NOTA FROM SUPABASE)
  Future<void> fetchStoreSettings() async {
    if (_storeId == null) return;
  
    _isLoading = true;
    notifyListeners();
  
    try {
      // RLS di Supabase akan otomatis memfilter sesuai store_id user yang login
      final response = await Supabase.instance.client
          .from('store_settings')
          .select()
          .eq('store_id', _storeId!)
          .maybeSingle();
  
      if (response != null) {
        // Lakukan casting eksplisit dari _JsonMap ke Map<String, dynamic>
        _storeSettings = Map<String, dynamic>.from(response);
      } else {
        _storeSettings = null;
      }
    } catch (e) {
      debugPrint('Error fetch store settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 3. FUNGSI CLEAR SETTINGS (SAAT LOGOUT)
  void clearSettings() {
    _storeId = null;
    _namaToko = '';
    _userRole = '';
    _emailToko = '';
    _storeSettings = null;
    notifyListeners();
  }
}
