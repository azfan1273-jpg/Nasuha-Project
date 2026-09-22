import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

class PremiumAkunScreen extends StatefulWidget {
  const PremiumAkunScreen({super.key});

  @override
  State<PremiumAkunScreen> createState() => _PremiumAkunScreenState();
}

class _PremiumAkunScreenState extends State<PremiumAkunScreen> {
  // Pilihan paket: 'bulanan' atau 'tahunan'
  String _selectedPlan = 'bulanan';

  @override
  void initState() {
    super.initState();
    // Cek status premium user pas halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().checkSubscriptionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Akun'),
        backgroundColor: Colors.pink.shade50,
      ),
      body: subProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==== KARTU STATUS USER ====
                  _buildStatusCard(subProvider),
                  const SizedBox(height: 24),

                  // ==== PILIHAN PAKET ====
                  const Text(
                    'Pilih Paket Langganan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanOption(
                    planId: 'bulanan',
                    title: 'Bulanan',
                    price: 'Rp 50.000',
                    period: '/ bulan',
                    isSelected: _selectedPlan == 'bulanan',
                  ),
                  const SizedBox(height: 12),
                  _buildPlanOption(
                    planId: 'tahunan',
                    title: 'Tahunan',
                    price: 'Rp 500.000',
                    period: '/ tahun',
                    subtitle: 'Hemat 2 bulan!',
                    isSelected: _selectedPlan == 'tahunan',
                  ),
                  const SizedBox(height: 24),

                  // ==== LIST FITUR PREMIUM ====
                  const Text(
                    'Fitur Premium:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('Analisis Pelanggan (Clay Engine)'),
                  _buildFeatureItem('Export Laporan Keuangan'),
                  _buildFeatureItem('Multi-Cabang'),
                  _buildFeatureItem('Support Prioritas'),
                  const SizedBox(height: 32),

                  // ==== TOMBOL UPGRADE ====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: subProvider.isPremium
                          ? null // Kalau udah premium, tombol mati
                          : () => _handleUpgrade(subProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        subProvider.isPremium
                            ? 'Anda Sudah Premium ✨'
                            : 'Upgrade Sekarang',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==== WIDGET: Kartu Status User ====
  Widget _buildStatusCard(SubscriptionProvider subProvider) {
    final isPremium = subProvider.isPremium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [Colors.amber.shade400, Colors.orange.shade600]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.person,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                isPremium ? 'Premium Member' : 'Free Member',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Paket: ${subProvider.planType}\nBerakhir: ${_formatDate(subProvider.endDate)}'
                : 'Upgrade untuk membuka semua fitur eksklusif.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==== WIDGET: Pilihan Paket ====
  Widget _buildPlanOption({
    required String planId,
    required String title,
    required String price,
    required String period,
    String? subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.pink.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: planId,
              groupValue: _selectedPlan,
              activeColor: Colors.pink,
              onChanged: (val) => setState(() => _selectedPlan = val!),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                Text(period, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==== WIDGET: Item Fitur ====
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ==== Helper Format Tanggal ====
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==== Handler Tombol Upgrade ====
  void _handleUpgrade(SubscriptionProvider subProvider) {
    // SEMENTARA: Tampilkan dialog konfirmasi dulu.
    // Nanti di sini kita ganti dengan alur Midtrans / manual transfer.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Upgrade'),
        content: Text(
          'Anda akan berlangganan paket $_selectedPlan.\n\n'
          'Fitur pembayaran otomatis akan segera hadir. '
          'Sementara ini, silakan hubungi admin untuk proses manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Nanti arahkan ke halaman pembayaran / upload bukti transfer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur pembayaran segera hadir!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
