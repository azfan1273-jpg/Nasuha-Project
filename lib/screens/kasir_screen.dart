import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

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
  String _storeCode = '------';
  bool _isLoadingCode = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreCode();
    _fetchCashiers();
  }

  // 1. AMBIL KODE 6 DIGIT TOKO MILIK OWNER
  Future<void> _fetchStoreCode() async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) return;

      final data = await supabase
          .from('stores')
          .select('store_code')
          .eq('id', storeId)
          .maybeSingle();

      if (data != null && data['store_code'] != null && mounted) {
        setState(() {
          _storeCode = data['store_code'].toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetch store code: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCode = false);
    }
  }

  // 2. FETCH KASIR KHUSUS TOKO INI (RLS SECURE)
  Future<void> _fetchCashiers() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Wajib filter store_id agar data kasir antar-toko tidak bocor
      final data = await supabase
          .from('profiles')
          .select()
          .eq('role', 'kasir')
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

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

  // 3. HAPUS / CABUT AKSES KASIR
  Future<void> _deleteCashier(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cabut Akses Kasir',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus akun kasir "$name"? Pegawai ini tidak akan bisa mengakses kasir toko lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Akses', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('profiles').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Akses kasir "$name" telah dihapus')),
          );
        }
        _fetchCashiers();
      } catch (e) {
        debugPrint('Error delete cashier: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola Akun Kasir',
          style: TextStyle(
            color: _textBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchStoreCode();
            await _fetchCashiers();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🟢 KARTU KODE TOKO 6 DIGIT UNTUK KASIR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode Pendaftaran Kasir',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bagikan 6 digit kode ini ke pegawai agar bisa mendaftar mandiri.',
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _storeCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode toko berhasil disalin!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _isLoadingCode ? '...' : _storeCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // BANNER INFORMASI RINGKAS TOTAL KASIR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _blueAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Kasir: ${_cashiers.length} Pegawai',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kasir memiliki kewenangan mencatat transaksi & melihat riwayat operasional toko.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Daftar Pegawai Kasir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              // LIST KASIR / EMPTY STATE[cite: 3]
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(color: _blueAccent)),
                    )
                  : _cashiers.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Belum Ada Kasir Terdaftar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Bagikan kode toko di atas agar pegawai dapat mendaftar mandiri.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cashiers.length,
                          itemBuilder: (context, index) {
                            final item = _cashiers[index];
                            // 🟢 Membaca kolom nama_pegawai sesuai database baru
                            final name = item['nama_pegawai'] ?? 'Kasir';
                            final email = item['email'] ?? '-';
                            final phone = item['phone'] ?? '-';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE0F2FE),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'K',
                                    style: const TextStyle(
                                      color: _blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _textBlack,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: const Text(
                                        'Kasir Aktif',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Email: $email',
                                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                                    ),
                                    Text(
                                      'No. HP: $phone',
                                      style: const TextStyle(fontSize: 10, color: Colors.black45),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  tooltip: 'Hapus Akses Kasir',
                                  onPressed: () => _deleteCashier(
                                    item['id'].toString(),
                                    name,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
