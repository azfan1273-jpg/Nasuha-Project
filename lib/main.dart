import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/settings_provider.dart';
import 'screens/kasir_home_screen.dart';

// ISI DENGAN CREDENTIAL SUPABASE KAMU NANTI
const String supabaseUrl = 'https://qcpxitlltkkxtdctertz.supabase.co';
const String supabaseAnonKey = 'sb_publishable_CeC_XB7zVoD26xBHmsKHKw_VxqWhPAG';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (Jika URL belum diisi, panggil app tanpa crash)
  if (supabaseUrl != 'https://qcpxitlltkkxtdctertz.supabase.co') {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

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
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const KasirHomeScreen(),
    );
  }
}
