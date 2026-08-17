import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/settings_provider.dart';
import '../widgets/buat_order_dialog.dart';
import '../widgets/report_dialog.dart';
import '../widgets/setting_dialog.dart';
import '../widgets/toko_header_widget.dart';
import 'package:remixicon/remixicon.dart';

class LayarStatistik extends StatefulWidget {
  const LayarStatistik({Key? key}) : super(key: key);

  @override
  State<LayarStatistik> createState() => _LayarStatistikState();
}

class _LayarStatistikState extends State<LayarStatistik> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
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

    try {
      final List<dynamic> data = await supabase
          .from('orders')
          .select('*')
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

      final status = (order['status'] ?? 'Baru').toString().toUpperCase();

      if (!matchesSearch) return false;

      if (_selectedFilter == 'ANTRIAN') {
        return status == 'ANTRIAN' || status == 'BARU';
      } else if (_selectedFilter == 'PROSES') {
        return status == 'PROSES';
      } else if (_selectedFilter == 'SELESAI') {
        return status == 'SELESAI';
      } else if (_selectedFilter == 'BATAL') {
        return status == 'BATAL' || status == 'CANCEL';
      }
      return true;
    }).toList();
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

  String _formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '17/09/2026';
    try {
      final dt = DateTime.parse(rawDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '17/09/2026';
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
        width: 385,
        color: _bgDark,
        child: Column(
          children: [
            const SizedBox(height: 10),
            TokoHeaderWidget(
              namaToko: settings.namaToko,
              userRole: settings.userRole,
              emailToko: settings.emailToko,
              isLoading: _isLoading,
              onRefresh: _fetchOrders,
            ),
            const SizedBox(height: 10),

            _buildBannerPromo(),
            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftSidebar(),

                    const SizedBox(width: 6),
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: _goldAccent.withOpacity(0.5),
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
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _textBlack,
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
                                    border: Border.all(color: _cardDark),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(fontSize: 9),
                                    onChanged: (val) {
                                      setState(() => _searchQuery = val);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Pencarian list bar...',
                                      hintStyle: TextStyle(fontSize: 8, color: Colors.black38),
                                      prefixIcon: Icon(Icons.search, size: 14, color: Colors.grey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.only(bottom: 12),
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
                                color: _cardDark.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardDark),
                              ),
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(color: _goldAccent, strokeWidth: 2),
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
                                          color: _goldAccent,
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

            _buildTransactionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPromo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: _goldAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Promo Cuci Komplit Diskon 10%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _goldAccent,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Berlaku sampai akhir bulan.',
                      style: TextStyle(fontSize: 8, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _goldAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return SizedBox(
      width: 46,
      child: Column(
        children: [
          _buildFilterButton('ANTRIAN', Remix.time_line),
          const SizedBox(height: 8),
          _buildFilterButton('PROSES', Remix.loader_2_line),
          const SizedBox(height: 8),
          _buildFilterButton('SELESAI', Remix.shield_check_line),
          const SizedBox(height: 8),
          _buildFilterButton('BATAL', Remix.close_circle_line),
          
          const Spacer(),

          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const ReportDialog(),
              );
            },
            child: _buildSideMenuItem(
              icon: Icons.assignment_outlined,
            ),
          ),
          
          const SizedBox(height: 8),
          
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const SettingDialog(),
              );
            },
            child: _buildSideMenuItem(icon: Icons.settings_outlined),
          ),
        ],
      ),
    );  
  }

  Widget _buildFilterButton(String filterKey, IconData icon) {
    final bool isSelected = _selectedFilter == filterKey;
  
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFFCE7F3),
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
          color: isSelected ? Colors.white : const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildSideMenuItem({required IconData icon}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF111827)),
    );
  }

  Widget _buildOrderCardBar(Map<String, dynamic> item) {
    final name = item['customer_name'] ?? 'Pelanggan';
    final total = (item['total_price'] as num?)?.toDouble() ?? 0.0;
    final dateStr = _formatTanggal(item['created_at']);
    final service = item['service_name'] ?? '1 order';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFC7E8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Est selesai - $dateStr',
                  style: const TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service.contains('(') ? service.split('(').first : service,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _textBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatRupiah(total),
                style: const TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: _textBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _goldAccent,
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
