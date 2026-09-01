import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';

class PiutangScreen extends StatefulWidget {
  const PiutangScreen({Key? key}) : super(key: key);

  @override
  State<PiutangScreen> createState() => _PiutangScreenState();
}

class _PiutangScreenState extends State<PiutangScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _listPiutang = [];

  @override
  void initState() {
    super.initState();
    _fetchPiutangData();
  }

  Future<void> _fetchPiutangData() async {
      setState(() => _isLoading = true);
      try {
        final storeId = context.read<SettingsProvider>().storeId;
        if (storeId == null) return;
  
        final response = await supabase
            .from('orders')
            .select('*')
            .eq('store_id', storeId)
            .eq('status_pembayaran', 'Belum Lunas')
            .order('created_at', ascending: false);
  
        if (mounted) {
          final list = List<Map<String, dynamic>>.from(response);
          
          // HITUNG TOTAL SELURUH PIUTANG
          double totalSemuaPiutang = 0;
          for (var item in list) {
            final nominal = num.tryParse(
                  item['grand_total']?.toString() ?? 
                  item['total']?.toString() ?? 
                  item['total_harga']?.toString() ?? '0'
                )?.toDouble() ?? 0.0;
            totalSemuaPiutang += nominal;
          }
  
          setState(() {
            _listPiutang = list;
            _isLoading = false;
          });
  
          // Kirim balik total piutang ke ReportScreen saat pop / kembali
          // (Opsional, atau kita bisa buat state lokal di report screen)
        }
      } catch (e) {
        debugPrint('Error fetch piutang: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }

  Future<void> _bayarPiutang(dynamic orderId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Ubah status pembayaran jadi Lunas dan catat waktu pelunasan
      await supabase.from('orders').update({
        'status_pembayaran': 'Lunas',
        'waktu_pelunasan': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piutang berhasil dilunasi!')),
        );
        _fetchPiutangData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melunasi piutang: $e')),
        );
      }
    }
  }

  String _formatRupiah(num amount) {
    final str = amount.abs().toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        title: Text('Daftar Piutang Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: settings.textColor)),
        backgroundColor: settings.cardDark,
        foregroundColor: settings.textColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: settings.accentColor))
          : _listPiutang.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      Text('Tidak ada piutang aktif saat ini!', style: TextStyle(color: settings.textColor.withOpacity(0.7), fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPiutangData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _listPiutang.length,
                    itemBuilder: (context, index) {
                      final item = _listPiutang[index];
                      final nota = item['nota_number'] ?? '-';
                      final customer = item['customer_name'] ?? 'Umum';
                      final total = num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
                      final date = item['created_at']?.toString().split('T')[0] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: settings.cardDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(nota, style: TextStyle(fontWeight: FontWeight.bold, color: settings.accentColor, fontSize: 13)),
                                  Text(date, style: TextStyle(color: settings.textColor.withOpacity(0.5), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(customer, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: settings.textColor)),
                              const SizedBox(height: 4),
                              Text('Total Tagihan: ${_formatRupiah(total)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _bayarPiutang(item['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: const Text('Lunasi Piutang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
