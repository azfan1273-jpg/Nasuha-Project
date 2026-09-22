import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/settings_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/kasir_page_manager.dart';
import 'screens/splash_screen.dart';
import 'providers/subscription_provider.dart';

SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env dulu
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
      title: 'Nasuha Kasir Laundry',
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
