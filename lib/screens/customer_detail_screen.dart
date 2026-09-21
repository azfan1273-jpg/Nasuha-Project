import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../widgets/order_detail_dialog.dart';
import 'dart:convert';

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
  Map<String, dynamic> _currentCustomerProfile = {};
  Map<String, dynamic>? _churnData; // Data untuk analisis churn

  // Stats
  int _totalTransaksi = 0;
  num _totalKontribusi = 0;
  double _persenKontribusi = 0.0;

  // Filter Active
  String _selectedTimeFilter = 'Semua';
  String _selectedMetricFilter = 'Harga';

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

  // ✅ FUNGSI BUKA WHATSAPP
  Future<void> _openWhatsAppChat() async {
    final profile = _currentCustomerProfile.isNotEmpty
        ? _currentCustomerProfile
        : widget.customer;
    final phone = (profile['phone'] ?? profile['customer_phone'] ?? '').toString();
    final name = (profile['name'] ?? profile['customer_name'] ?? 'Pelanggan').toString();

    if (phone.isEmpty || phone == '-') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor WhatsApp tidak tersedia'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final message = Uri.encodeComponent(
      'Halo $name, ada yang bisa dibantu terkait order laundry Anda?'
    );
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$message';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa membuka WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ LOGIC STATUS MURNI KONTRIBUSI + CHURN
  Map<String, dynamic> _getCustomerStatusBadge() {
    if (_allOrders.isEmpty || _persenKontribusi == 0) {
      return {'label': 'Baru', 'color': Colors.grey};
    }

    final latestOrder = _allOrders.first;
    final latestDate = DateTime.tryParse(latestOrder['created_at']?.toString() ?? '');
    final daysSinceLastOrder = latestDate != null
        ? DateTime.now().difference(latestDate).inDays
        : 0;

    // Tentukan status dasar berdasarkan kontribusi murni
    String baseStatus;
    Color baseColor;

    if (_persenKontribusi >= 10) {
      baseStatus = 'VVIP';
      baseColor = const Color(0xFFFFD700);
    } else if (_persenKontribusi >= 7) {
      baseStatus = 'VIP';
      baseColor = const Color(0xFFEC4899);
    } else if (_persenKontribusi >= 5) {
      baseStatus = 'Best';
      baseColor = Colors.cyanAccent;
    } else if (_persenKontribusi >= 1) {
      baseStatus = 'Reguler';
      baseColor = Colors.lightGreenAccent;
    } else {
      baseStatus = 'Baru';
      baseColor = Colors.grey;
    }

    // ✅ LOGIC CHURN: Hanya untuk Best ke bawah
    if (baseStatus == 'Best' || baseStatus == 'Reguler' || baseStatus == 'Baru') {
      // Cek data churn dari Supabase (penurunan >= 1%)
      if (_churnData != null) {
        final isChurn = _churnData?['is_churn'] ?? false;
        final decline = _churnData?['decline'] ?? 0.0;
        if (isChurn) {
          return {
            'label': 'Churn',
            'color': Colors.redAccent,
            'decline': decline,
          };
        }
      }
      // Fallback: jika data churn belum ada, cek berdasarkan hari
      if (daysSinceLastOrder > 40) {
        return {'label': 'Churn', 'color': Colors.redAccent};
      }
    }

    return {'label': baseStatus, 'color': baseColor};
  }

  Future<void> _fetchCustomerOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null || storeId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final custId = widget.customer['id']?.toString() ?? '';
      final custCode = widget.customer['customer_code']?.toString() ?? '';
      final custPhone = (widget.customer['phone'] ?? widget.customer['customer_phone'] ?? '').toString();
      final custName = (widget.customer['name'] ?? widget.customer['customer_name'] ?? '').toString();

      // 1. TARIK PROFIL PELANGGAN
      var profileQuery = Supabase.instance.client
          .from('customers')
          .select('*')
          .eq('store_id', storeId);

      if (custId.isNotEmpty) {
        profileQuery = profileQuery.eq('id', custId);
      } else if (custPhone.isNotEmpty && custPhone != '-') {
        profileQuery = profileQuery.eq('phone', custPhone);
      } else if (custName.isNotEmpty) {
        profileQuery = profileQuery.eq('name', custName);
      }

      final custResp = await profileQuery.maybeSingle();
      Map<String, dynamic> fetchedProfile = {};
      if (custResp != null) {
        fetchedProfile = Map<String, dynamic>.from(custResp);
      } else {
        fetchedProfile = Map<String, dynamic>.from(widget.customer);
      }

      // 2. PANGGIL FUNCTION SUPABASE
      final response = await Supabase.instance.client.rpc(
        'get_customer_orders_detail',
        params: {
          'p_store_id': storeId,
          'p_cust_id': custId.isNotEmpty ? custId : null,
          'p_cust_code': custCode.isNotEmpty ? custCode : null,
          'p_cust_phone': (custPhone.isNotEmpty && custPhone != '-') ? custPhone : null,
          'p_cust_name': custName.isNotEmpty ? custName : null,
        },
      );

      if (response == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. PROSES HASIL
      final grandTotalOmset = num.tryParse(response['grand_total_store']?.toString() ?? '0') ?? 0;
      dynamic rawData = response['order_data'];
      List<Map<String, dynamic>> fetchedOrders = [];

      if (rawData is List) {
        fetchedOrders = List<Map<String, dynamic>>.from(rawData);
      } else if (rawData is String && rawData.isNotEmpty && rawData != '[]') {
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is List) {
            fetchedOrders = List<Map<String, dynamic>>.from(decoded);
          }
        } catch (e) {
          debugPrint('❌ Error decode JSON: $e');
        }
      }

      // Hitung total
      num totalRp = 0;
      for (var order in fetchedOrders) {
        totalRp += num.tryParse(order['total_price']?.toString() ?? '0') ?? 0;
      }

      double pct = 0;
      if (grandTotalOmset > 0) {
        pct = (totalRp / grandTotalOmset) * 100;
      }

      if (mounted) {
        setState(() {
          _currentCustomerProfile = fetchedProfile;
          _allOrders = fetchedOrders;
          _totalTransaksi = fetchedOrders.length;
          _totalKontribusi = totalRp;
          _persenKontribusi = pct;
          _isLoading = false;
        });
        _applyTimeFilter(_selectedTimeFilter);
      }

      // ✅ 4. FETCH CHURN ANALYSIS (Setelah data utama berhasil)
      if (custCode.isNotEmpty) {
        try {
          final churnResponse = await Supabase.instance.client.rpc(
            'get_customer_churn_analysis',
            params: {
              'p_store_id': storeId,
              'p_cust_code': custCode,
            },
          );
          if (churnResponse != null && mounted) {
            setState(() {
              _churnData = Map<String, dynamic>.from(churnResponse);
            });
          }
        } catch (e) {
          debugPrint('Error fetch churn data: $e');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💥 ERROR FATAL: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditCustomerDialog(BuildContext context, SettingsProvider settings) async {
    final profile = _currentCustomerProfile.isNotEmpty
        ? _currentCustomerProfile
        : widget.customer;
    
    final nameController = TextEditingController(
      text: (profile['name'] ?? profile['customer_name'] ?? '').toString()
    );
    final phoneController = TextEditingController(
      text: (profile['phone'] ?? profile['customer_phone'] ?? '').toString() == '-'
          ? ''
          : (profile['phone'] ?? profile['customer_phone'] ?? '').toString()
    );
    final addressController = TextEditingController(
      text: (profile['address'] ?? profile['customer_address'] ?? '').toString() == '-'
          ? ''
          : (profile['address'] ?? profile['customer_address'] ?? '').toString()
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: settings.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Data Pelanggan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: settings.textColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(fontSize: 12, color: settings.textColor),
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan *',
                  labelStyle: TextStyle(color: settings.textColor.withOpacity(0.6)),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 12, color: settings.textColor),
                decoration: InputDecoration(
                  labelText: 'No. WA / HP *',
                  hintText: '08...',
                  labelStyle: TextStyle(color: settings.textColor.withOpacity(0.6)),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: TextStyle(fontSize: 12, color: settings.textColor),
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  labelStyle: TextStyle(color: settings.textColor.withOpacity(0.6)),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text(
                    'Hapus Pelanggan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _confirmDeleteCustomer(context, settings);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: settings.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                final custId = profile['id'];
                await Supabase.instance.client.from('customers').update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty
                      ? '-'
                      : phoneController.text.trim(),
                  'address': addressController.text.trim().isEmpty
                      ? '-'
                      : addressController.text.trim(),
                }).eq('id', custId);

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data pelanggan berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchCustomerOrders();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(BuildContext context, SettingsProvider settings) async {
    final profile = _currentCustomerProfile.isNotEmpty
        ? _currentCustomerProfile
        : widget.customer;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: settings.cardDark,
        title: const Text(
          'Hapus Pelanggan?',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${profile['name'] ?? profile['customer_name']}"? Data yang terhapus tidak bisa dikembalikan.',
          style: TextStyle(color: settings.textColor, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'HAPUS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Supabase.instance.client
            .from('customers')
            .delete()
            .eq('id', profile['id']);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pelanggan berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus pelanggan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _applyTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      final now = DateTime.now();

      if (filter == '7 Hari') {
        final sevenDaysAgo = now.subtract(const Duration(days: 6));
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.isAfter(sevenDaysAgo.subtract(const Duration(hours: 1)));
        }).toList();
      } else if (filter == '30 Hari') {
        final thirtyDaysAgo = now.subtract(const Duration(days: 29));
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.isAfter(thirtyDaysAgo.subtract(const Duration(hours: 1)));
        }).toList();
      } else if (filter == 'Bulan Ini') {
        _filteredOrders = _allOrders.where((o) {
          final dt = DateTime.tryParse(o['created_at']?.toString() ?? '');
          return dt != null && dt.month == now.month && dt.year == now.year;
        }).toList();
      } else {
        _filteredOrders = List.from(_allOrders);
      }
    });
  }

  List<DateTime> _getDateRange() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    List<DateTime> dateRange = [];

    if (_selectedTimeFilter == '7 Hari') {
      for (int i = 6; i >= 0; i--) {
        dateRange.add(todayDate.subtract(Duration(days: i)));
      }
    } else if (_selectedTimeFilter == '30 Hari') {
      for (int i = 29; i >= 0; i--) {
        dateRange.add(todayDate.subtract(Duration(days: i)));
      }
    } else if (_selectedTimeFilter == 'Bulan Ini') {
      final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= totalDaysInMonth; i++) {
        dateRange.add(DateTime(now.year, now.month, i));
      }
    } else {
      if (_allOrders.isEmpty) {
        for (int i = 6; i >= 0; i--) {
          dateRange.add(todayDate.subtract(Duration(days: i)));
        }
      } else {
        final firstOrderDateRaw = _allOrders.last['created_at']?.toString() ?? '';
        final firstDt = DateTime.tryParse(firstOrderDateRaw) ?? todayDate;
        final startDate = DateTime(firstDt.year, firstDt.month, firstDt.day);
        int totalDays = todayDate.difference(startDate).inDays + 1;
        if (totalDays < 7) totalDays = 7;
        for (int i = 0; i < totalDays; i++) {
          dateRange.add(startDate.add(Duration(days: i)));
        }
      }
    }
    return dateRange;
  }

  List<FlSpot> _generateChartData() {
    final dateRange = _getDateRange();
    Map<String, double> dayMap = {};

    for (var dt in dateRange) {
      final key = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      dayMap[key] = 0.0;
    }

    for (var o in _filteredOrders) {
      final dtRaw = DateTime.tryParse(o['created_at']?.toString() ?? '');
      if (dtRaw != null) {
        final key = "${dtRaw.year}-${dtRaw.month.toString().padLeft(2, '0')}-${dtRaw.day.toString().padLeft(2, '0')}";
        if (dayMap.containsKey(key)) {
          double val = (_selectedMetricFilter == 'Harga')
              ? (double.tryParse(o['total_price']?.toString() ?? '0') ?? 0)
              : 1.0;
          dayMap[key] = (dayMap[key] ?? 0) + val;
        }
      }
    }

    List<FlSpot> spots = [];
    int index = 1;
    for (var dt in dateRange) {
      final key = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      spots.add(FlSpot(index.toDouble(), dayMap[key] ?? 0.0));
      index++;
    }
    return spots;
  }

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
    final profile = _currentCustomerProfile.isNotEmpty
        ? _currentCustomerProfile
        : widget.customer;
    final name = (profile['name'] ?? profile['customer_name'] ?? 'Pelanggan').toString();
    final phone = (profile['phone'] ?? profile['customer_phone'] ?? '-').toString();
    final customerCode = (profile['customer_code'] ?? 'NSH-????').toString();

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
          style: TextStyle(
            color: settings.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // ✅ TOMBOL WHATSAPP
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.green, size: 26),
            tooltip: 'Chat via WhatsApp',
            onPressed: _openWhatsAppChat,
          ),
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: settings.textColor, size: 26),
            tooltip: 'Edit Data Pelanggan',
            onPressed: () => _showEditCustomerDialog(context, settings),
          ),
          const SizedBox(width: 8),
        ],
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
                                    style: TextStyle(
                                      color: settings.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          color: settings.textColor.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (customerCode != 'NSH-????')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: settings.accentColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            customerCode,
                                            style: TextStyle(
                                              color: settings.accentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final badge = _getCustomerStatusBadge();
                                final Color badgeColor = badge['color'];
                                final String badgeLabel = badge['label'];
                                final double? decline = badge['decline'];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: badgeColor.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (decline != null && decline > 0)
                                        Text(
                                          '↓${decline.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 9,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Transaksi',
                              '$_totalTransaksi',
                              settings.accentColor,
                              settings,
                            ),
                            _buildStatItem(
                              'Total Kontribusi',
                              _formatRupiah(_totalKontribusi),
                              settings.accentColor,
                              settings,
                            ),
                            _buildStatItem(
                              '% Kontribusi',
                              '${_persenKontribusi.toStringAsFixed(0)}%',
                              settings.accentColor,
                              settings,
                            ),
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
                        style: TextStyle(
                          color: settings.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                  // CONTAINER GRAFIK INTERAKTIF
                  Builder(
                    builder: (context) {
                      final chartSpots = _generateChartData();
                      final dateRange = _getDateRange();
                      final double maxY = _getMaxY();
                      double chartWidth = MediaQuery.of(context).size.width - 60;
                      if (_selectedTimeFilter == '30 Hari' ||
                          _selectedTimeFilter == 'Bulan Ini' ||
                          _selectedTimeFilter == 'Semua') {
                        chartWidth = chartSpots.length * 34.0;
                      }

                      return Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: settings.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: settings.textColor.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 45,
                              height: double.infinity,
                              child: LineChart(
                                LineChartData(
                                  maxY: maxY,
                                  minY: 0,
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 45,
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
                                            style: TextStyle(
                                              color: settings.textColor.withOpacity(0.6),
                                              fontSize: 9,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [],
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: SizedBox(
                                  width: chartWidth,
                                  height: double.infinity,
                                  child: LineChart(
                                    LineChartData(
                                      maxY: maxY,
                                      minY: 0,
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (val) => FlLine(
                                          color: settings.textColor.withOpacity(0.08),
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            getTitlesWidget: (val, meta) {
                                              final int index = val.toInt() - 1;
                                              if (index < 0 || index >= dateRange.length) {
                                                return const SizedBox.shrink();
                                              }
                                              final dt = dateRange[index];
                                              final label = "${dt.day}/${dt.month}";
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: settings.textColor.withOpacity(0.8),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipColor: (touchedSpot) => settings.accentColor,
                                          getTooltipItems: (touchedSpots) {
                                            return touchedSpots.map((spot) {
                                              final idx = spot.x.toInt() - 1;
                                              String dateStr = '';
                                              if (idx >= 0 && idx < dateRange.length) {
                                                final dt = dateRange[idx];
                                                dateStr = "${dt.day}/${dt.month}/${dt.year}";
                                              }
                                              final val = spot.y;
                                              final formattedVal = _selectedMetricFilter == 'Harga'
                                                  ? _formatRupiah(val)
                                                  : '${val.toInt()} Transaksi';
                                              return LineTooltipItem(
                                                '$dateStr\n$formattedVal',
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: chartSpots,
                                          isCurved: true,
                                          color: settings.accentColor,
                                          barWidth: 2.5,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: settings.accentColor.withOpacity(0.12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // FILTER WAKTU
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: settings.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Semua', 'Bulan Ini', '7 Hari', '30 Hari'].map((f) {
                        final isSel = _selectedTimeFilter == f;
                        return GestureDetector(
                          onTap: () => _applyTimeFilter(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
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
                                          style: TextStyle(
                                            color: settings.textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          nota,
                                          style: TextStyle(
                                            color: settings.textColor.withOpacity(0.6),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatRupiah(price),
                                      style: TextStyle(
                                        color: settings.accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
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
        Text(
          title,
          style: TextStyle(color: settings.textColor.withOpacity(0.6), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  String _formatDateReadable(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      final List<String> days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${days[dt.weekday % 7]}, ${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
