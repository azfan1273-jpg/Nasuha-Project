import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CariPelangganScreen extends StatefulWidget {
  const CariPelangganScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers([String keyword = '']) async {
    setState(() => _isLoading = true);
    try {
      var query = supabase.from('customers').select();
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

  // 🔹 Getter untuk Mengurutkan (A-Z) dan Menyisipkan Header Abjad
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
        list.add(currentHeader); // Masukkan penanda huruf (String)
      }
      list.add(item); // Masukkan data pelanggan (Map)
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
              final newCustomerData = {
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
                  Navigator.pop(dialogContext, newCustomerData);
                }
              }
            },
            child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newCust != null && mounted) {
      Navigator.pop(context, newCust);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _displayList;

    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: Scaffold(
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
                      onChanged: (val) => _loadCustomers(val.trim()),
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

                                    // 🔹 TAMPILKAN HEADER ABJAD (A, B, C...)
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

                                    // 🔹 TAMPILKAN CARD PELANGGAN
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
                                        onTap: () => Navigator.pop(context, cust),
                                      ),
                                    );
                                  },
                                ),
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
