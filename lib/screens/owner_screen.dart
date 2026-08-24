import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _greenAccent = Color(0xFF16A34A);
  static const Color _textBlack = Color(0xFF111827);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('nama_toko, no_hp, alamat')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['nama_toko'] ?? '';
          _phoneController.text = data['no_hp'] ?? '';
          _addressController.text = data['alamat'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error load profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: Scaffold(
            backgroundColor: _bgDark,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Profil Toko',
                style: TextStyle(color: _textBlack, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nama Toko', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bgDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Nomor WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bgDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Alamat Toko', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bgDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _greenAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) return;

                          await Supabase.instance.client.from('profiles').update({
                            'nama_toko': _nameController.text,
                            'no_hp': _phoneController.text,
                            'alamat': _addressController.text,
                          }).eq('id', user.id);

                          if (context.mounted) {
                            await context.read<SettingsProvider>().fetchStoreId();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profil toko berhasil diperbarui!')),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal memperbarui profil: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'SIMPAN PROFIL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
