import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterCashierScreen extends StatefulWidget {
  const RegisterCashierScreen({super.key});

  @override
  State<RegisterCashierScreen> createState() => _RegisterCashierScreenState();
}

class _RegisterCashierScreenState extends State<RegisterCashierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _storeCodeController.dispose();
    super.dispose();
  }

  Future<void> _registerCashier() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final storeCode = _storeCodeController.text.trim();

      // 1. Cek apakah kode toko (store_code) valid dan terdaftar di database
      final storeData = await supabase
          .from('stores')
          .select('id')
          .eq('store_code', storeCode)
          .maybeSingle();

      if (storeData == null) {
        throw Exception('Kode Toko tidak ditemukan! Pastikan kode 6 digit benar.');
      }

      final storeId = storeData['id'];

      // 2. Daftarkan akun baru ke Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;
      if (user == null) throw Exception('Gagal membuat akun autentikasi.');

      // 3. Masukkan atau perbarui data profil pegawai ke tabel profiles menggunakan upsert
      await supabase.from('profiles').upsert({
        'id': user.id, // Menghubungkan langsung dengan auth.users
        'store_id': storeId,
        'nama_pegawai': _nameController.text.trim(),
        'role': 'kasir',
      });

      if (mounted) {
        // Sign out otomatis agar kasir melakukan login manual secara bersih dari awal
        await supabase.auth.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi kasir berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman login
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        
        // Terjemahkan pesan error jika email sudah terdaftar
        if (errorMessage.contains('user_already_exists') || errorMessage.contains('already registered')) {
          errorMessage = 'Email ini sudah terdaftar! Gunakan email lain.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // WAJIB: Mematikan indikator loading agar tidak muter terus
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F7),
      appBar: AppBar(
        title: const Text('Daftar Akun Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan informasi akun dan kode 6 digit yang diberikan oleh Owner toko.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                
                // Input Nama Lengkap
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', filled: true, fillColor: Colors.white),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Input Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Kasir', filled: true, fillColor: Colors.white),
                  validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 12),

                // Input Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 12),

                // Input Kode Toko 6 Digit
                TextFormField(
                  controller: _storeCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Kode Toko (6 Angka dari Owner)', 
                    filled: true, 
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                  validator: (v) => v == null || v.length != 6 ? 'Kode toko harus 6 digit' : null,
                ),
                const SizedBox(height: 24),

                // Tombol Daftar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _registerCashier,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('DAFTAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
