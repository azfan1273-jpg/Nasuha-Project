import 'dart:async'; // Impor Timer untuk Debounce
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_detail_screen.dart';

import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

final supabase = Supabase.instance.client;

class CariPelangganScreen extends StatefulWidget {
  final bool isSelectionMode; // Flag untuk membedakan mode pilih / mode kelola

  const CariPelangganScreen({
    super.key,
    this.isSelectionMode = true, // Default = mode pilih pelanggan untuk kasir
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
  Timer? _debounceTimer; // 🔹 Tambahkan timer untuk debounce pencarian

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // 🔹 Batalkan timer saat widget di-dispose
    super.dispose();
  }

  // 🔹 Implementasi Debounce pada pencarian
  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadCustomers(value.trim());
    });
  }

 Future<void> _loadCustomers([String keyword = '']) async {
      setState(() => _isLoading = true);
      try {
        // 1. Ambil storeId dari SettingsProvider
        final storeId = context.read<SettingsProvider>().storeId;
        if (storeId == null) return;
  
        // 2. Filter query pelanggan khusus milik toko ini
        var query = supabase.from('customers').select().eq('store_id', storeId);
  
        if (keyword.isNotEmpty) {
          query = query.or('name.ilike.%$keyword%,phone.ilike.%$keyword%');
        }
  
        final data = await query;
  
        if (mounted) {
          setState(() {
            _customersList = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetch customers: $e');
        if (mounted) setState(() => _isLoading = false);
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
  
                // 1. Ambil storeId dari SettingsProvider
                final storeId = context.read<SettingsProvider>().storeId;
                if (storeId == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Error: Store ID tidak ditemukan')),
                  );
                  return;
                }
  
                // 2. Sertakan store_id agar lolos RLS Supabase
                final newCustomerData = {
                  'store_id': storeId,
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty ? '-' : phoneController.text.trim(),
                  'address': addressController.text.trim().isEmpty ? '-' : addressController.text.trim(),
                };
  
                try {
                  final response = await supabase
                      .from('customers')
                      .insert(newCustomerData)
                      .select()
                      .single();
  
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, response);
                  }
                } catch (e) {
                  debugPrint('Error inserting customer: $e');
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

  @override
  Widget build(BuildContext context) {
    final displayItems = _displayList;
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
                      onChanged: _onSearchChanged, // 🔹 Menggunakan fungsi debounce
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
                                        subtitle: Text(
                                          '${cust['phone'] ?? '-'} • ${cust['address'] ?? '-'}',
                                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                                        ),
                                        onTap: () {
                                          if (widget.isSelectionMode) {
                                            // Mode Kasir: Kembalikan data pelanggan terpilih
                                            Navigator.pop(context, cust);
                                          } else {
                                            // Mode Kelola: Buka detail pelanggan
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
