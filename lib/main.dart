// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_provider.dart';
import 'kasir_home_screen.dart';
import 'login_screen.dart';
import 'kasir_page_manager.dart'; // Jika memakai layar geser

const String supabaseUrl = 'https://qcpxitlltkkxtdctertz.supabase.co';
const String supabaseAnonKey = 'sb_publishable_CeC_XB7zVoD26xBHmsKHKw_VxqWhPAG';

// Helpergetter aman untuk mengakses Supabase Client kapan saja
SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib inisialisasi Supabase sebelum runApp dijalankan
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const NasuhaApp(),
    ),
  );
}

class NasuhaApp extends StatelessWidget {
  const NasuhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASUHA Kasir',
      debugShowCheckedModeBanner: false,
      home: const KasirPageManager(), // Atau LoginScreen() / KasirHomeScreen()
    );
  }
}
