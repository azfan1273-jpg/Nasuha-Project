import 'package:flutter/material.dart';

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
}
