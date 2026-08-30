import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class SettingsProvider with ChangeNotifier {
  // --- STORE & PROFILE DATA ---
  String _namaToko = '';
  String _userRole = '';
  String _emailToko = '';
  String? _storeId;

  Map<String, dynamic>? _storeSettings;
  bool _isLoading = false;

  // 🟢 TAMBAHKAN DEKLARASI VARIABEL PRINTER DI SINI:
    BluetoothInfo? _selectedPrinter;
    BluetoothInfo? get selectedPrinter => _selectedPrinter;

  // --- DYNAMIC THEME STATE ---
  // Mode: 'default' (Pink) | 'gold' (Hitam Emas)
  String _selectedTheme = 'default';

  // Getters Data Store
  String get namaToko => _namaToko;
  String get userRole => _userRole;
  String get emailToko => _emailToko;
  String? get storeId => _storeId;
  Map<String, dynamic>? get storeSettings => _storeSettings;
  bool get isLoading => _isLoading;

  // Getter Tema Aktif
  String get selectedTheme => _selectedTheme;

  // 🟢 CONSTRUCTOR: Otomatis muat tema dari penyimpanan HP saat aplikasi pertama kali dibuka
    SettingsProvider() {
      _loadThemeFromPrefs();
    }

  // --- GETTER WARNA DINAMIS ---
  Color get bgDark => _selectedTheme == 'gold' 
      ? const Color(0xFF121212) // Hitam Pekat Latar Belakang
      : const Color(0xFFFAF5F7); // Pink Soft Soft Latar Belakang

  Color get cardDark => _selectedTheme == 'gold' 
      ? const Color(0xFF1E1E22) // Hitam Kartu Elegan
      : const Color(0xFFFCE7F3); // Pink Soft Kartu

  Color get accentColor => _selectedTheme == 'gold' 
      ? const Color(0xFFFFD700) // Warna Emas / Gold
      : const Color(0xFFEC4899); // Warna Pink Utama

  Color get textColor => _selectedTheme == 'gold' 
      ? const Color(0xFFF3F4F6) // Teks Terang (Gelap Mode)
      : const Color(0xFF111827); // Teks Gelap (Terang Mode)

  // 🟢 1. MUAT TEMA TERSIMPAN
      Future<void> _loadThemeFromPrefs() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          _selectedTheme = prefs.getString('app_theme') ?? 'default';
          notifyListeners();
        } catch (e) {
          debugPrint('Error loading theme from prefs: $e');
        }
      }
    
      // 🟢 2. SIMPAN PILIHAN TEMA SECARA PERMANEN
      Future<void> setTheme(String themeName) async {
        if (_selectedTheme == themeName) return;
        _selectedTheme = themeName;
        notifyListeners(); // Ubah UI secara instan
    
        // Simpan ke memori HP
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_theme', themeName);
        } catch (e) {
          debugPrint('Error saving theme to prefs: $e');
        }
      }

  // 1. FUNGSI FETCH STORE ID & PROFILE
  Future<void> fetchStoreId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('Log: User belum login / null');
        return;
      }
  
      final response = await Supabase.instance.client
          .from('profiles')
          .select('store_id, nama_toko')
          .eq('id', user.id)
          .maybeSingle();
  
      if (response != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response);
        
        _storeId = data['store_id']?.toString();
        _namaToko = data['nama_toko']?.toString() ?? '';
        notifyListeners();
  
        if (_storeId != null && _storeId!.isNotEmpty) {
          await fetchStoreSettings();
        }
      } else {
        debugPrint('Log: Profile user tidak ditemukan di database');
      }
    } catch (e) {
      debugPrint('Error fetching store_id: $e');
    }
  }

  // 2. FUNGSI FETCH DATA PENGATURAN TOKO
  Future<void> fetchStoreSettings() async {
    if (_storeId == null) return;
  
    _isLoading = true;
    notifyListeners();
  
    try {
      final response = await Supabase.instance.client
          .from('store_settings')
          .select()
          .eq('store_id', _storeId!)
          .maybeSingle();
  
      if (response != null) {
        _storeSettings = Map<String, dynamic>.from(response);
      } else {
        final defaultPayload = {
          'store_id': _storeId,
          'header_nama_toko': 'Jasa Laundry & Dry Cleaning', 
          'header_hp': '{{HP :}}',
          'footer_nota': 'Terima kasih telah mempercayakan pakaian Anda pada kami!',
          'footer_wa': 'Silakan simpan nomor ini untuk cek status laundry.',
          'notifikasi_wa': '-',
          'show_nama_kasir': true,
          'show_footer_nota': true,
          'show_footer_wa': true,
          'show_qr_code': true,
          'paper_size': '58 mm',
        };

        final inserted = await Supabase.instance.client
            .from('store_settings')
            .insert(defaultPayload)
            .select()
            .single();

        _storeSettings = Map<String, dynamic>.from(inserted);
      }
    } catch (e) {
      debugPrint('Error fetch or auto-create store settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. FUNGSI CLEAR SETTINGS (SAAT LOGOUT)
  void clearSettings() {
    _storeId = null;
    _namaToko = '';
    _userRole = '';
    _emailToko = '';
    _storeSettings = null;
    _selectedTheme = 'default';
    notifyListeners();
  } 

 // 🟢 SETTER TERHUBUNG DENGAN VARIABEL DI ATAS
  void setSelectedPrinter(BluetoothInfo? device) {
    _selectedPrinter = device;
    notifyListeners();
  }
}
