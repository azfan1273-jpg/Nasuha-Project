import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_date_screen.dart';
import 'chart_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriode = 'Hari Ini';
  DateTimeRange? _customDateRange;
  String _activeTab = 'Omset'; // Default tab

  double _totalOmset = 0.0;
  double _totalPendapatan = 0.0;
  double _totalPengeluaran = 0.0;
  bool _isLoading = false;

  List<dynamic> _ordersData = [];
  List<dynamic> _expensesData = [];

  static const Color _primaryBlue = Color(0xFFEC4899);
  static const Color _bgSoft = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final range = _dateRange;
      final start = range['start']!.toIso8601String();
      final end = range['end']!.toIso8601String();

      // Fetch Orders (Pendapatan & Omset)
      final orders = await Supabase.instance.client
          .from('orders')
          .select()
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: false);

      // Fetch Expenses (Pengeluaran)
      final expenses = await Supabase.instance.client
          .from('expenses')
          .select()
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: false);

      double sumOmset = 0.0;
      double sumPendapatan = 0.0;

      for (var item in orders) {
        final double price = ((item['total_price'] ?? 0) as num).toDouble();
        sumOmset += price;
        if (item['status_pembayaran'] == 'Lunas') {
          sumPendapatan += price;
        }
      }

      double sumPengeluaran = 0.0;
      for (var item in expenses) {
        sumPengeluaran += ((item['amount'] ?? 0) as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _ordersData = orders;
          _expensesData = expenses;
          _totalOmset = sumOmset;
          _totalPendapatan = sumPendapatan;
          _totalPengeluaran = sumPengeluaran;
        });
      }
    } catch (e) {
      debugPrint('Error fetch financial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, DateTime> get _dateRange {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

   

    // 1. DUA HARI / TANGGAL PILIHAN CUSTOM
    if (_selectedPeriode == 'Custom Range' && _customDateRange != null) {
      final start = DateTime(
        _customDateRange!.start.year,
        _customDateRange!.start.month,
        _customDateRange!.start.day,
        0, 0, 0,
      );
      final end = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23, 59, 59,
      );
      return {'start': start, 'end': end};
    }
  
    // 2. HARI INI (DEFAULT)
    if (_selectedPeriode == 'Hari Ini') {
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return {'start': startOfDay, 'end': endOfDay};
    } 
  
    // 3. 7 HARI TERAKHIR
    if (_selectedPeriode == '7 Hari Terakhir') {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return {'start': start, 'end': end};
    }
  
    // 4. BULAN INI
    if (_selectedPeriode.contains('Bulan Ini')) {
      final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return {'start': startOfMonth, 'end': endOfDay};
    }
  
    // FALLBACK DEFAULT (HARI INI)
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return {'start': startOfDay, 'end': endOfDay};
  }

  Future<void> _pickCustomDateRange() async {
    final newRange = await Navigator.push<DateTimeRange>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomDateScreen(initialRange: _customDateRange),
      ),
    );

    if (newRange != null) {
      setState(() {
        _customDateRange = newRange;
        _selectedPeriode = 'Custom Range';
      });
      _fetchFinancialData();
    }
  }

  void _exportToExcel() {
    if (_ordersData.isEmpty && _expensesData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport!')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Kategori,Judul / Pelanggan,Tanggal,Jumlah (Rp)');

    for (var item in _ordersData) {
      final title = (item['customer_name'] ?? 'Transaksi #${item['id']}').toString().replaceAll(',', ' ');
      final date = item['created_at'].toString().split('T')[0];
      final amount = (item['total_price'] ?? 0).toString();
      buffer.writeln('Pendapatan,"$title",$date,$amount');
    }

    for (var item in _expensesData) {
      final title = (item['title'] ?? 'Pengeluaran #${item['id']}').toString().replaceAll(',', ' ');
      final date = item['created_at'].toString().split('T')[0];
      final amount = (item['amount'] ?? 0).toString();
      buffer.writeln('Pengeluaran,"$title",$date,$amount');
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName = 'Laporan_Keuangan_${_selectedPeriode.replaceAll(' ', '_')}.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File $fileName berhasil di-download!')),
    );
  }

  String _formatRupiah(double value) {
    final number = value.round().toString();
    final chars = number.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).reversed.join());
    }
    return 'Rp ${chunks.reversed.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    final double profit = _totalPendapatan - _totalPengeluaran;

    return Scaffold(
      backgroundColor: _bgSoft,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER GRADIENT BIRU DENGAN LOGO & JUDUL
            Container(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'LAPORAN KEUANGAN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Laundry Kasir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                    onPressed: _pickCustomDateRange,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. BARIS CONTROL: DROPDOWN RINGKAS & BUTTONS EXPORT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dropdown dengan Ukuran Pas Sesuai Konten
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriode,
                            isExpanded: false, // Tidak bikin lebar penuh
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryBlue, size: 18),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _textDark),
                            items: const [
                              DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                              DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                              DropdownMenuItem(value: '7 Hari Terakhir', child: Text('7 Hari Terakhir')),
                              DropdownMenuItem(value: 'Custom Range', child: Text('Custom Range')),
                            ],
                            onChanged: (val) async {
                              if (val == null) return;
                              if (val == 'Custom Range') {
                                await _pickCustomDateRange();
                              } else {
                                setState(() => _selectedPeriode = val);
                                _fetchFinancialData();
                              }
                            },
                          ),
                        ),
                      ),
                      
                      Row(
                        children: [
                          // Button Export Excel
                          InkWell(
                            onTap: _exportToExcel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.table_chart_rounded, color: Colors.white, size: 13),
                                  SizedBox(width: 4),
                                  Text('Export Excel', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Button Export PDF
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export PDF siap diintegrasikan!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 13),
                                  SizedBox(width: 4),
                                  Text('Export PDF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. CARDS RINGKASAN (4 CARD: OMSET, PENDAPATAN, PENGELUARAN, PROFIT)
                  Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Omset',
                        value: _formatRupiah(_totalOmset),
                        badgeText: '▲ Total Sales',
                        badgeColor: Colors.purple,
                        icon: Icons.storefront_outlined,
                        iconColor: Colors.purple,
                        bgColor: const Color(0xFFFAF5FF),
                        isSelected: _activeTab == 'Omset',
                        onTap: () => setState(() => _activeTab = 'Omset'),
                      ),
                      const SizedBox(width: 6),
                      _buildSummaryCard(
                        title: 'Pendapatan',
                        value: _formatRupiah(_totalPendapatan),
                        badgeText: '▲ Lunas',
                        badgeColor: Colors.blue,
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.blue,
                        bgColor: const Color(0xFFEFF6FF),
                        isSelected: _activeTab == 'Pendapatan',
                        onTap: () => setState(() => _activeTab = 'Pendapatan'),
                      ),
                      const SizedBox(width: 6),
                      _buildSummaryCard(
                        title: 'Pengeluaran',
                        value: _formatRupiah(_totalPengeluaran),
                        badgeText: '▼ Expenses',
                        badgeColor: Colors.red,
                        icon: Icons.vertical_align_bottom_rounded,
                        iconColor: Colors.red,
                        bgColor: const Color(0xFFFEF2F2),
                        isSelected: _activeTab == 'Pengeluaran',
                        onTap: () => setState(() => _activeTab = 'Pengeluaran'),
                      ),
                      const SizedBox(width: 6),
                      _buildSummaryCard(
                        title: 'Profit',
                        value: _formatRupiah(profit),
                        badgeText: '▲ Net Profit',
                        badgeColor: Colors.green,
                        icon: Icons.show_chart_rounded,
                        iconColor: Colors.green,
                        bgColor: const Color(0xFFF0FDF4),
                        isSelected: _activeTab == 'Profit',
                        onTap: () => setState(() => _activeTab = 'Profit'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. CARD GRAFIK KEUANGAN
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grafik Keuangan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                            ),
                            Row(
                              children: [
                                _buildLegendItem('Pendapatan', Colors.blue),
                                const SizedBox(width: 8),
                                _buildLegendItem('Pengeluaran', Colors.red),
                                const SizedBox(width: 8),
                                _buildLegendItem('Profit', Colors.green),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ReportChartWidget(
                          items: _ordersData,
                          expenses: _expensesData,
                          activeTab: _activeTab, // <-- passing activeTab ke widget grafik
                          isLoading: _isLoading,
                          height: 180,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. DETAIL LAPORAN PER TANGGAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.calendar_today_rounded, size: 18, color: _primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              'Detail Laporan per Tanggal',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  _buildDailyDetailCard(
                                    date: '24 Agt 2026',
                                    pendapatan: _totalPendapatan,
                                    pengeluaran: _totalPengeluaran,
                                    profit: profit,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET CARD RINGKASAN ITEM (4 TOP CARDS)
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? iconColor : Colors.black.withOpacity(0.06),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: iconColor.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(fontSize: 9.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
              ),
              const SizedBox(height: 3),
              Text(badgeText, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: badgeColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  Widget _buildDailyDetailCard({
    required String date,
    required double pendapatan,
    required double pengeluaran,
    required double profit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        title: Text(
          date,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.arrow_upward_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Pendapatan (Order Laundry)',
                  value: _formatRupiah(pendapatan),
                  valueColor: const Color(0xFF16A34A),
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  icon: Icons.arrow_downward_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  title: 'Pengeluaran (Pembelian Detergen)',
                  value: _formatRupiah(pengeluaran),
                  valueColor: const Color(0xFFDC2626),
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  icon: Icons.show_chart_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Profit Hari Ini',
                  value: _formatRupiah(profit),
                  valueColor: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textDark),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
