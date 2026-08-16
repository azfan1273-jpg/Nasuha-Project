import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import 'kasir_page_manager.dart';
import 'kasir_home_screen.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'superadmin@gmail.com');
  final _passwordController = TextEditingController(text: '12345678');
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);
  static const Color _pinkAccent = Color(0xFFEC4899);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

	// 1. FUNGSI LOGIN DENGAN EMAIL & PASSWORD
  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan Password wajib diisi!', isError: true);
          return;
        }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
              _showSnackBar('Login berhasil! Selamat datang.');
              _navigateToHome();
            }
    	} on AuthException catch (e) {
     		 if (mounted) _showSnackBar(e.message, isError: true);
        } catch (e) {
              if (mounted) _showSnackBar('Terjadi kesalahan: $e', isError: true);
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          }
        // 2. FUNGSI LOGIN DENGAN GOOGLE (SUPABASE OAUTH)
          Future<void> _loginWithGoogle() async {
              setState(() => _isLoading = true);
          
              try {
                final String? currentDomain = kIsWeb ? Uri.base.origin : null;
          
                final bool redirectToWeb = await supabase.auth.signInWithOAuth(
                  OAuthProvider.google,
                  redirectTo: currentDomain,
                );
          
                if (!redirectToWeb && mounted) {
                  _showSnackBar('Gagal mengarahkan ke login Google', isError: true);
                }
              } on AuthException catch (e) {
                if (mounted) _showSnackBar(e.message, isError: true);
              } catch (e) {
                if (mounted) _showSnackBar('Gagal Login Google: $e', isError: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }
        
          void _navigateToHome() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const KasirHomeScreen()),
            );
          }
        
          void _showSnackBar(String message, {bool isError = false}) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message, style: const TextStyle(fontSize: 12)),
                backgroundColor: isError ? Colors.redAccent : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Stack(
                          clipBehavior: Clip.none,
            children: [
            // DEKORASI MAWAR ATAS KIRI
              const Positioned(
                top: -24,
                left: -10,
                child: Text('🌹🌿', style: TextStyle(fontSize: 28)),
              ),

              // CARD FORM LOGIN
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // LOGO TOKO
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: _pinkAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'LNDR KASIR LAUNDRY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: _textBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Masuk ke akun LNDR Anda',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    const SizedBox(height: 20),

					// INPUT EMAIL
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email Akun',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textBlack),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 12, color: _textBlack),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
					// INPUT PASSWORD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textBlack),
                          ),
                        
                        GestureDetector(
                         onTap: () => _showSnackBar('Fitur reset password belum diaktifkan'),
                         child: const Text(
                           'Lupa Password?',
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pinkAccent),
                         ),
                       ),
                     ],
                   ),
                    const SizedBox(height: 20),
                    
                    // TOMBOL LOG IN (EMAIL)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _loginWithEmail,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'LOG IN',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

					// SEPARATOR "ATAU"
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.black12)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('atau', style: TextStyle(fontSize: 10, color: Colors.black38)),
                        ),
                        Expanded(child: Divider(color: Colors.black12)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // TOMBOL LOGIN BY GOOGLE EMAIL
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _textBlack,
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 18,
                            width: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                          ),
                          label: const Text(
                            'Masuk dengan Google',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LINK DAFTAR TOKO BARU
                      GestureDetector(
                        onTap: () => _showSnackBar('Silakan hubungi Admin untuk pendaftaran toko baru'),
                        child: const Text(
                          'Belum punya akun? Daftar Toko Baru (Owner)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _pinkAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // DEKORASI MAWAR BAWAH KANAN
                const Positioned(
                  bottom: -24,
                  right: -10,
                  child: Text('🌿🌹', style: TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
