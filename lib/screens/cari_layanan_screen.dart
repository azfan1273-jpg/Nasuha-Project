import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CariLayananScreen extends StatefulWidget {
  const CariLayananScreen({super.key});

  @override
  State<CariLayananScreen> createState() => _CariLayananScreenState();
}

class _CariLayananScreenState extends State<CariLayananScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _servicesList = [];
  List<String> _categoriesList = ['Semua'];
  
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch data layanan dari Supabase
      final servicesData = await supabase
          .from('services')
          .select('*')
          .order('name', ascending: true);

      // 2. Fetch kategori dari tabel service_categories (jika ada) atau ekstrak dari data layanan
      List<String> categories = ['Semua'];
      try {
        final catData = await supabase
            .from('service_categories')
            .select('name')
            .order('name', ascending: true);
        for (var item in catData) {
          final catName = item['name'].toString().trim();
          if (catName.isNotEmpty && !categories.contains(catName)) {
            categories.add(catName);
          }
        }
      } catch (_) {
        // Fallback jika tabel service_categories belum dibuat
        for (var item in servicesData) {
          final catName = (item['category'] ?? '').toString().trim();
          if (catName.isNotEmpty && !categories.contains(catName)) {
            categories.add(catName);
          }
        }
      }

      if (mounted) {
        setState(() {
          _servicesList = List<Map<String, dynamic>>.from(servicesData);
          _categoriesList = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch services & categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _servicesList.where((service) {
      final name = (service['name'] ?? '').toString().toLowerCase();
      final category = (service['category'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = name.contains(query);
      final matchesCategory = _selectedCategory == 'Semua' ||
          category == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<double?> _showQtyDialog(Map<String, dynamic> service) async {
    final qtyController = TextEditingController(text: '1');
    final unit = service['unit'] ?? 'Kg';

    return showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          service['name'] ?? 'Jumlah Order',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textBlack),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Harga: ${_formatRupiah((service['price'] as num?) ?? 0)} / $unit',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Jumlah / Qty ($unit)',
                hintText: 'Contoh: 2.5 atau 3',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final qty = double.tryParse(qtyController.text.replaceAll(',', '.'));
              if (qty != null && qty > 0) {
                Navigator.pop(dialogCtx, qty);
              }
            },
            child: const Text('TAMBAHKAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredServices;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Layanan',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. INPUT PENCARIAN
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Cari layanan...',
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
              const SizedBox(height: 12),

              // 2. HORIZONTAL FILTER CHIPS
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoriesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categoriesList[index];
                    final bool isSelected = _selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? _goldAccent : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _goldAccent : Colors.black12,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _goldAccent.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : _textBlack,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 3. DAFTAR LAYANAN
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _goldAccent))
                    : filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'Layanan tidak ditemukan',
                              style: TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final price = (item['price'] as num?) ?? 0;
                              final unit = item['unit'] ?? 'Kg';

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _cardDark,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.local_laundry_service_rounded,
                                      color: _goldAccent,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item['name'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textBlack),
                                  ),
                                  subtitle: Text(
                                    '${_formatRupiah(price)} / $unit',
                                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _goldAccent.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: _goldAccent,
                                      size: 18,
                                    ),
                                  ),
                                  onTap: () async {
                                    final qty = await _showQtyDialog(item);
                                    if (qty != null && qty > 0 && mounted) {
                                      Navigator.pop(context, {...item, 'quantity': qty});
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
