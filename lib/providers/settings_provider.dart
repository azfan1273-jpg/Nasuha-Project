import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppThemeMode { pink, dark }

class SettingsProvider with ChangeNotifier {

  static const String _themeKey = 'app_theme_mode'; // Key untuk penyimpanan lokal

  // --- KODE LAMA KAMU (namaToko, userRole, dll) TETAP DI SINI ---
  String _namaToko = 'NASUHA LAUNDRY';
  String _userRole = 'OWNER';
  String _emailToko = 'owner@lndr.com';

  String get namaToko => _namaToko;
  String get userRole => _userRole;
  String get emailToko => _emailToko;

  String? _storeId;
  String? get storeId => _storeId;

  // --- LOGIKA TEMA BARU (2 TEMA) ---
  AppThemeMode _currentTheme = AppThemeMode.pink;
  AppThemeMode get currentTheme => _currentTheme;

  Color get bgDark {
    return _currentTheme == AppThemeMode.dark
        ? const Color(0xFF121212) // Hitam Gelap
        : const Color(0xFFFAF5F7); // Pink Terang
  }

  Color get cardDark {
    return _currentTheme == AppThemeMode.dark
        ? const Color(0xFF1E1E24) // Kartu Gelap
        : const Color(0xFFFCE7F3); // Kartu Pink
  }

  Color get accentColor => const Color(0xFFEC4899); // Pink mencolok tetap sama

  Color get textColor {
    return _currentTheme == AppThemeMode.dark
        ? Colors.white
        : const Color(0xFF111827);
  }

  // Constructor: Otomatis memuat tema tersimpan saat aplikasi pertama kali dibuka
    SettingsProvider() {
    _loadThemeFromPrefs();
  }

	void clearSettings() {
	  _storeId = null; // Atau '' (sesuai tipe data storeId kamu, misal String/UUID)
	 	  notifyListeners();
	}

  Future<void> fetchStoreId() async {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;
  
        final response = await Supabase.instance.client
            .from('profiles')
            .select('store_id')
            .eq('id', user.id)
            .maybeSingle();
  
        if (response != null) {
          _storeId = response['store_id']?.toString();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error fetching store_id: $e');
      }
    }
  

  // 🔹 2. Memuat pilihan tema dari penyimpanan HP/Browser
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'dark') {
        _currentTheme = AppThemeMode.dark;
      } else {
        _currentTheme = AppThemeMode.pink;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat tema: $e');
    }
  }

  // 🔹 3. Menyimpan pilihan tema saat tombol diklik
  Future<void> setTheme(AppThemeMode theme) async {
    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme == AppThemeMode.dark ? 'dark' : 'pink');
    } 
      catch (e) {
      debugPrint('Gagal menyimpan tema: $e');
    }
  }
}
