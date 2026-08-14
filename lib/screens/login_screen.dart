import 'package:flutter/material.dart';
import 'kasir_home_screen.dart';

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

  // PALET WARNA SENADA HOME SCREEN
  static const Color _bgDark = Color(0xFFFAF5F7);       // Cream Light Background
  static const Color _cardDark = Color(0xFFFCE7F3);     // Rose Soft Card Accent
  static const Color _goldAccent = Color(0xFFEC4899);   // Rose Blush Accent
  static const Color _textBlack = Color(0xFF111827);    // Hitam Pekat Tegas

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KasirHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. KARTU UTAMA LOGIN
              Container(
                width: 380,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _cardDark, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withOpacity(0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO BULAT NASUHA
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: _cardDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: _goldAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // NAMA TOKO & SUBTITLE
                    const Text(
                      'NASUHA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Masuk ke akun NASUHA Anda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // INPUT EMAIL AKUN
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email Akun',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 13, color: _textBlack),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _cardDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _cardDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _goldAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // INPUT PASSWORD & LUPA PASSWORD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _goldAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      style: const TextStyle(fontSize: 13, color: _textBlack),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _cardDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _cardDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _goldAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TOMBOL LOG IN
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOG IN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // LINK DAFTAR
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Belum punya akun? Daftar Toko Baru (Owner)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ORNAMEN MAWAR MENJALAR - KIRI ATAS
              Positioned(
                top: -18,
                left: -18,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Text(
                    '🌹🌿',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),

              // 3. ORNAMEN MAWAR MENJALAR - KANAN BAWAH
              Positioned(
                bottom: -18,
                right: -18,
                child: Transform.rotate(
                  angle: 2.8,
                  child: const Text(
                    '🌹🌿',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
