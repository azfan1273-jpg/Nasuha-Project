import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/customer_insight_engine.dart';
import '../providers/settings_provider.dart';
import 'customer_detail_screen.dart';

class CustomerInsightScreen extends StatefulWidget {
  const CustomerInsightScreen({super.key});

  @override
  State<CustomerInsightScreen> createState() => _CustomerInsightScreenState();
}

class _CustomerInsightScreenState extends State<CustomerInsightScreen> {
  bool _isLoading = true;
  bool _isLoadingTopCustomers = false;
  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> _topCustomers = [];
  num _totalStoreRevenue = 0;
  int _totalPotensial = 0;
  num _totalEstOmset = 0;

  @override
  void initState() {
    super.initState();
    _analyzePredictions();
    _fetchTopCustomers();
  }

  // Helper format rupiah simple
  String _formatRupiahSimple(num number) {
    if (number == null || number == 0) return '0';
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  // Format rupiah lengkap
  String _formatRupiah(num number) {
    if (number == null || number == 0) return 'Rp 0';
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  Future<void> _analyzePredictions() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final predictions = await CustomerInsightEngine.fetchTomorrowPredictions(storeId: storeId);
      num totalOmsetAcc = 0;
      
      for (var item in predictions) {
        final val = item['est_spend'] ?? item['estimated_omset'] ?? 0;
        if (val is num) {
          totalOmsetAcc += val;
        } else {
          totalOmsetAcc += num.tryParse(val.toString()) ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _predictions = predictions;
          _totalPotensial = predictions.length;
          _totalEstOmset = totalOmsetAcc;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error screen engine: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Function fetch top customers
  Future<void> _fetchTopCustomers() async {
    setState(() => _isLoadingTopCustomers = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        setState(() => _isLoadingTopCustomers = false);
        return;
      }
  
      final response = await Supabase.instance.client.rpc(
        'get_top_customers',
        params: {
          'p_store_id': storeId,
          'p_limit': 20,
        },
      );
  
      if (response != null) {
        final topCustomersData = response['top_customers'];
        final totalRevenue = response['total_store_revenue'] ?? 0; // ✅ AMBIL TOTAL OMSET
        
        if (topCustomersData is List) {
          setState(() {
            _topCustomers = List<Map<String, dynamic>>.from(topCustomersData);
            _totalStoreRevenue = num.tryParse(totalRevenue.toString()) ?? 0; // ✅ SIMPAN
            _isLoadingTopCustomers = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch top customers: $e');
      setState(() => _isLoadingTopCustomers = false);
    }
  }

  // Function untuk cashback/reminder WhatsApp
  Future<void> _sendCashbackOffer(Map<String, dynamic> customer) async {
    final phone = customer['customer_phone']?.toString() ?? '';
    final name = customer['customer_name']?.toString() ?? 'Pelanggan';
    final totalRevenue = customer['total_revenue'] ?? 0;
    
    if (phone.isEmpty || phone == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Format nomor
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    // Pesan cashback
    final message = Uri.encodeComponent(
      'Halo Kak $name! Terima kasih sudah menjadi pelanggan setia Nasuha Laundry. '
      'Sebagai apresiasi untuk transaksi senilai Rp ${_formatRupiahSimple(totalRevenue)}, '
      'kami berikan diskon spesial 10% untuk transaksi berikutnya! '
      'Silakan tunjukkan pesan ini ke kasir. 🎁',
    );

    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$message';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendWhatsAppReminder(String phone, String name) async {
    if (phone.isEmpty || phone == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    String formattedPhone = cleanPhone;
    if (cleanPhone.startsWith('0')) {
      formattedPhone = '62${cleanPhone.substring(1)}';
    }

    final message = Uri.encodeComponent(
      "Halo Kak $name! Laundry pakaiannya sudah masuk jadwal cuci rutin nih. Yuk laundry hari ini agar pakaian tetap bersih & harum! 😊",
    );

    final url = Uri.parse("https://wa.me/$formattedPhone?text=$message");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252528),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Customer Insight Engine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _analyzePredictions();
              _fetchTopCustomers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Potensi Masuk',
                          value: '$_totalPotensial Pelanggan',
                          subtitle: 'Prediksi Akurasi AI 90%+',
                          icon: Icons.psychology_rounded,
                          accentColor: const Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Proyeksi Kas',
                          value: _formatRupiah(_totalEstOmset),
                          subtitle: 'Estimasi Esok Hari',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Prediksi Pelanggan Datang Esok Hari',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Geser tabel ke kanan untuk melihat status RFM & tombol Follow Up WA',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _predictions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text('Belum ada data riwayat yang mencukupi untuk diprediksi', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : _buildFrozenPredictionTable(),
                  const SizedBox(height: 24),
                  // Top Customers Table
                  _buildTopCustomersTable(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildFrozenPredictionTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KOLOM STABIL (FROZEN: NAMA PELANGGAN)
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  color: const Color(0xFF252528),
                  child: const Text(
                    'Pelanggan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Colors.white12),
                ..._predictions.map((item) {
                  final String tag = item['tag'] ?? 'Aktif';
                  final String customerName = item['customer_name'] ?? item['name'] ?? '-';
                  return Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            color: tag == 'VIP' ? Colors.amber : (tag == 'Resiko Churn' ? Colors.redAccent : Colors.lightGreenAccent),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Container(width: 1, color: Colors.white12),
          // 2. KOLOM SCROLLABLE HORIZONTAL
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    color: const Color(0xFF252528),
                    child: const Row(
                      children: [
                        _HeaderCell(title: 'Skor AI', width: 65),
                        _HeaderCell(title: 'Analisis Siklus', width: 140),
                        _HeaderCell(title: 'Est. Omset', width: 110),
                        _HeaderCell(title: 'Layanan Favorit', width: 130),
                        _HeaderCell(title: 'Total Tx', width: 80),
                        _HeaderCell(title: 'Kontribusi', width: 80),
                        _HeaderCell(title: 'Follow-Up', width: 90, isCenter: true),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.white12),
                  ..._predictions.map((item) {
                    // Parsing nilai aman dengan fallback key dari API Vercel
                    final int score = (item['score'] ?? item['ai_score'] ?? 0).toInt();
                    final num estSpend = item['est_spend'] ?? item['estimated_omset'] ?? 0;
                    final int totalTx = item['total_tx'] ?? item['transaction_count'] ?? 0;
                    final String contribution = item['contribution'] ?? '0%';
                    final String reason = item['reason'] ?? item['cycle_analysis'] ?? '-';
                    final String favorite = item['favorite_service'] ?? item['service'] ?? '-';
                    final String customerName = item['customer_name'] ?? item['name'] ?? '-';
                    final String phone = item['phone'] ?? item['customer_phone'] ?? '';
                    
                    Color badgeColor = Colors.orange;
                    if (score >= 80) badgeColor = const Color(0xFF00E676);
                    else if (score >= 55) badgeColor = Colors.amber;

                    return Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          _DataCell(
                            width: 65,
                            child: Text(
                              '$score%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                          _DataCell(
                            width: 140,
                            child: Text(
                              reason,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _DataCell(
                            width: 110,
                            child: Text(
                              _formatRupiah(estSpend),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                            ),
                          ),
                          _DataCell(
                            width: 130,
                            child: Text(
                              favorite,
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _DataCell(
                            width: 80,
                            child: Text(
                              '$totalTx Order',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                            ),
                          ),
                          _DataCell(
                            width: 80,
                            child: Text(
                              contribution,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ),
                          // Tombol WA Follow Up
                          _DataCell(
                            width: 90,
                            child: InkWell(
                              onTap: () => _sendWhatsAppReminder(phone, customerName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_rounded, size: 12, color: Colors.greenAccent),
                                    SizedBox(width: 4),
                                    Text('WA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }

  // Widget untuk Top Customers Table
  Widget _buildTopCustomersTable() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            ' Top 20 Pelanggan Setia',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          // ✅ INFO TOTAL OMSET TOKO (KOTAK 3D)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A2A2E),
                  Color(0xFF1E1E22),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E676).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF00E676),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Total Omset Toko',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatRupiah(_totalStoreRevenue),
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _isLoadingTopCustomers
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF00E676)),
                  ),
                )
              : _topCustomers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'Belum ada data pelanggan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : _buildTopCustomersTableContent(),
        ],
      ),
    );
  }

  Widget _buildTopCustomersTableContent() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 42,
              color: const Color(0xFF252528),
              child: const Row(
                children: [
                  SizedBox(width: 80, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 130, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Nama Pelanggan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 110, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Total (Rp)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 80, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Total TX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 130, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Layanan Favorit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 80, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Kontribusi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                  SizedBox(width: 100, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)))),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.white12),
            // Data rows
            ..._topCustomers.map((customer) {
              final status = customer['customer_status'] ?? 'Reguler';
              final name = customer['customer_name'] ?? '-';
              final totalRevenue = customer['total_revenue'] ?? 0;
              final totalTx = customer['total_transactions'] ?? 0;
              final favoriteService = customer['favorite_service'] ?? '-';
              final contributionPercent = customer['contribution_percent'];
              
              // Fix: Handle contribution yang bisa jadi String atau num
              String contributionText = '0%';
              if (contributionPercent is String) {
                contributionText = contributionPercent.contains('%') ? contributionPercent : '${contributionPercent}%';
              } else if (contributionPercent is num) {
                contributionText = '${contributionPercent.toStringAsFixed(1)}%';
              }

              Color statusColor = Colors.grey;
              if (status == 'VVIP') statusColor = const Color(0xFFFFD700);
              else if (status == 'VIP') statusColor = const Color(0xFFEC4899);
              else if (status == 'Best') statusColor = Colors.cyanAccent;

              return Container(
                height: 52,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _formatRupiahSimple(totalRevenue),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$totalTx',
                          style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          favoriteService,
                          style: const TextStyle(fontSize: 10, color: Colors.white60),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          contributionText,
                          style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: InkWell(
                          onTap: () => _sendCashbackOffer(customer),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.card_giftcard, size: 12, color: Colors.amber),
                                SizedBox(width: 4),
                                Text('Cashback', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final bool isCenter;
  
  const _HeaderCell({
    required this.title,
    required this.width,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: isCenter ? Alignment.center : Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;
  final double width;
  
  const _DataCell({
    required this.child,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
