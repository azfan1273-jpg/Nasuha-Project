import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void showChangePasswordDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ChangePasswordDialogContent(),
  );
}

class ChangePasswordDialogContent extends StatefulWidget {
  const ChangePasswordDialogContent({super.key});

  @override
  State<ChangePasswordDialogContent> createState() => _ChangePasswordDialogContentState();
}

class _ChangePasswordDialogContentState extends State<ChangePasswordDialogContent> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isOldPasswordValid = false;
  bool _isCheckingOldPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOldPassword(String value) async {
    if (value.length < 6) {
      setState(() => _isOldPasswordValid = false);
      return;
    }
    setState(() => _isCheckingOldPassword = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: user!.email!,
          password: value,
        );
        setState(() {
          _isOldPasswordValid = response.user != null;
        });
      }
    } catch (e) {
      setState(() => _isOldPasswordValid = false);
    } finally {
      setState(() => _isCheckingOldPassword = false);
    }
  }

  Future<void> _submitChangePassword() async {
    if (!_isOldPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password lama salah!')),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password baru tidak cocok!')),
      );
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 6 karakter!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ganti password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: const Text(
        'Ganti Password',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Password Lama', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                onChanged: _verifyOldPassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: _isCheckingOldPassword
                      ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A))))
                      : _oldPasswordController.text.isNotEmpty
                          ? Icon(
                              _isOldPasswordValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _isOldPasswordValid ? const Color(0xFF16A34A) : Colors.red,
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Password Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Konfirm Password Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoading ? null : _submitChangePassword,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
