import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'customer_detail_screen.dart';

final supabase = Supabase.instance.client;

class CariPelangganScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CariPelangganScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<CariPelangganScreen> createState() => _CariPelangganScreenState();
}

class _CariPelangganScreenState extends State<CariPelangganScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customersList = [];
  bool _isLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadCustomers(value.trim());
    });
  }

  // 🟢 FETCH DATA DARI ENGINE BACKEND (RPC)
  Future<void> _loadCustomers([String keyword = '']) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final settings = context.read<SettingsProvider>();

      // 🟢 Pastikan storeId sudah ter-fetch jika sebelumnya null
      if (settings.storeId == null || settings.storeId!.isEmpty) {
        await settings.fetchStoreId();
      }

      final storeId = settings.storeId;
      debugPrint('🔍 CHECK STORE_ID: $storeId');

      if (storeId == null || storeId.isEmpty) {
        debugPrint('⚠️ STORE ID KOSONG/NULL!');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await supabase.rpc('get_customers_by_store', params: {
        'p_store_id': storeId,
        'p_keyword': keyword,
      });

      debugPrint('FETCH SUCCESS: $response');

      final dataList = List<Map<String, dynamic>>.from(response ?? []);

      if (mounted) {
        setState(() {
          _customersList = dataList;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetch customers RPC: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _displayList {
    final List<dynamic> list = [];
    String currentHeader = '';

    final sorted = List<Map<String, dynamic>>.from(_customersList);
    sorted.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().trim().toUpperCase();
      final nameB = (b['name'] ?? '').toString().trim().toUpperCase();
      return nameA.compareTo(nameB);
    });

    for (var item in sorted) {
      final name = (item['name'] ?? '').toString().trim();
      final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';

      if (letter != currentHeader) {
        currentHeader = letter;
        list.add(currentHeader);
      }
      list.add(item);
    }
    return list;
  }

  Future<void> _showTambahPelangganDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final newCust = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tambah Pelanggan Baru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textBlack),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Nama Lengkap',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'No. WhatsApp / HP',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Alamat (Opsional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final storeId = context.read<SettingsProvider>().storeId;
              if (storeId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Error: Store ID tidak ditemukan')),
                );
                return;
              }

              try {
                // 🟢 SIMPAN VIA ENGINE RPC BACKEND
                final response = await supabase.rpc('insert_customer_by_store', params: {
                  'p_store_id': storeId,
                  'p_name': nameController.text.trim(),
                  'p_phone': phoneController.text.trim().isEmpty ? '-' : phoneController.text.trim(),
                  'p_address': addressController.text.trim().isEmpty ? '-' : addressController.text.trim(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, Map<String, dynamic>.from(response));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan pelanggan: $e')),
                  );
                }
              }
            },
            child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newCust != null && mounted) {
      _loadCustomers(_searchController.text.trim());
    }
  }

  // 🟢 FITUR EDIT PELANGGAN BARU
  Future<void> _showEditPelangganDialog(Map<String, dynamic> cust) async {
    final nameController = TextEditingController(text: cust['name'] ?? '');
    final phoneController = TextEditingController(text: (cust['phone'] == '-') ? '' : cust['phone'] ?? '');
    final addressController = TextEditingController(text: (cust['address'] == '-') ? '' : cust['address'] ?? '');

    final isUpdated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Data Pelanggan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textBlack),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: 'No. WhatsApp / HP',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Alamat',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              try {
                await supabase.from('customers').update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty ? '-' : phoneController.text.trim(),
                  'address': addressController.text.trim().isEmpty ? '-' : addressController.text.trim(),
                }).eq('id', cust['id']);

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Data pelanggan berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui data: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (isUpdated == true && mounted) {
      _loadCustomers(_searchController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _displayList;
    final accentColor = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Pelanggan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textBlack),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _goldAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: _goldAccent, size: 20),
            ),
            tooltip: 'Tambah Pelanggan Baru',
            onPressed: _showTambahPelangganDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Nama / No. HP',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _goldAccent))
                    : displayItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Pelanggan tidak ditemukan',
                              style: TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          )
                        : ListView.builder(
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              final item = displayItems[index];

                              if (item is String) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _goldAccent,
                                    ),
                                  ),
                                );
                              }

                              final cust = item as Map<String, dynamic>;
                              final custCode = cust['customer_code']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: const CircleAvatar(
                                    backgroundColor: _cardDark,
                                    child: Icon(Icons.person_rounded, color: _goldAccent),
                                  ),
                                  title: Text(
                                    cust['name'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textBlack),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, // 🟢 Rata kiri bersusun
                                    children: [
                                      const SizedBox(height: 2),
                                      // 1. BARIS NOMOR HP
                                      Text(
                                        cust['phone'] ?? '-',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      // 2. BARIS ALAMAT (DI BAWAH NO HP)
                                      Text(
                                        cust['address'] ?? '-',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 🟢 BADGE 3D KODE PELANGGAN DI SEBELAH KANAN
                                      if (custCode.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                offset: const Offset(0, 2),
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            custCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                        tooltip: 'Edit Pelanggan',
                                        onPressed: () => _showEditPelangganDialog(cust),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (widget.isSelectionMode) {
                                      Navigator.pop(context, cust);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CustomerDetailScreen(customer: cust),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
