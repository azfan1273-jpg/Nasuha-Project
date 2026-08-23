import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ==========================================
// 1. LAYAR UTAMA: KELOLA LAYANAN LAUNDRY
// ==========================================
class KelolaLayananScreen extends StatefulWidget {
  const KelolaLayananScreen({super.key});

  @override
  State<KelolaLayananScreen> createState() => _KelolaLayananScreenState();
}

class _KelolaLayananScreenState extends State<KelolaLayananScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _services = [];
  List<String> _kategoriOptions = ['Kiloan', 'Satuan', 'Khusus', 'Lainnya'];
  
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

  Future<void> _fetchKategoriAndServices() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('services')
          .select()
          .order('name', ascending: true);

      try {
        final catData = await supabase.from('service_categories').select('name');
        final fetchedCats = catData
            .map((e) => e['name'].toString().trim())
            .where((name) => name.isNotEmpty)
            .toList();
        if (fetchedCats.isNotEmpty) {
          _kategoriOptions = fetchedCats;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _services = List<Map<String, dynamic>>.from(data);
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

  // 🔹 Grouping Services by Category
  Map<String, List<Map<String, dynamic>>> get _groupedServices {
    final query = _searchQuery.toLowerCase();
    final filtered = _services.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return name.contains(query) || cat.contains(query);
    }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in filtered) {
      final cat = (item['category'] ?? 'Lainnya').toString().trim();
      final key = cat.isEmpty ? 'Lainnya' : cat;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _openFormLayananScreen([Map<String, dynamic>? existingService]) async {
    final refresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormLayananScreen(
          existingService: existingService,
          kategoriOptions: _kategoriOptions,
        ),
      ),
    );

    if (refresh == true && mounted) {
      _fetchKategoriAndServices();
    }
  }

  Future<void> _deleteService(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Layanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus layanan "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
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
        debugPrint('Error delete service: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupedServices;

    			return Scaffold(
			       backgroundColor: _bgDark,
			       appBar: AppBar(
			         backgroundColor: Colors.white,
			         elevation: 0,
			         leading: IconButton(
			           icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
			           onPressed: () => Navigator.pop(context),
			         ),
			         title: const Text(
			           'Kelola Layanan',
			           style: TextStyle(
			             fontSize: 16,
			             fontWeight: FontWeight.bold,
			             color: Colors.black87,
			           ),
			         ),
			       ),
                  floatingActionButton: FloatingActionButton.extended(
                    backgroundColor: _goldAccent,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Tambah Layanan',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openFormLayananScreen(),
                  ),
                  body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // 1. INPUT PENCARIAN
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      decoration: InputDecoration(
                        hintText: 'Pencarian...',
                        hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. DAFTAR TERKELOMPOK BERDASARKAN KATEGORI
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchKategoriAndServices,
                        color: _goldAccent,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: _goldAccent))
                            : groupedData.isEmpty
                                ? Center(
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.dry_cleaning_outlined, size: 56, color: Colors.black26),
                                          SizedBox(height: 12),
                                          Text(
                                            'Tidak Ada Layanan Ditemukan',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    itemCount: groupedData.keys.length,
                                    itemBuilder: (context, index) {
                                      final categoryName = groupedData.keys.elementAt(index);
                                      final items = groupedData[categoryName]!;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // HEADER JUDUL KATEGORI (KILOAN, SATUAN, DLL)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 2),
                                            child: Text(
                                              categoryName.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                fontStyle: FontStyle.italic,
                                                color: _textBlack,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),

                                          // LIST CARD LAYANAN DALAM KATEGORI TERSEBUT
                                          ...items.map((item) {
                                            final price = (item['price'] as num).toDouble();
                                            final unit = item['unit'] ?? 'Kg';
                                            final estimation = item['estimation'] ?? '';

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: Colors.black.withOpacity(0.06)),
                                              ),
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                                title: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: _textBlack,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    // BADGE KATEGORI (Misal: Umum / Kiloan)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: _cardDark,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'Umum',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: _goldAccent,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    '${_formatRupiah(price)} / $unit' +
                                                        (estimation.toString().isNotEmpty ? ' • $estimation' : ''),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                                      onPressed: () => _openFormLayananScreen(item),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                      onPressed: () => _deleteService(item['id'], item['name'] ?? ''),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      );
                                    },
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

// ==========================================
// 2. LAYAR FORM TAMBAH / EDIT LAYANAN
// ==========================================
class FormLayananScreen extends StatefulWidget {
  final Map<String, dynamic>? existingService;
  final List<String> kategoriOptions;

  const FormLayananScreen({
    super.key,
    this.existingService,
    required this.kategoriOptions,
  });

  @override
  State<FormLayananScreen> createState() => _FormLayananScreenState();
}

class _FormLayananScreenState extends State<FormLayananScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _limeGreen = Color(0xFFBEF264);
  static const Color _textBlack = Color(0xFF111827);

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _estValController;

  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedEstUnit;
  bool _isSaving = false;

  final List<String> _units = ['Kg', 'Pcs', 'Meter', 'Pasang', 'Paket', 'Lainnya'];
  final List<String> _estUnits = ['Hari', 'Jam', 'Menit'];

  @override
  void initState() {
    super.initState();
    final service = widget.existingService;
    _nameController = TextEditingController(text: service?['name'] ?? '');
    _priceController = TextEditingController(
      text: service != null ? (service['price'] as num).toInt().toString() : '',
    );

    String initialEstVal = '';
    String initialEstUnit = 'Hari';
    if (service != null && service['estimation'] != null) {
      final estStr = service['estimation'].toString().trim();
      final parts = estStr.split(' ');
      if (parts.length >= 2) {
        initialEstVal = parts[0];
        initialEstUnit = parts.sublist(1).join(' ');
      } else {
        initialEstVal = estStr;
      }
    }

    _estValController = TextEditingController(text: initialEstVal);
    _selectedEstUnit = _estUnits.contains(initialEstUnit) ? initialEstUnit : 'Hari';
    _selectedUnit = service?['unit'] ?? 'Kg';

    _selectedCategory = service?['category'] ?? (widget.kategoriOptions.isNotEmpty ? widget.kategoriOptions.first : 'Kiloan');
    if (!widget.kategoriOptions.contains(_selectedCategory) && widget.kategoriOptions.isNotEmpty) {
      _selectedCategory = widget.kategoriOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _estValController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim().replaceAll('.', '').replaceAll(',', '');

    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi!')),
      );
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format harga tidak valid!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String estimationFull = _estValController.text.trim().isNotEmpty
        ? '${_estValController.text.trim()} $_selectedEstUnit'
        : '';

    final payload = {
      'name': name,
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'price': price,
      'estimation': estimationFull,
    };

    try {
      if (widget.existingService != null) {
        await supabase
            .from('services')
            .update(payload)
            .eq('id', widget.existingService!['id']);
      } else {
        await supabase.from('services').insert(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error save service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingService != null;

    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: Scaffold(
            backgroundColor: _bgDark,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26, style: BorderStyle.solid),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              isEdit ? 'FORM EDIT LAYANAN' : 'FORM TAMBAH LAYANAN',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: _textBlack,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 1. KATEGORI LAYANAN
                          const Text('Kategory Layanan', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: _textBlack)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                hint: const Text('Contoh : Kiloan', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                                style: const TextStyle(color: _textBlack, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                                items: widget.kategoriOptions.map((cat) {
                                  return DropdownMenuItem(value: cat, child: Text(cat));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. LAYANAN & SATUAN
                          const Text('Layanan', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: _textBlack)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  decoration: InputDecoration(
                                    hintText: 'Contoh : Cuci Komplit',
                                    hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUnit,
                                    style: const TextStyle(color: _textBlack, fontSize: 12, fontWeight: FontWeight.bold),
                                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedUnit = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 3. BIAYA LAYANAN
                          const Text('Biaya Layanan', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: _textBlack)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            decoration: InputDecoration(
                              hintText: 'contoh : 8.000',
                              hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 4. ESTIMASI PEKERJAAN & WAKTU
                          const Text('Estimasi Pekerjaan', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: _textBlack)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _estValController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  decoration: InputDecoration(
                                    hintText: 'contoh : 2',
                                    hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedEstUnit,
                                    style: const TextStyle(color: _textBlack, fontSize: 12, fontWeight: FontWeight.bold),
                                    items: _estUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedEstUnit = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TOMBOL SIMPAN LAYANAN
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _limeGreen,
                            foregroundColor: _textBlack,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: _isSaving ? null : _saveService,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: _textBlack, strokeWidth: 2),
                                )
                              : const Text(
                                  'SIMPAN LAYANAN',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                ),
                        ),
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
