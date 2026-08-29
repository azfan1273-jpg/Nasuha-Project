import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/settings_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/kasir_page_manager.dart';
import 'screens/splash_screen.dart';

const String supabaseUrl = 'https://elesjrpswpppbliaifbw.supabase.co';
const String supabaseAnonKey = 'sb_publishable_iX0RtTSOEZjtsyz_wj4-aw_hgPjOIUZ';

SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
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
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFAF5F7),
      ),
      
      home: StreamBuilder<AuthState>(
                    stream: supabase.auth.onAuthStateChange,
                    builder: (context, snapshot) {
                      // Membaca session aktif secara akurat dari stream update
                      final session = snapshot.data?.session ?? supabase.auth.currentSession;
            
                      // Jika session kosong (setelah logout / belum login), lempar ke LoginScreen
                      if (session == null) {
                        return const LoginScreen();
                      }
            
                      // 🔹 TAHAP PENTING: Panggil fetchStoreId() begitu user terdeteksi login
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final settingsProvider = context.read<SettingsProvider>();
                        // Panggil fetch hanya jika storeId belum dimuat
                        if (settingsProvider.storeId == null) {
                          settingsProvider.fetchStoreId();
                        }
                      });
            
                      return const SplashScreen();
                    },
                  ),
    );
  }
}
