import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

final supabase = Supabase.instance.client;

class EditLayananScreen extends StatefulWidget {
  const EditLayananScreen({super.key});

  @override
  State<EditLayananScreen> createState() => _EditLayananScreenState();
}

class _EditLayananScreenState extends State<EditLayananScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _services = [];
  List<String> _kategoriOptions = ['Satuan', 'Kiloan', 'Khusus', 'Lainnya'];

  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKategoriAndServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  Future<void> _fetchKategoriAndServices() async {
              setState(() => _isLoading = true);
              try {
                // 1. Ambil storeId dari SettingsProvider
                final storeId = context.read<SettingsProvider>().storeId;
                if (storeId == null) return;
          
                // 2. Query data layanan toko
                final data = await supabase
                    .from('services')
                    .select('*')
                    .eq('store_id', storeId) // Filter store_id
                    .order('category_order', ascending: true)
                    .order('name', ascending: true);

			      List<String> categories = [];
			      for (var item in data) {
			        final catName = (item['category'] ?? '').toString().trim();
			        if (catName.isNotEmpty && !categories.contains(catName)) {
			          categories.add(catName);
			        }
			      }

			      if (mounted) {
			        setState(() {
			          _services = List<Map<String, dynamic>>.from(data);
			          if (categories.isNotEmpty) {
			            _kategoriOptions = categories;
			          }
			          _isLoading = false;
			        });
			      }
			    } catch (e) {
			      debugPrint('Error fetch services: $e');
			      if (mounted) {
			        setState(() => _isLoading = false);
			        ScaffoldMessenger.of(context).showSnackBar(
			          SnackBar(content: Text('Gagal memuat layanan: $e')),
			        );
			      }
			    }
			  }

  Future<void> _deleteService(dynamic id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('services').delete().eq('id', id);
        _fetchKategoriAndServices();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  void _showAturUrutanKategoriDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geser Urutan Kategori',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Urutan teratas otomatis tersimpan di Supabase & berlaku di semua HP.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ReorderableListView(
                      children: _kategoriOptions.map((cat) {
                        return ListTile(
                          key: ValueKey(cat),
                          dense: true,
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                          leading: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                        );
                      }).toList(),
                      onReorder: (oldIndex, newIndex) async {
                        setBottomSheetState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _kategoriOptions.removeAt(oldIndex);
                          _kategoriOptions.insert(newIndex, item);
                        });

                        for (int i = 0; i < _kategoriOptions.length; i++) {
                          final catName = _kategoriOptions[i];
                          await supabase
                              .from('services')
                              .update({'category_order': i + 1})
                              .eq('category', catName);
                        }

                        _fetchKategoriAndServices();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F7),
      appBar: AppBar(
        title: const Text('Kelola Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Urutkan Kategori',
            icon: const Icon(Icons.low_priority_rounded, color: Color(0xFFEC4899)),
            onPressed: _showAturUrutanKategoriDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : RefreshIndicator(
              onRefresh: _fetchKategoriAndServices,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Cari layanan...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: _kategoriOptions.map((cat) {
                          final itemsInCat = _filteredServices
                              .where((s) => (s['category'] ?? '').toString().trim().toLowerCase() == cat.toLowerCase())
                              .toList();

                          if (itemsInCat.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  cat.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              ...itemsInCat.map((item) {
                                final price = (item['price'] as num?) ?? 0;
                                final unit = item['unit'] ?? 'Kg';
                                final estimation = item['estimation'] ?? '';
                                final isActive = item['is_active'] ?? true;

                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isActive ? 1.0 : 0.5,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFFCE7F3) : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.checkroom_rounded,
                                          color: isActive ? const Color(0xFFEC4899) : Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['name'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.pink.shade50 : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'Aktif' : 'Non-aktif',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? const Color(0xFFEC4899) : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${_formatRupiah(price)} / $unit' +
                                            (estimation.toString().isNotEmpty ? ' • $estimation' : ''),
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteService(item['id'], item['name'] ?? ''),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
