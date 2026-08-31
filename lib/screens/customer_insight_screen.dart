import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<Map<String, dynamic>> _predictions = [];
  
  int _totalPotensial = 0;
  num _totalEstOmset = 0;

  @override
  void initState() {
    super.initState();
    _analyzePredictions();
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
        totalOmsetAcc += (num.tryParse(item['est_spend']?.toString() ?? '0') ?? 0);
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

  Future<void> _sendWhatsAppReminder(String phone, String name) async {
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

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
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
            onPressed: _analyzePredictions,
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
                          item['name'] ?? '-',
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
                    final int score = item['score'] ?? 0;
                    final num estSpend = item['est_spend'] ?? 0;
                    final int totalTx = item['total_tx'] ?? 0;
                    final String contribution = item['contribution'] ?? '0%';

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
                              item['reason'] ?? '-',
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
                              item['favorite_service'] ?? 'Cuci Komplit',
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
                              onTap: () => _sendWhatsAppReminder(item['phone'] ?? '', item['name'] ?? ''),
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
