import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

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
    final settings = context.watch<SettingsProvider>();
    final groupedData = _groupedServices;

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: settings.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kelola Layanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: settings.textColor,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: settings.accentColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(fontSize: 13, color: settings.textColor),
                  decoration: const InputDecoration(
                    hintText: 'Cari layanan...',
                    hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.black45),
                    prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchKategoriAndServices,
                  color: settings.accentColor,
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: settings.accentColor))
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
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 2),
                                      child: Text(
                                        categoryName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: settings.textColor.withOpacity(0.7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    ...items.map((item) {
                                      final price = (item['price'] as num).toDouble();
                                      final unit = item['unit'] ?? 'Kg';
                                      final estimation = item['estimation'] ?? '';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          leading: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: settings.accentColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.checkroom_rounded,
                                              color: settings.accentColor,
                                              size: 22,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['name'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: settings.textColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: settings.accentColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item['category'] ?? 'Umum',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: settings.accentColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
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
                                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                                onPressed: () => _openFormLayananScreen(item),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
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
// 2. LAYAR FORM TAMBAH / EDIT LAYANAN (MODERN FULLSCREEN UI)
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
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _estValController;
  late TextEditingController _descController;

  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedEstUnit;
  int _selectedIconIndex = 0;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _units = ['Kg', 'Pcs', 'Meter', 'Pasang', 'Paket', 'Lainnya'];
  final List<String> _estUnits = ['Hari', 'Jam', 'Menit'];

  final List<IconData> _serviceIcons = [
    Icons.checkroom_rounded,
    Icons.dry_cleaning_rounded,
    Icons.do_not_step_rounded,
    Icons.iron_rounded,
    Icons.bed_rounded,
    Icons.more_horiz_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final service = widget.existingService;
    _nameController = TextEditingController(text: service?['name'] ?? '');
    _priceController = TextEditingController(
      text: service != null ? (service['price'] as num).toInt().toString() : '',
    );
    _descController = TextEditingController(text: service?['description'] ?? '');

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
    _isActive = service?['is_active'] ?? true;

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
    _descController.dispose();
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
    final settings = context.read<SettingsProvider>();

    final payload = {
      'name': name,
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'price': price,
      'estimation': estimationFull,
      'description': _descController.text.trim(),
      'is_active': _isActive,
      if (widget.existingService == null) 'store_id': settings.storeId,
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

  Widget _buildSectionHeader(String title, IconData icon, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isEdit = widget.existingService != null;
    final primaryColor = settings.accentColor;

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: settings.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Layanan' : 'Tambah Layanan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: settings.textColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD TEXT
              Text(
                isEdit ? 'Ubah detail layanan Anda' : 'Buat layanan baru untuk pelanggan Anda',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // CONTAINER FORM BARU (SESUAI MOCKUP GAMBAR)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: INFORMASI LAYANAN ---
                    _buildSectionHeader('Informasi Layanan', Icons.info_outline_rounded, primaryColor),
                    
                    const Text('Nama Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputStyle('Cuci Kering'),
                    ),
                    const SizedBox(height: 14),

                    const Text('Kategori Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputStyle('Pilih Kategori'),
                      style: TextStyle(fontSize: 13, color: settings.textColor, fontWeight: FontWeight.w500),
                      items: widget.kategoriOptions.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    const Text('Icon Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_serviceIcons.length, (index) {
                        final isSelected = _selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIconIndex = index),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.12) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              _serviceIcons[index],
                              size: 20,
                              color: isSelected ? primaryColor : Colors.black54,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // --- SECTION 2: HARGA & SATUAN ---
                    _buildSectionHeader('Harga & Satuan', Icons.local_offer_outlined, primaryColor),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13),
                                decoration: _inputStyle('7.000').copyWith(
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: Text('Rp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Satuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: _inputStyle('Satuan'),
                                style: TextStyle(fontSize: 13, color: settings.textColor, fontWeight: FontWeight.w500),
                                items: _units.map((u) => DropdownMenuItem(value: u, child: Text('/ $u'))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedUnit = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Contoh: / Kg, / Pcs, / Set, / Item',
                              style: TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // --- SECTION 3: OPERASIONAL ---
                    _buildSectionHeader('Operasional', Icons.access_time_rounded, primaryColor),
                    
                    Wrap(
                      spacing: 16,
                      runSpacing: 14,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        // Estimasi Pekerjaan
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimasi Pekerjaan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _estValController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _inputStyle('2'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 90,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedEstUnit,
                                      decoration: _inputStyle('Unit').copyWith(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                      style: TextStyle(fontSize: 12, color: settings.textColor, fontWeight: FontWeight.w500),
                                      items: _estUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedEstUnit = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    
                        // Status Layanan
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status Layanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: _isActive,
                                    activeColor: primaryColor,
                                    onChanged: (val) => setState(() => _isActive = val),
                                  ),
                                ),
                                Text(
                                  _isActive ? 'Aktif' : 'Non-aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isActive ? primaryColor : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // --- SECTION 4: DESKRIPSI ---
                    _buildSectionHeader('Deskripsi', Icons.description_outlined, primaryColor),
                    
                    const Text('Deskripsi Layanan (opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputStyle('Cuci, kering dan lipat. Menggunakan deterjen premium...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ACTION BUTTON (BATAL & SIMPAN)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: settings.textColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSaving ? null : _saveService,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Layanan',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
