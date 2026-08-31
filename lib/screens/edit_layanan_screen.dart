import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

final supabase = Supabase.instance.client;

class EditLayananScreen extends StatefulWidget {
  final Map<String, dynamic>? serviceData;

  const EditLayananScreen({super.key, this.serviceData});

  @override
  State<EditLayananScreen> createState() => _EditLayananScreenState();
}

class _EditLayananScreenState extends State<EditLayananScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _estimationValueController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  // 🟢 Kategori default tanpa data dummy 'Sepatu & Tas'
  List<String> _kategoriOptions = ['Kiloan', 'Satuan'];
  List<Map<String, dynamic>> _servicesList = [];
  
  Map<String, dynamic>? _selectedServiceForEdit;
  String _selectedCategory = 'Kiloan';
  String _selectedUnit = 'kg';
  String _selectedTimeUnit = 'Hari';
  String _searchKeyword = '';
  
  bool _isLoading = false;
  bool _isLoadingList = true;

  @override
  void initState() {
    super.initState();
    if (widget.serviceData != null) {
      _populateFormForEdit(widget.serviceData!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchServices();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _estimationValueController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingList = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoadingList = false);
        return;
      }

      final response = await supabase.rpc('get_services_by_store', params: {
        'p_store_id': storeId,
        'p_keyword': '',
      });

      final List data = (response as List?) ?? [];
      final List<Map<String, dynamic>> loadedServices = List<Map<String, dynamic>>.from(data);

      List<String> categories = List.from(_kategoriOptions);
      for (var item in loadedServices) {
        final cat = (item['category'] ?? '').toString().trim();
        if (cat.isNotEmpty && !categories.contains(cat)) {
          categories.add(cat);
        }
      }

      if (mounted) {
        setState(() {
          _servicesList = loadedServices;
          _kategoriOptions = categories;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch services: $e');
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  // 🟢 ISI FORM SAAT ITEM KARTU DIKLIK (EDIT MODE)
    void _populateFormForEdit(Map<String, dynamic> data) {
        setState(() {
          _selectedServiceForEdit = data;
          _nameController.text = data['name'] ?? data['service_name'] ?? '';
          _priceController.text = (data['price'] ?? '').toString();
          _selectedCategory = data['category'] ?? 'Kiloan';
          _selectedUnit = data['unit'] ?? 'kg';
          _notesController.text = data['notes'] ?? '';
    
          // 🟢 BACA TEPAT NILAI ESTIMASI DARI DATABASE
          final String rawEst = (data['estimation'] ?? data['estimasi'] ?? '').toString().trim();
    
          if (rawEst.isNotEmpty && rawEst != 'null') {
            final parts = rawEst.split(' ');
            _estimationValueController.text = parts[0]; // Isikan angka aslinya dari DB
    
            if (parts.length > 1 && (parts[1] == 'Hari' || parts[1] == 'Jam')) {
              _selectedTimeUnit = parts[1];
            } else {
              _selectedTimeUnit = 'Hari';
            }
          } else {
            _estimationValueController.clear(); // Kosongkan jika memang tidak diset
            _selectedTimeUnit = 'Hari';
          }
        });
      }

  void _resetForm() {
    setState(() {
      _selectedServiceForEdit = null;
      _nameController.clear();
      _priceController.clear();
      _estimationValueController.clear();
      _notesController.clear();
      _selectedUnit = 'kg';
      _selectedTimeUnit = 'Hari';
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) throw Exception('ID Toko tidak ditemukan.');

      final serviceId = _selectedServiceForEdit != null 
          ? int.tryParse(_selectedServiceForEdit!['id'].toString()) 
          : null;

      final String estimationText = '${_estimationValueController.text.trim()} $_selectedTimeUnit';

      await supabase.rpc('upsert_service_by_store', params: {
        'p_id': serviceId,
        'p_store_id': storeId,
        'p_name': _nameController.text.trim(),
        'p_price': double.tryParse(_priceController.text.trim()) ?? 0,
        'p_unit': _selectedUnit,
        'p_category': _selectedCategory,
        'p_estimation': estimationText,
        'p_notes': _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedServiceForEdit != null ? 'Layanan berhasil diperbarui!' : 'Layanan baru ditambahkan!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _resetForm();
        _fetchServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteService(int serviceId) async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      await supabase.rpc('delete_service_by_store', params: {
        'p_id': serviceId,
        'p_store_id': storeId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan berhasil dihapus!'), backgroundColor: Colors.orange),
        );
        if (_selectedServiceForEdit?['id'] == serviceId) {
          _resetForm();
        }
        _fetchServices();
      }
    } catch (e) {
      debugPrint('Error delete service: $e');
    }
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED4C9D)),
            onPressed: () {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty && !_kategoriOptions.contains(newCat)) {
                setState(() {
                  _kategoriOptions.add(newCat);
                  _selectedCategory = newCat;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String categoryName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus kategori "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _kategoriOptions.remove(categoryName);
                if (_selectedCategory == categoryName) {
                  _selectedCategory = _kategoriOptions.isNotEmpty ? _kategoriOptions.first : '';
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    const bgPink = Color(0xFFFFE5EC);
    const purpleBar = Color(0xFF5E0B5B);
    const primaryPink = Color(0xFFED4C9D);

    final isEdit = _selectedServiceForEdit != null;

    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        backgroundColor: bgPink,
        elevation: 0,
        title: const Text(
          'KELOLA LAYANAN LAUNDRY',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 🟢 LAYOUT FIX (TANPA SINGLECHILDSCROLLVIEW)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🟢 1. SECTION DAFTAR LAYANAN (GLOBAL / TANPA FILTER KATEGORI)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Layanan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  if (isEdit)
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.add_circle_outline, size: 14, color: primaryPink),
                      label: const Text('Batal Edit', style: TextStyle(color: primaryPink, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // SEARCH INPUT
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                onChanged: (val) {
                  setState(() => _searchKeyword = val.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Cari layanan...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // LIST LAYANAN FLEXIBLE
              Expanded(
                flex: 2,
                child: _isLoadingList
                    ? const Center(child: CircularProgressIndicator(color: primaryPink))
                    : Builder(
                        builder: (context) {
                          // 🟢 Hanya menyaring berdasarkan kata kunci pencarian (Tanpa filter kategori)
                          final filtered = _servicesList.where((s) {
                            final name = (s['name'] ?? s['service_name'] ?? '').toString().toLowerCase();
                            return name.contains(_searchKeyword);
                          }).toList();

                          if (filtered.isEmpty) {
                            return Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Belum ada layanan.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              // 📍 Lokasi: ListTile di dalam ListView.separated
                              itemBuilder: (ctx, idx) {
                                final item = filtered[idx];
                                final bool isSelected = _selectedServiceForEdit?['id'] == item['id'];
                                final price = num.tryParse(item['price']?.toString() ?? '0') ?? 0;
                              
                                // 🟢 AMBIL TEKS ESTIMASI UNTUK DITAMPILKAN DI LIST
                                final estText = (item['estimation'] ?? item['estimasi'] ?? '').toString().trim();
                                final displayEst = (estText.isNotEmpty && estText != 'null') ? ' • Est: $estText' : '';
                              
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: primaryPink.withOpacity(0.1),
                                  title: Text(
                                    item['name'] ?? item['service_name'] ?? '-', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                                  ),
                                  // 🟢 SUBTITLE SEKARANG MENAMPILKAN HARGA, SATUAN, KATEGORI, & ESTIMASI
                                  subtitle: Text(
                                    '${_formatRupiah(price)} / ${item['unit'] ?? 'kg'} • ${item['category'] ?? 'Umum'}$displayEst', 
                                    style: const TextStyle(fontSize: 11, color: Colors.black54)
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                        onPressed: () => _populateFormForEdit(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        onPressed: () => _deleteService(int.parse(item['id'].toString())),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              // 🟢 2. BAR KATEGORI (BERSIH DARI DATA DUMMY)
              Container(
                decoration: BoxDecoration(
                  color: purpleBar,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showAddCategoryDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '+ Kategory',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ..._kategoriOptions.map((cat) {
                        final isSel = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          onLongPress: () => _confirmDeleteCategory(cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? primaryPink : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🟢 3. FORM INPUT / EDIT FIX
              Expanded(
                flex: 3,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text('Nama Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Cuci Komplit / Cuci Lipat',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),

                      const Text('Satuan Hitungan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Row(
                        children: ['kg', 'Pcs', 'meter', 'pasang'].map((unit) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: unit,
                                groupValue: _selectedUnit,
                                activeColor: primaryPink,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) => setState(() => _selectedUnit = val!),
                              ),
                              Text(unit, style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 8),
                            ],
                          );
                        }).toList(),
                      ),

                      const Text('Biaya Layanan (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '8000',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Biaya wajib diisi' : null,
                      ),

                      const Text('Estimasi Pengerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _estimationValueController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: '2',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTimeUnit,
                                  isExpanded: true,
                                  items: ['Hari', 'Jam'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                                  onChanged: (val) => setState(() => _selectedTimeUnit = val!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                     SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            // 🟢 Jika Mode Edit (isEdit = true) warna HIJAU, jika Tambah Baru warna PINK
                            backgroundColor: isEdit ? const Color(0xFF10B981) : primaryPink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _saveService,
                          icon: _isLoading
                              ? const SizedBox.shrink()
                              : Icon(
                                  isEdit ? Icons.check_circle_outline : Icons.add_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEdit ? 'UPDATE LAYANAN' : 'SIMPAN LAYANAN BARU',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
