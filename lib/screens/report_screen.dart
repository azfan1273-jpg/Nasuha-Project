import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/order_detail_dialog.dart';
import 'chart_screen.dart';
import 'piutang_screen.dart';
import 'custom_date_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;

  String _filterPeriode = 'Hari Ini';
  String _activeTabChart = 'Omset';

  // VARIABEL UNTUK KUSTOM TANGGAL
  DateTimeRange? _customDateRange;

  double _totalOmset = 0;
  double _totalPendapatan = 0;
  double _totalPengeluaran = 0;
  double _totalPiutang = 0;

  List<dynamic> _rawOrders = [];
  List<dynamic> _rawExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadLaporanKeuangan();
  }

  Future<void> _loadLaporanKeuangan() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final Map<String, dynamic> params = {
        'p_store_id': storeId,
        'p_filter_periode': _filterPeriode == 'Sesuaikan Tanggal...' ? 'Custom' : _filterPeriode,
      };

      if (_filterPeriode == 'Sesuaikan Tanggal...' && _customDateRange != null) {
        params['p_start_date'] = _customDateRange!.start.toIso8601String().split('T')[0];
        params['p_end_date'] = _customDateRange!.end.toIso8601String().split('T')[0];
      }

      final response = await supabase.rpc('get_financial_report_by_store', params: params);

      if (mounted && response != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response);

        final fetchedOrders = List<dynamic>.from(data['orders'] ?? []);
        final fetchedExpenses = List<dynamic>.from(data['expenses'] ?? []);

        // 🟢 HITUNG PIUTANG HANYA DARI ORDERAN PERIODE/RENTANG AKTIF
        double piutangPeriode = 0;
        for (var o in fetchedOrders) {
          final statusBayar = (o['status_pembayaran'] ?? '').toString().trim().toLowerCase();
          if (statusBayar != 'lunas') {
            piutangPeriode += num.tryParse(o['total_price']?.toString() ?? '0')?.toDouble() ?? 0.0;
          }
        }

        setState(() {
          _totalOmset = num.tryParse(data['total_omset']?.toString() ?? '0')?.toDouble() ?? 0.0;
          _totalPendapatan = num.tryParse(data['total_pendapatan']?.toString() ?? '0')?.toDouble() ?? 0.0;
          _totalPengeluaran = num.tryParse(data['total_pengeluaran']?.toString() ?? '0')?.toDouble() ?? 0.0;
          _totalPiutang = num.tryParse(data['total_piutang']?.toString() ?? '0')?.toDouble() ?? 0.0;
        
          _rawOrders = fetchedOrders;
          _rawExpenses = fetchedExpenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load report RPC: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final DateTimeRange? picked = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => CustomDateScreen(
          initialRange: _customDateRange,
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _filterPeriode = 'Sesuaikan Tanggal...';
      });
      _loadLaporanKeuangan();
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final excel = excel_lib.Excel.createExcel();

      final excel_lib.Sheet sheet1 = excel['Ringkasan Keuangan'];
      sheet1.appendRow([excel_lib.TextCellValue('LAPORAN KEUANGAN LAUNDRY')]);
      sheet1.appendRow([excel_lib.TextCellValue('Periode: $_filterPeriode')]);
      sheet1.appendRow([]);
      sheet1.appendRow([excel_lib.TextCellValue('Kategori'), excel_lib.TextCellValue('Nominal')]);
      sheet1.appendRow([excel_lib.TextCellValue('Total Omset'), excel_lib.TextCellValue(_totalOmset.toString())]);
      sheet1.appendRow([excel_lib.TextCellValue('Total Pendapatan Riil'), excel_lib.TextCellValue(_totalPendapatan.toString())]);
      sheet1.appendRow([excel_lib.TextCellValue('Total Pengeluaran'), excel_lib.TextCellValue(_totalPengeluaran.toString())]);
      sheet1.appendRow([excel_lib.TextCellValue('Laba Bersih Riil'), excel_lib.TextCellValue((_totalPendapatan - _totalPengeluaran).toString())]);

      final excel_lib.Sheet sheet2 = excel['Detail Orderan'];
      sheet2.appendRow([
        excel_lib.TextCellValue('Tanggal'),
        excel_lib.TextCellValue('Pelanggan'),
        excel_lib.TextCellValue('Layanan'),
        excel_lib.TextCellValue('Status Bayar'),
        excel_lib.TextCellValue('Total')
      ]);

      for (var item in _rawOrders) {
        final rawDate = item['created_at'] ?? '';
        final displayDate = rawDate.toString().split('T')[0];

        sheet2.appendRow([
          excel_lib.TextCellValue(displayDate),
          excel_lib.TextCellValue(item['customer_name'] ?? '-'),
          excel_lib.TextCellValue(item['services_summary'] ?? item['service_name'] ?? '-'),
          excel_lib.TextCellValue(item['status_pembayaran'] ?? '-'),
          excel_lib.TextCellValue((item['total_price'] ?? 0).toString()),
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
    final isNeg = amount < 0;
    final str = amount.abs().toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return isNeg ? '-Rp $formatted' : 'Rp $formatted';
  }

  String _formatDateReadable(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 RUMUS LABA BERSIH BERDASARKAN PENDAPATAN RIIL (UANG DITERIMA - PENGELUARAN)
    final labaBersih = _totalPendapatan - _totalPengeluaran;
    final profitMargin = _totalPendapatan > 0
        ? ((labaBersih / _totalPendapatan) * 100).toStringAsFixed(1)
        : '0';

    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        title: Text('Laporan Keuangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: settings.textColor)),
        elevation: 0,
        backgroundColor: settings.cardDark,
        foregroundColor: settings.textColor,
        actions: [
          DropdownButton<String>(
            value: _filterPeriode,
            underline: const SizedBox(),
            dropdownColor: settings.cardDark,
            icon: Icon(Icons.arrow_drop_down, color: settings.textColor),
            items: [
              'Hari Ini',
              'Minggu Ini',
              'Bulan Ini',
              '7 Hari Terakhir',
              '30 Hari Terakhir',
              'Sesuaikan Tanggal...',
            ].map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: settings.textColor)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                if (val == 'Sesuaikan Tanggal...') {
                  _pickCustomDateRange();
                } else {
                  setState(() {
                    _filterPeriode = val;
                    _customDateRange = null;
                  });
                  _loadLaporanKeuangan();
                }
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: settings.accentColor))
          : RefreshIndicator(
              onRefresh: _loadLaporanKeuangan,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // SUBTITLE TANGGAL JIKA FILTER KUSTOM AKTIF
                  if (_filterPeriode == 'Sesuaikan Tanggal...' && _customDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: settings.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: settings.accentColor),
                            const SizedBox(width: 8),
                            Text(
                              'Periode: ${_customDateRange!.start.toString().split(' ')[0]} s/d ${_customDateRange!.end.toString().split(' ')[0]}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: settings.textColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // BARIS SUMMARY: OMSET & PENGELUARAN
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Omset',
                          amount: _formatRupiah(_totalOmset),
                          color: Colors.green,
                          icon: Icons.arrow_downward_rounded,
                          settings: settings,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Pengeluaran',
                          amount: _formatRupiah(_totalPengeluaran),
                          color: Colors.redAccent,
                          icon: Icons.arrow_upward_rounded,
                          settings: settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // BARIS SUMMARY: PIUTANG & LABA BERSIH
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PiutangScreen()),
                            ).then((_) {
                              _loadLaporanKeuangan();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: settings.cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.money_off_rounded, color: Colors.orangeAccent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Piutang', style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatRupiah(_totalPiutang),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: settings.textColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Laba Bersih ($profitMargin%)',
                          amount: _formatRupiah(labaBersih),
                          color: labaBersih >= 0 ? Colors.blue : Colors.redAccent,
                          icon: Icons.account_balance_wallet_rounded,
                          settings: settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CONTAINER GRAFIK DAN TAB
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: settings.textColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Omset', 'Pendapatan', 'Pengeluaran', 'Profit'].map((tab) {
                            final isSelected = _activeTabChart == tab;
                            return InkWell(
                              onTap: () => setState(() => _activeTabChart = tab),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? settings.accentColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tab,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : settings.textColor.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
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
                  const SizedBox(height: 24),

                  // 🟢 BAGIAN LIST TRANSAKSI / DAFTAR ORDER SESUAI TAB GRAFIK AKTIF
                  _buildDynamicTransactionList(settings),
                ],
              ),
            ),
    );
  }

  // 🟢 WIDGET MENAMPILKAN DAFTAR ORDERAN ATAU PENGELUARAN PRESISI SESUAI TAB GRAFIK
  Widget _buildDynamicTransactionList(SettingsProvider settings) {
    final bool isExpenseTab = _activeTabChart == 'Pengeluaran';
    
    List<dynamic> displayList = [];

    if (isExpenseTab) {
      // 1. TAB PENGELUARAN: Semua pengeluaran di rentang waktu
      displayList = _rawExpenses;
    } else if (_activeTabChart == 'Pendapatan' || _activeTabChart == 'Profit') {
      // 2. TAB PENDAPATAN & PROFIT: Hanya transaksi yang LUNAS
      displayList = _rawOrders.where((o) {
        final st = (o['status_pembayaran'] ?? '').toString().trim().toLowerCase();
        return st == 'lunas';
      }).toList();
    } else {
      // 3. TAB OMSET: Semua transaksi (Lunas maupun Belum Lunas)
      displayList = _rawOrders;
    }

    String headerTitle = 'Daftar Order ($_activeTabChart - $filterTitleText)';
    if (isExpenseTab) {
      headerTitle = 'Daftar Pengeluaran ($filterTitleText)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              headerTitle,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: settings.textColor),
            ),
            Text(
              '${displayList.length} Items',
              style: TextStyle(fontSize: 12, color: settings.textColor.withOpacity(0.6)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        displayList.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: settings.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: settings.textColor.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Icon(
                      isExpenseTab ? Icons.receipt_long_outlined : Icons.inbox_outlined,
                      size: 44,
                      color: settings.textColor.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isExpenseTab
                          ? 'Tidak ada pengeluaran pada periode ini'
                          : 'Tidak ada orderan pada periode ini',
                      style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final item = Map<String, dynamic>.from(displayList[index]);

                  if (isExpenseTab) {
                    final amount = num.tryParse(item['amount']?.toString() ?? '0')?.toDouble() ?? 0.0;
                    final note = item['notes'] ?? item['category'] ?? 'Pengeluaran';
                    final category = item['category'] ?? 'Umum';
                    final displayDate = _formatDateReadable(item['expense_date'] ?? item['created_at'] ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: settings.cardDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        ),
                        title: Text(
                          note,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: settings.textColor),
                        ),
                        subtitle: Text(
                          '$displayDate • $category',
                          style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.6)),
                        ),
                        trailing: Text(
                          '- ${_formatRupiah(amount)}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  // TAMPILAN ITEM ORDERAN
                  final custName = item['customer_name'] ?? item['customer'] ?? 'Pelanggan';
                  final price = num.tryParse(item['total_price']?.toString() ?? '0')?.toDouble() ?? 0.0;
                  final service = item['services_summary'] ?? item['service_name'] ?? 'Layanan Laundry';
                  final statusBayar = item['status_pembayaran'] ?? 'Belum Lunas';
                  final isLunas = statusBayar.toString().trim().toLowerCase() == 'lunas';
                  final displayDate = _formatDateReadable(item['created_at'] ?? '');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: settings.cardDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    child: ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => OrderDetailDialog(
                            order: item,
                            onOrderUpdated: _loadLaporanKeuangan,
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: (isLunas ? Colors.green : Colors.orangeAccent).withOpacity(0.15),
                        child: Icon(
                          isLunas ? Icons.check_circle_outline : Icons.pending_actions,
                          color: isLunas ? Colors.green : Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        custName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: settings.textColor),
                      ),
                      subtitle: Text(
                        '$displayDate • $service',
                        style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatRupiah(price),
                            style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isLunas ? Colors.green : Colors.orangeAccent).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusBayar,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isLunas ? Colors.green : Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  String get filterTitleText {
    if (_filterPeriode == 'Sesuaikan Tanggal...' && _customDateRange != null) {
      return 'Kustom';
    }
    return _filterPeriode;
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required SettingsProvider settings,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settings.textColor.withOpacity(0.05)),
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
                Text(title, style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(fontSize: isFullWidth ? 17 : 14, fontWeight: FontWeight.bold, color: settings.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
