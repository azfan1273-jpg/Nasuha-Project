import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/kasir_page_manager.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/order_provider.dart';


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
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'NASUHA Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFAF5F7),
      ),
      home: session != null ? const KasirPageManager() : const LoginScreen(),
    );
  }
}
