import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _blueAccent = Color(0xFF0284C7);
  static const Color _textBlack = Color(0xFF111827);

  List<Map<String, dynamic>> _cashiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCashiers();
  }

  Future<void> _fetchCashiers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('profiles').select().eq('role', 'kasir');
      if (mounted) {
        setState(() {
          _cashiers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch cashiers: $e');
      if (mounted) setState(() => _isLoading = false);
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
              title: const Text('Kelola Akun Kasir', style: TextStyle(color: _textBlack, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _blueAccent))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cashiers.length,
                    itemBuilder: (context, index) {
                      final item = _cashiers[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.person_outline_rounded, color: _blueAccent, size: 20),
                          ),
                          title: Text(item['name'] ?? 'Kasir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(item['email'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
