import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'superadmin@lndr.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  static const Color _bgDark = Color(0xFFFAF5F7);
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
        // StreamBuilder di main.dart otomatis memindahkan halaman ke KasirPageManager
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

  // 3. DIALOG LUPA PASSWORD
  void _showLupaPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lupa Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan email akun Anda untuk menerima link reset password:', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: resetEmailController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Email Akun',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await supabase.auth.resetPasswordForEmail(email);
                if (mounted) _showSnackBar('Link reset password telah dikirim ke email $email!');
              } catch (e) {
                if (mounted) _showSnackBar('Gagal mengirim link reset: $e', isError: true);
              }
            },
            child: const Text('Kirim Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. DIALOG REGISTRASI OWNER BARU
  void _showDaftarTokoDialog() {
    final namaTokoController = TextEditingController();
    final emailRegController = TextEditingController();
    final passwordRegController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Daftar Toko Baru (Owner)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogInput(namaTokoController, 'Nama Toko / Laundry'),
            const SizedBox(height: 10),
            _buildDialogInput(emailRegController, 'Email Owner', isEmail: true),
            const SizedBox(height: 10),
            _buildDialogInput(passwordRegController, 'Password', isPassword: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final namaToko = namaTokoController.text.trim();
              final email = emailRegController.text.trim();
              final password = passwordRegController.text.trim();

              if (namaToko.isEmpty || email.isEmpty || password.isEmpty) {
                _showSnackBar('Semua data wajib diisi!', isError: true);
                return;
              }

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final res = await supabase.auth.signUp(
                  email: email,
                  password: password,
                  data: {'nama_toko': namaToko, 'role': 'Owner'},
                );

                if (res.user != null && mounted) {
                  _showSnackBar('Pendaftaran berhasil! Silakan login dengan akun baru.');
                }
              } catch (e) {
                if (mounted) _showSnackBar('Gagal mendaftar: $e', isError: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Daftar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // HELPER INPUT DIALOG
  Widget _buildDialogInput(TextEditingController controller, String hint, {bool isEmail = false, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Akun',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textBlack,
                          ),
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

                      // INPUT PASSWORD LABEL & LUPA PASSWORD LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _textBlack,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showLupaPasswordDialog,
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pinkAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // KOTAK INPUT PASSWORD
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          style: const TextStyle(fontSize: 12, color: _textBlack),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.black45,
                              ),
                              onPressed: () {
                                setState(() => _isPasswordObscured = !_isPasswordObscured);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TOMBOL LOG IN
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
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.black12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('atau', style: TextStyle(fontSize: 10, color: Colors.black38)),
                          ),
                          Expanded(child: Divider(color: Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // TOMBOL GOOGLE
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

                      // LINK DAFTAR TOKO
                      GestureDetector(
                        onTap: _showDaftarTokoDialog,
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

                // DEKORASI MAWAR ATAS KIRI & BAWAH KANAN
                const Positioned(
                  top: -16,
                  left: -10,
                  child: Text('🌹🌿', style: TextStyle(fontSize: 26)),
                ),
                const Positioned(
                  bottom: -16,
                  right: -10,
                  child: Text('🌹🌿', style: TextStyle(fontSize: 26)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
