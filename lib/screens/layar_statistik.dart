import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import '../widgets/order_detail_dialog.dart';
import '../screens/report_screen.dart';
import 'setting_screen.dart';


class LayarStatistik extends StatefulWidget {
  const LayarStatistik({Key? key}) : super(key: key);

  @override
  State<LayarStatistik> createState() => _LayarStatistikState();
}

class _LayarStatistikState extends State<LayarStatistik> {
  static const Color _textBlack = Color(0xFF111827);

  final List<Map<String, dynamic>> _allOrders = [];
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'ANTRIAN';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final settings = context.read<SettingsProvider>();

    try {
      final List<dynamic> data = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allOrders.clear();
          _allOrders.addAll(List<Map<String, dynamic>>.from(data));
        });
      }
    } catch (e) {
      debugPrint('Error fetch orders di LayarStatistik: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _allOrders.where((order) {
      final name = (order['customer_name'] ?? '').toString().toLowerCase();
      final phone = (order['customer_phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(query) || phone.contains(query);

      if (!matchesSearch) return false;

      final status = (order['status'] ?? 'Baru').toString().toUpperCase();

      switch (_selectedFilter) {
        case 'ANTRIAN':
          return status == 'ANTRIAN' || status == 'BARU';
        case 'PROSES':
          return status == 'PROSES';
        case 'SELESAI':
          return status == 'SELESAI';
        case 'BATAL':
          return status == 'BATAL' || status == 'CANCEL';
        default:
          return true;
      }
    }).toList();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  String _getJudulListBar() {
    switch (_selectedFilter) {
      case 'ANTRIAN':
        return 'Antrian';
      case 'PROSES':
        return 'Proses';
      case 'SELESAI':
        return 'Selesai';
      case 'BATAL':
        return 'Transaksi Batal';
      default:
        return 'Antrian';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Center(
      child: Container(
        width: double.infinity,
        color: settings.bgDark,
        child: Column(
          children: [
            
            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftSidebar(settings),

                    const SizedBox(width: 6),
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: settings.accentColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  _getJudulListBar(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: settings.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 5,
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: settings.cardDark),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(fontSize: 9),
                                    onChanged: (val) {
                                      setState(() => _searchQuery = val);
                                    },
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Pencarian list bar...',
                                      hintStyle: TextStyle(fontSize: 8, color: Colors.black38),
                                      prefixIcon: Icon(Icons.search, size: 14, color: Colors.grey),
                                      prefixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 28),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: settings.cardDark.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: settings.cardDark),
                              ),
                              child: _isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(color: settings.accentColor, strokeWidth: 2),
                                    )
                                  : _filteredOrders.isEmpty
                                      ? const Center(
                                          child: Text(
                                            '(Belum Ada Data)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black38,
                                            ),
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: _fetchOrders,
                                          color: settings.accentColor,
                                          child: ListView.builder(
                                            itemCount: _filteredOrders.length,
                                            itemBuilder: (context, index) {
                                              final item = _filteredOrders[index];
                                              return _buildOrderCardBar(item);
                                            },
                                          ),
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildTransactionButton(settings),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(SettingsProvider settings) {
    return SizedBox(
      width: 46,
      child: Column(
        children: [
          _buildFilterButton('ANTRIAN', Remix.time_line, settings),
          const SizedBox(height: 8),
          _buildFilterButton('PROSES', Remix.loader_2_line, settings),
          const SizedBox(height: 8),
          _buildFilterButton('SELESAI', Remix.shield_check_line, settings),
          const SizedBox(height: 8),
          _buildFilterButton('BATAL', Remix.close_circle_line, settings),
          
          const Spacer(),

          _buildSideMenuItem(
            icon: Icons.assignment_outlined,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          _buildSideMenuItem(
            icon: Icons.settings_outlined,
            settings: settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );  
  }

  Widget _buildFilterButton(String filterKey, IconData icon, SettingsProvider settings) {
    final bool isSelected = _selectedFilter == filterKey;
  
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : settings.cardDark,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : settings.textColor,
        ),
      ),
    );
  }

  Widget _buildSideMenuItem({required IconData icon, required VoidCallback onTap, required SettingsProvider settings}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: settings.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: settings.textColor),
      ),
    );
  }

  Widget _buildOrderCardBar(Map<String, dynamic> item) {
    final String customerName = (item['customer_name'] ?? item['nama_pelanggan'] ?? 'Pelanggan').toString();
    final num totalPrice = num.tryParse(item['total_price']?.toString() ?? '0') ?? 0;

    int serviceCount = 0;
    if (item['order_items'] is List && (item['order_items'] as List).isNotEmpty) {
      serviceCount = (item['order_items'] as List).length;
    } else if (item['service_name'] != null && item['service_name'].toString().isNotEmpty) {
      serviceCount = item['service_name'].toString().split(',').length;
    }
    final String serviceText = '$serviceCount layanan';

    String estText = 'Est: -';
    final dynamic rawEst = item['estimated_at'] ?? item['estimasi_selesai'] ?? item['estimasi'];
    
    if (rawEst != null && rawEst.toString().isNotEmpty && rawEst.toString() != 'null') {
      try {
        final targetDate = DateTime.parse(rawEst.toString());
        estText = 'Est: ${_formatTanggal(targetDate.toIso8601String())}';
      } catch (_) {}
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => OrderDetailDialog(
            order: item,
            onOrderUpdated: _fetchOrders,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF3B0),
              Color(0xFFFFC7E8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionButton(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: settings.accentColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BuatOrderDialog(
                onOrderCreated: _fetchOrders,
              ),
            );
          },
          icon: const Icon(Icons.list_alt_rounded, size: 20),
          label: const Text(
            'MENU TRANSAKSI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
