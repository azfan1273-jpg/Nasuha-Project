import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/settings_provider.dart';
import '../widgets/order_detail_dialog.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  
  // Stats
  int _totalTransaksi = 0;
  num _totalKontribusi = 0;
  double _persenKontribusi = 0.0;

  // Filter Active
  String _selectedTimeFilter = 'Semua';
  String _selectedMetricFilter = 'Harga'; // Pilihan: 'Harga' atau 'Transaksi'

  @override
  void initState() {
    super.initState();
    _fetchCustomerOrders();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _fetchCustomerOrders() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final customerPhone = widget.customer['phone'] ?? widget.customer['customer_phone'];
      final customerName = widget.customer['name'] ?? widget.customer['customer_name'];

      // 1. Fetch Transaksi Pelanggan Terisolasi store_id
      var query = Supabase.instance.client
          .from('orders')
          .select()
          .eq('store_id', storeId);

      if (customerPhone != null && customerPhone.toString().isNotEmpty) {
        query = query.eq('customer_phone', customerPhone);
      } else {
        query = query.eq('customer_name', customerName);
      }

      final response = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> fetched = List<Map<String, dynamic>>.from(response);

      // 2. Fetch Total Omset Keseluruhan Toko
      final allOrdersResp = await Supabase.instance.client
          .from('orders')
          .select('total_price')
          .eq('store_id', storeId);

      num grandTotalOmset = 0;
      for (var o in allOrdersResp) {
        grandTotalOmset += num.tryParse(o['total_price']?.toString() ?? '0') ?? 0;
      }

      // Hitung Stats Pelanggan Ini
      num totalRp = 0;
      for (var order in fetched) {
        totalRp += num.tryParse(order['total_price']?.toString() ?? '0') ?? 0;
      }

      double pct = 0;
      if (grandTotalOmset > 0) {
        pct = (totalRp / grandTotalOmset) * 100;
      }

      if (mounted) {
        setState(() {
          _allOrders = fetched;
          _totalTransaksi = fetched.length;
          _totalKontribusi = totalRp;
          _persenKontribusi = pct;
          _isLoading = false;
        });

        _applyTimeFilter(_selectedTimeFilter);
      }
    } catch (e) {
      debugPrint('Error fetch customer detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      final now = DateTime.now();

      if (filter == 'Minggu') {
        final lastWeek = now.subtract(const Duration(days: 7));
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.isAfter(lastWeek);
        }).toList();
      } else if (filter == 'Bulan') {
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.month == now.month && dt.year == now.year;
        }).toList();
      } else if (filter == 'Tahun') {
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.year == now.year;
        }).toList();
      } else {
        _filteredOrders = List.from(_allOrders);
      }
    });
  }

  // 🟢 LOGIKA GRAFIK DINAMIS BERDASARKAN DROPDOWN (HARGA VS TRANSAKSI)
  List<FlSpot> _generateChartData() {
    if (_filteredOrders.isEmpty) {
      return const [
        FlSpot(1, 0),
        FlSpot(5, 0),
        FlSpot(10, 0),
        FlSpot(15, 0),
        FlSpot(20, 0),
        FlSpot(25, 0),
        FlSpot(31, 0)
      ];
    }

    Map<int, double> dayMap = {1: 0, 5: 0, 10: 0, 15: 0, 20: 0, 25: 0, 31: 0};

    for (var o in _filteredOrders) {
      final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
      if (dt != null) {
        double val = 0;
        if (_selectedMetricFilter == 'Harga') {
          val = double.tryParse(o['total_price']?.toString() ?? '0') ?? 0;
        } else {
          val = 1; // 🟢 Tambahkan 1 transaksi jika mode 'Transaksi'
        }

        int targetDay = 1;
        if (dt.day >= 28) {
          targetDay = 31;
        } else if (dt.day >= 23) {
          targetDay = 25;
        } else if (dt.day >= 18) {
          targetDay = 20;
        } else if (dt.day >= 13) {
          targetDay = 15;
        } else if (dt.day >= 8) {
          targetDay = 10;
        } else if (dt.day >= 3) {
          targetDay = 5;
        }

        dayMap[targetDay] = (dayMap[targetDay] ?? 0) + val;
      }
    }

    return [
      FlSpot(1, dayMap[1] ?? 0),
      FlSpot(5, dayMap[5] ?? 0),
      FlSpot(10, dayMap[10] ?? 0),
      FlSpot(15, dayMap[15] ?? 0),
      FlSpot(20, dayMap[20] ?? 0),
      FlSpot(25, dayMap[25] ?? 0),
      FlSpot(31, dayMap[31] ?? 0),
    ];
  }

  // Hitung Nilai Tertinggi Sumbu Y
  double _getMaxY() {
    final spots = _generateChartData();
    double maxVal = 0;
    for (var spot in spots) {
      if (spot.y > maxVal) maxVal = spot.y;
    }
    if (_selectedMetricFilter == 'Transaksi') {
      return maxVal < 4 ? 4 : maxVal + 1;
    } else {
      return maxVal < 50000 ? 50000 : maxVal * 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final name = (widget.customer['name'] ?? widget.customer['customer_name'] ?? 'Pelanggan').toString();
    final phone = (widget.customer['phone'] ?? widget.customer['customer_phone'] ?? '-').toString();

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: settings.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Details Pelanggan',
          style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: settings.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD HEADER PELANGGAN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: settings.textColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: settings.textColor.withOpacity(0.2),
                              child: Icon(Icons.person, color: settings.textColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    phone,
                                    style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: settings.accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 12),
                                  SizedBox(width: 2),
                                  Text('VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total Transaksi', '$_totalTransaksi', settings.accentColor, settings),
                            _buildStatItem('Total Kontribusi', _formatRupiah(_totalKontribusi), settings.accentColor, settings),
                            _buildStatItem('% Kontribusi', '${_persenKontribusi.toStringAsFixed(0)}%', settings.accentColor, settings),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN PILIHAN METRIK GRAFIK
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: settings.textColor.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMetricFilter,
                        dropdownColor: settings.cardDark,
                        icon: Icon(Icons.arrow_drop_down, color: settings.textColor),
                        style: TextStyle(color: settings.textColor, fontWeight: FontWeight.bold, fontSize: 12),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMetricFilter = val);
                          }
                        },
                        items: ['Harga', 'Transaksi'].map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m, style: TextStyle(color: settings.textColor)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // CONTAINER GRAFIK
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20, right: 16, left: 4, bottom: 10),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: settings.textColor.withOpacity(0.05)),
                    ),
                    child: LineChart(
                      LineChartData(
                        maxY: _getMaxY(),
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => FlLine(color: settings.textColor.withOpacity(0.08), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 55,
                              getTitlesWidget: (val, meta) {
                                if (val < 0) return const SizedBox.shrink();
                                String label = '';
                                if (_selectedMetricFilter == 'Transaksi') {
                                  if (val % 1 == 0) label = val.toInt().toString();
                                } else {
                                  if (val >= 1000000) {
                                    label = '${(val / 1000000).toStringAsFixed(1)}M';
                                  } else if (val >= 1000) {
                                    label = '${(val / 1000).toInt()}k';
                                  } else {
                                    label = val.toInt().toString();
                                  }
                                }
                                return Text(
                                  label,
                                  style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                return Text(
                                  '${val.toInt()}',
                                  style: TextStyle(color: settings.textColor, fontSize: 11, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateChartData(),
                            isCurved: true,
                            color: settings.accentColor,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // FILTER WAKTU (SEMUA, MINGGU, BULAN, TAHUN)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Semua', 'Minggu', 'Bulan', 'Tahun'].map((f) {
                        final isSel = _selectedTimeFilter == f;
                        return GestureDetector(
                          onTap: () => _applyTimeFilter(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? settings.accentColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: isSel ? Colors.white : settings.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // LIST TRANSAKSI PELANGGAN
                  _filteredOrders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Belum ada transaksi',
                              style: TextStyle(color: settings.textColor.withOpacity(0.6)),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final item = _filteredOrders[index];
                            final num price = num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
                            final String nota = item['nota_number'] ?? 'LNDR-${(item['id'] ?? 0).toString().padLeft(5, '0')}';
                            final String rawDate = item['created_at'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => OrderDetailDialog(
                                    order: item,
                                    onOrderUpdated: _fetchCustomerOrders,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: settings.cardDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: settings.textColor.withOpacity(0.05)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDateReadable(rawDate),
                                          style: TextStyle(color: settings.textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          nota,
                                          style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatRupiah(price),
                                      style: TextStyle(color: settings.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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

  Widget _buildStatItem(String title, String value, Color valueColor, SettingsProvider settings) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDateReadable(String raw) {
    if (raw.isEmpty) return 'Senin, 01 Agustus 2026';
    try {
      final dt = DateTime.parse(raw);
      final List<String> days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${days[dt.weekday % 7]}, ${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
