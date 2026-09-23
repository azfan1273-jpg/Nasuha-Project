import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/qty_input_dialog.dart'; // ⬅️ import popup qty

final supabase = Supabase.instance.client;

class DaftarLayananScreen extends StatefulWidget {
  final bool isSelectionMode;

  const DaftarLayananScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<DaftarLayananScreen> createState() => _DaftarLayananScreenState();
}

class _DaftarLayananScreenState extends State<DaftarLayananScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _pinkAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _estController = TextEditingController();

  List<Map<String, dynamic>> _servicesList = [];
  List<String> _categoriesList = [];

  String _selectedCategory = 'Kiloan';
  String _selectedUnit = 'kg';
  String _selectedEstUnit = 'Hari';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _editingServiceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _estController.dispose();
    super.dispose();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await supabase.rpc('get_services_by_store', params: {
        'p_store_id': storeId,
        'p_keyword': '',
      });

      final servicesData = List<Map<String, dynamic>>.from(response ?? []);

      final Set<String> fetchedCategories = {};
      for (var service in servicesData) {
        final cat = (service['category'] ?? '').toString().trim();
        if (cat.isNotEmpty) fetchedCategories.add(cat);
      }

      List<String> finalCategories = fetchedCategories.toList();
      if (finalCategories.isEmpty) finalCategories = ['Kiloan', 'Satuan'];

      if (mounted) {
        setState(() {
          _servicesList = servicesData;
          _categoriesList = finalCategories;
          if (finalCategories.isNotEmpty) _selectedCategory = finalCategories.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch services: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _servicesList;
    return _servicesList.where((service) {
      final name = (service['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _resetForm() {
    _editingServiceId = null;
    _nameController.clear();
    _priceController.clear();
    _estController.clear();
    _selectedCategory = _categoriesList.isNotEmpty ? _categoriesList.first : 'Kiloan';
    _selectedUnit = 'kg';
    _selectedEstUnit = 'Hari';
  }

  Future<void> _saveLayanan() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final est = int.tryParse(_estController.text.trim()) ?? 1;
    final storeId = context.read<SettingsProvider>().storeId;

    if (name.isEmpty || price <= 0 || storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Biaya Layanan wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // ✅ Gabung angka + unit jadi 1 string: "2 Hari"
      final payload = {
        'name': name,
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'price': price,
        'estimation': '$est $_selectedEstUnit',
      };

      if (_editingServiceId != null) {
        await supabase.from('services').update(payload).eq('id', _editingServiceId!);
      } else {
        await supabase.from('services').insert({
          'store_id': storeId,
          ...payload,
        });
      }

      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan berhasil disimpan!'), backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      debugPrint('Error save service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteLayanan(String id) async {
    try {
      await supabase.from('services').delete().eq('id', id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan berhasil dihapus')),
        );
      }
    } catch (e) {
      debugPrint('Error delete service: $e');
    }
  }

  // ============================================================
  // POPUP QTY (dipanggil waktu mode pilih)
  // ============================================================
  Future<void> _showQtyDialog(Map<String, dynamic> item) async {
    final qty = await showDialog<double>(
      context: context,
      builder: (_) => QtyInputDialog(
        serviceName: item['name'] ?? 'Layanan',
        price: (item['price'] as num).toDouble(),
        unit: item['unit'] ?? 'kg',
       // initialQty: 1.0,
        title: 'Jumlah / Berat',
      ),
    );

    if (qty != null && mounted) {
      Navigator.pop(context, {
        ...item,        // estimation & field lain otomatis ikut
        'quantity': qty,
      });
    }
  }

  void _showTambahKategoriDialog(BuildContext mainContext, StateSetter setPopUpState) {
    final catController = TextEditingController();

    showDialog(
      context: mainContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Contoh: Sepatu / Helm',
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
            onPressed: () {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty) {
                setState(() {
                  if (!_categoriesList.contains(newCat)) _categoriesList.add(newCat);
                });
                setPopUpState(() => _selectedCategory = newCat);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openTambahPopUp([Map<String, dynamic>? item]) {
    if (item != null) {
      _editingServiceId = item['id'].toString();
      _nameController.text = item['name'] ?? '';
      _priceController.text = (item['price'] ?? 0).toString();

      // ✅ Pecah "2 Hari" jadi angka + unit
      final estStr = item['estimation']?.toString() ?? '1 Hari';
      final parts = estStr.trim().split(' ');
      _estController.text = parts.isNotEmpty ? parts[0] : '1';
      _selectedEstUnit = parts.length > 1 ? parts[1] : 'Hari';

      _selectedCategory = item['category'] ?? 'Kiloan';
      _selectedUnit = item['unit'] ?? 'kg';
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPopUpState) {
            return Dialog(
              backgroundColor: const Color(0xFFFAF5F7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingServiceId != null ? 'Edit Layanan' : 'Tambah Layanan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textBlack),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categoriesList.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () => _showTambahKategoriDialog(context, setPopUpState),
                                icon: const Icon(Icons.add, color: Colors.white, size: 14),
                                label: const Text('Kategori',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              );
                            }
                            final cat = _categoriesList[index - 1];
                            final isSelected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setPopUpState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFBE185D) : const Color(0xFF831843),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(cat,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nama Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Cuci Komplit / Cuci Lipat',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Satuan Hitungan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack)),
                      Row(children: [
                        _buildRadioOption('kg', setPopUpState),
                        _buildRadioOption('Pcs', setPopUpState),
                        _buildRadioOption('meter', setPopUpState),
                        _buildRadioOption('pasang', setPopUpState),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Biaya Layanan (Rp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '8000',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Estimasi Pengerjaan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _estController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '2',
                                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedEstUnit,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  style: const TextStyle(fontSize: 12, color: _textBlack, fontWeight: FontWeight.w500),
                                  items: const [
                                    DropdownMenuItem(value: 'Hari', child: Text('Hari')),
                                    DropdownMenuItem(value: 'Jam', child: Text('Jam')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setPopUpState(() => _selectedEstUnit = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pinkAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _saveLayanan();
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          label: Text(
                            _editingServiceId != null ? 'UPDATE LAYANAN' : '+ SIMPAN LAYANAN BARU',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(String value, StateSetter setPopUpState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedUnit,
          activeColor: _pinkAccent,
          visualDensity: VisualDensity.compact,
          onChanged: (val) {
            if (val != null) setPopUpState(() => _selectedUnit = val);
          },
        ),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredServices;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSelectionMode ? 'PILIH LAYANAN' : 'KELOLA LAYANAN LAUNDRY',
          style: const TextStyle(color: _textBlack, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: widget.isSelectionMode
            ? []
            : [
                IconButton(
                  tooltip: 'Tambah Layanan Baru',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: _pinkAccent, size: 26),
                  onPressed: () => _openTambahPopUp(),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daftar Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textBlack)),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari layanan...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _pinkAccent))
                    : filteredList.isEmpty
                        ? const Center(child: Text('Layanan tidak ditemukan', style: TextStyle(fontSize: 12, color: Colors.grey)))
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final price = (item['price'] as num?) ?? 0;
                              final unit = item['unit'] ?? 'kg';
                              final cat = item['category'] ?? '-';
                              // ✅ Baca langsung sebagai string
                              final estStr = item['estimation']?.toString() ?? '1 Hari';

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: ListTile(
                                  dense: true,
                                  onTap: () {
                                    if (widget.isSelectionMode) {
                                      _showQtyDialog(item); // ✅ Popup qty
                                    } else {
                                      _openTambahPopUp(item);
                                    }
                                  },
                                  title: Text(
                                    item['name'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textBlack),
                                  ),
                                  subtitle: Text(
                                    '${_formatRupiah(price)} / $unit  •  $cat  •  Est: $estStr',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  trailing: widget.isSelectionMode
                                      ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                                              onPressed: () => _openTambahPopUp(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                              onPressed: () => _deleteLayanan(item['id'].toString()),
                                            ),
                                          ],
                                        ),
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
