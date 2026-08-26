import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../providers/settings_provider.dart';
import '../widgets/form_pengeluaran_dialog.dart';
import 'chart_screen.dart'; // Menggunakan widget chart asli projek kamu!

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isExporting = false;

  String _filterPeriode = 'Hari Ini';
  String _activeTabChart = 'Omset'; // 'Omset', 'Pendapatan', 'Pengeluaran', 'Profit'

  double _totalOmset = 0;
  double _totalPengeluaran = 0;
  
  // Data Metode Pembayaran
  double _cashTotal = 0;
  double _qrisTotal = 0;

  List<dynamic> _rawOrders = [];
  List<dynamic> _rawExpenses = [];
  List<Map<String, dynamic>> _listPengeluaran = [];

  @override
  void initState() {
    super.initState();
    _loadLaporanKeuangan();
  }

  Future<void> _loadLaporanKeuangan() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) return;

      final now = DateTime.now();
      DateTime startDate;

      if (_filterPeriode == 'Hari Ini') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_filterPeriode == 'Minggu Ini') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
      } else {
        startDate = DateTime(now.year, now.month, 1);
      }

      final startDateIso = startDate.toIso8601String();

      // 1. Fetch Orders
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_price, payment_method, created_at, status_pembayaran')
          .eq('store_id', storeId)
          .gte('created_at', startDateIso);

      double omset = 0;
      double cash = 0;
      double qris = 0;

      for (var row in ordersResponse) {
        final price = ((row['total_price'] ?? 0) as num).toDouble();
        omset += price;
        
        final method = (row['payment_method'] ?? '').toString().toLowerCase();
        if (method.contains('cash') || method.contains('tunai')) {
          cash += price;
        } else {
          qris += price;
        }
      }

      // 2. Fetch Expenses
      final expensesResponse = await _supabase
          .from('expenses')
          .select('*')
          .eq('store_id', storeId)
          .gte('created_at', startDateIso)
          .order('created_at', ascending: false);

      double pengeluaran = 0;
      for (var row in expensesResponse) {
        pengeluaran += ((row['amount'] ?? 0) as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalOmset = omset;
          _totalPengeluaran = pengeluaran;
          _cashTotal = cash;
          _qrisTotal = qris;
          _rawOrders = ordersResponse;
          _rawExpenses = expensesResponse;
          _listPengeluaran = List<Map<String, dynamic>>.from(expensesResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // LOGIKA EXPORT EXCEL (.xlsx)
  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excel = excel_lib.Excel.createExcel();
      
      // Sheet 1: Ringkasan
      final excel_lib.Sheet sheet1 = excel['Ringkasan Keuangan'];
      sheet1.appendRow([excel_lib.TextCellValue('LAPORAN KEUANGAN LAUNDRY')]);
      sheet1.appendRow([excel_lib.TextCellValue('Periode: $_filterPeriode')]);
      sheet1.appendRow([]);
      sheet1.appendRow([excel_lib.TextCellValue('Kategori'), excel_lib.TextCellValue('Nominal')]);
      sheet1.appendRow([excel_lib.TextCellValue('Total Omset'), excel_lib.TextCellValue(_totalOmset.toString())]);
      sheet1.appendRow([excel_lib.TextCellValue('Total Pengeluaran'), excel_lib.TextCellValue(_totalPengeluaran.toString())]);
      sheet1.appendRow([excel_lib.TextCellValue('Laba Bersih'), excel_lib.TextCellValue((_totalOmset - _totalPengeluaran).toString())]);

      // Sheet 2: Detail Pengeluaran
      final excel_lib.Sheet sheet2 = excel['Detail Pengeluaran'];
      sheet2.appendRow([excel_lib.TextCellValue('Tanggal'), excel_lib.TextCellValue('Kategori'), excel_lib.TextCellValue('Catatan'), excel_lib.TextCellValue('Nominal')]);

      for (var item in _listPengeluaran) {
        sheet2.appendRow([
          excel_lib.TextCellValue(item['created_at'].toString().split('T')[0]),
          excel_lib.TextCellValue(item['category'] ?? 'Lain-lain'),
          excel_lib.TextCellValue(item['notes'] ?? '-'),
          excel_lib.TextCellValue((item['amount'] ?? 0).toString()),
        ]);
      }

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Laporan_Keuangan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan Excel berhasil dibuat! Opening...')),
        );
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint('Error export excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final labaBersih = _totalOmset - _totalPengeluaran;
    final profitMargin = _totalOmset > 0 ? ((labaBersih / _totalOmset) * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Laporan Keuangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            value: _filterPeriode,
            underline: const SizedBox(),
            items: ['Hari Ini', 'Minggu Ini', 'Bulan Ini'].map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _filterPeriode = val);
                _loadLaporanKeuangan();
              }
            },
          ),
          IconButton(
            icon: _isExporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.table_chart_rounded, color: Colors.green),
            tooltip: 'Export ke Excel',
            onPressed: _isExporting ? null : _exportToExcel,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => FormPengeluaranDialog(
              onSuccess: () => _loadLaporanKeuangan(),
            ),
          );
        },
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pengeluaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLaporanKeuangan,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. CARDS SUMMARY
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Omset',
                          amount: _formatRupiah(_totalOmset),
                          color: Colors.green,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pengeluaran',
                          amount: _formatRupiah(_totalPengeluaran),
                          color: Colors.redAccent,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: 'Laba Bersih (Margin: $profitMargin%)',
                    amount: _formatRupiah(labaBersih),
                    color: labaBersih >= 0 ? Colors.blue : Colors.orange,
                    icon: Icons.account_balance_wallet_rounded,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 20),

                  // 2. CHART WIDGET DARI PROJEK KAMU
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAB FILTER CHART (Omset, Pendapatan, Pengeluaran, Profit)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Omset', 'Pendapatan', 'Pengeluaran', 'Profit'].map((tab) {
                            final isSelected = _activeTabChart == tab;
                            return InkWell(
                              onTap: () => setState(() => _activeTabChart = tab),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEC4899) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tab,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // PAKAI WIDGET CHART PROJEK ASLI
                        ReportChartWidget(
                          items: _rawOrders,
                          expenses: _rawExpenses,
                          activeTab: _activeTabChart,
                          isLoading: _isLoading,
                          height: 180,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. BREAKDOWN METODE PEMBAYARAN
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 24),

                  // 4. RIWAYAT PENGELUARAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Pengeluaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_listPengeluaran.length} Transaksi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _listPengeluaran.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Belum ada catat pengeluaran', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _listPengeluaran.length,
                          itemBuilder: (context, index) {
                            final item = _listPengeluaran[index];
                            final amount = ((item['amount'] ?? 0) as num).toDouble();
                            final note = item['notes'] ?? item['category'] ?? 'Pengeluaran';
                            final category = item['category'] ?? 'Umum';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0.5,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                                  child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                ),
                                title: Text(note, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  '${item['created_at'].toString().split('T')[0]} • $category',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                trailing: Text(
                                  '- ${_formatRupiah(amount)}',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(fontSize: isFullWidth ? 17 : 14, fontWeight: FontWeight.bold, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final total = _cashTotal + _qrisTotal;
    final cashPct = total > 0 ? (_cashTotal / total) : 0.0;
    final qrisPct = total > 0 ? (_qrisTotal / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPaymentProgressItem(label: 'Tunai (Cash)', amount: _formatRupiah(_cashTotal), percentage: cashPct, color: Colors.green),
          const SizedBox(height: 10),
          _buildPaymentProgressItem(label: 'QRIS / Transfer', amount: _formatRupiah(_qrisTotal), percentage: qrisPct, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressItem({
    required String label,
    required String amount,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 2),
        Text(amount, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
