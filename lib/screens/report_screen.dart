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
  int _selectedTab = 0; // Default 0 = Laporan Omset

  double _omsetHariIni = 0.0;
  double _omsetTotal = 0.0;
  bool _isLoadingOmset = false;

  List<dynamic> _reportItems = [];
  double _totalLaporan = 0.0;
  bool _isLoadingReport = false;

  static const Color _bgSoft = Color(0xFFFAF5F7);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _fetchSummaryOmset();
    _fetchReportData();
  }

  Future<void> _fetchSummaryOmset() async {
    if (!mounted) return;
    setState(() => _isLoadingOmset = true);

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();

      final List<dynamic> totalData = await Supabase.instance.client
          .from('orders')
          .select('total_price');
          
      final List<dynamic> todayData = await Supabase.instance.client
          .from('orders')
          .select('total_price')
          .gte('created_at', startOfToday);

      double tempTotal = 0.0;
      for (var item in totalData) {
        tempTotal += (item['total_price'] as num?)?.toDouble() ?? 0.0;
      }

      double tempToday = 0.0;
      for (var item in todayData) {
        tempToday += (item['total_price'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _omsetTotal = tempTotal;
          _omsetHariIni = tempToday;
        });
      }
    } catch (e) {
      debugPrint('Error fetch summary omset: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOmset = false);
    }
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() => _isLoadingReport = true);

    try {
      final range = _dateRange;
      final start = range['start']!.toIso8601String();
      final end = range['end']!.toIso8601String();

      String tableName = 'orders';
      if (_selectedTab == 2) {
        tableName = 'expenses';
      }

      var query = Supabase.instance.client.from(tableName).select();

      if (_selectedTab == 1) {
        query = query.eq('status_pembayaran', 'Lunas');
      } else if (_selectedTab == 3) {
        query = query.eq('status_pembayaran', 'Belum Lunas');
      }

      final data = await query
          .gte('created_at', start)
          .lte('created_at', end)
          .order('created_at', ascending: false);

      double tempTotal = 0.0;
      for (var item in data) {
        tempTotal += ((item['total_price'] ?? item['amount'] ?? 0) as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _reportItems = data;
          _totalLaporan = tempTotal;
        });
      }
    } catch (e) {
      debugPrint('Error fetch report data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReport = false);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final newRange = await Navigator.push<DateTimeRange>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomDateScreen(
          initialRange: _customDateRange,
        ),
      ),
    );

    if (newRange != null) {
      setState(() {
        _customDateRange = newRange;
        _selectedPeriode = 'Custom';
      });
      _fetchReportData();
    }
  }

  void _exportToExcel() {
    if (_reportItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport!')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('No,Judul / Pelanggan,Tanggal,Jumlah (Rp)');

    for (int i = 0; i < _reportItems.length; i++) {
      final item = _reportItems[i];
      final title = (item['customer_name'] ?? item['title'] ?? 'Transaksi #${item['id']}')
          .toString()
          .replaceAll(',', ' ');
      final date = item['created_at'].toString().split('T')[0];
      final amount = (item['total_price'] ?? item['amount'] ?? 0).toString();

      buffer.writeln('${i + 1},"$title",$date,$amount');
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName = '${_getTabTitle(_selectedTab).replaceAll(' ', '_')}_$_selectedPeriode.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File $fileName berhasil di-download!')),
    );
  }

  Map<String, DateTime> get _dateRange {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

    if (_selectedPeriode == '7 Hari Terakhir') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriode == 'Bulan Ini') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedPeriode == '30 Hari') {
      startDate = now.subtract(const Duration(days: 30));
    } else if (_selectedPeriode == 'Custom' && _customDateRange != null) {
      startDate = _customDateRange!.start;
      endDate = _customDateRange!.end;
    }

    return {'start': startDate, 'end': endDate};
  }

  String _formatRupiah(double value) {
    final number = value.round().toString();
    final chars = number.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).reversed.join());
    }
    return 'Rp. ${chunks.reversed.join('.')}';
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Laporan Omset';
      case 1:
        return 'Laporan Pendapatan';
      case 2:
        return 'Laporan Pengeluaran';
      case 3:
        return 'Piutang';
      default:
        return 'Laporan Omset';
    }
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
            (_) => Container(
              width: 3,
              height: 1.5,
              color: Colors.purple.shade300,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: Scaffold(
            backgroundColor: _bgSoft,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // 1. HEADER
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: const [
                              Text(
                                'LAPORAN & STATISTIK',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: _textDark,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Nasuha Laundry.Superadmin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 2. SEPARATOR DOTTED
                    _buildDottedLine(),
                    const SizedBox(height: 8),

                    // 3. RINGKASAN OMSET
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Omset Hari ini',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _isLoadingOmset
                                    ? const SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      )
                                    : Text(
                                        _formatRupiah(_omsetHariIni),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Omset Total',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _isLoadingOmset
                                    ? const SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      )
                                    : Text(
                                        _formatRupiah(_omsetTotal),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 4. FILTER PERIODE
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriode,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: _textDark,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                              DropdownMenuItem(value: '7 Hari Terakhir', child: Text('7 Hari Terakhir')),
                              DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                              DropdownMenuItem(value: '30 Hari', child: Text('30 Hari')),
                              DropdownMenuItem(value: 'Custom', child: Text('Custom Tanggal')),
                            ],
                            onChanged: (val) async {
                              if (val == null) return;
                              if (val == 'Custom') {
                                await _pickCustomDateRange();
                              } else {
                                setState(() => _selectedPeriode = val);
                                _fetchReportData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 5. AREA EMBEDDED CHART
                    ReportChartWidget(
                      items: _reportItems,
                      isLoading: _isLoadingReport,
                      height: 200,
                    ),
                    const SizedBox(height: 14),

                    // 6. SEPARATOR DOTTED
                    _buildDottedLine(),
                    const SizedBox(height: 6),

                    // 7. DROPDOWN KATEGORI LAPORAN
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedTab,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: _textDark,
                            ),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Laporan Omset')),
                              DropdownMenuItem(value: 1, child: Text('Laporan Pendapatan')),
                              DropdownMenuItem(value: 2, child: Text('Laporan Pengeluaran')),
                              DropdownMenuItem(value: 3, child: Text('Piutang')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTab = val);
                                _fetchReportData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 8. LIST DATA TRANSAKSI
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _isLoadingReport
                              ? const Center(child: CircularProgressIndicator())
                              : _reportItems.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Tidak ada data ${_getTabTitle(_selectedTab).toLowerCase()}\nperiode $_selectedPeriode',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.black38, fontSize: 10.5),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _reportItems.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1, color: Colors.black12),
                                      itemBuilder: (context, index) {
                                        final item = _reportItems[index];
                                        final double amount =
                                            ((item['total_price'] ?? item['amount'] ?? 0) as num).toDouble();
                                        final String title = item['customer_name'] ??
                                            item['title'] ??
                                            'Transaksi #${item['id']}';
                                        final String date =
                                            item['created_at'].toString().split('T')[0];

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: _textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    date,
                                                    style: const TextStyle(
                                                        fontSize: 8.5, color: Colors.black45),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                _formatRupiah(amount),
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _selectedTab == 2
                                                      ? Colors.red.shade700
                                                      : Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 9. FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA3E635),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _exportToExcel,
                          child: const Text(
                            'EXPORT TO EXCEL',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TOTAL : ${_formatRupiah(_totalLaporan)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
