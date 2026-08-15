import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsProvider with ChangeNotifier {
  String _namaToko = 'NASUHA LAUNDRY';
  String _userRole = 'OWNER';
  String _emailToko = 'owner@lndr.com';

  String get namaToko => _namaToko;
  String get userRole => _userRole;
  String get emailToko => _emailToko;

  void updateToko({required String nama, required String role, required String email}) {
    _namaToko = nama;
    _userRole = role;
    _emailToko = email;
    notifyListeners();
  }

  void loadFromUser(User? user) {
    if (user != null) {
      _emailToko = user.email ?? _emailToko;
      final meta = user.userMetadata;
      if (meta != null) {
        if (meta['nama_toko'] != null) _namaToko = meta['nama_toko'];
        if (meta['role'] != null) _userRole = meta['role'];
      }
      notifyListeners();
    }
  }

  void reset() {
    _namaToko = 'NASUHA LAUNDRY';
    _userRole = 'OWNER';
    _emailToko = 'owner@lndr.com';
    notifyListeners();
  }
}
