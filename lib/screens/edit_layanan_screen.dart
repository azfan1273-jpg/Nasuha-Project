import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  List<String> _kategoriOptions = ['Kiloan', 'Satuan', 'Sepatu & Tas'];
  Map<String, int> _categoryCounts = {};
  int _totalServicesCount = 0;
  
  String _selectedCategory = 'Kiloan';
  String _selectedUnit = 'kg';
  String _selectedTimeUnit = 'Hari';
  bool _isLoading = false;
  bool _isLoadingChart = true;

  // Warna chart konsisten untuk setiap kategori
  final List<Color> _chartColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFA78BFA), // Purple
    const Color(0xFFFBBF24), // Orange/Yellow
    const Color(0xFFFDE047), // Light Yellow
    const Color(0xFF10B981), // Emerald
    const Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceData != null) {
      final data = widget.serviceData!;
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? '').toString();
      _selectedCategory = data['category'] ?? 'Kiloan';
      _selectedUnit = data['unit'] ?? 'kg';
      _notesController.text = data['notes'] ?? '';

      final estRaw = (data['estimation'] ?? '5 Hari').toString().split(' ');
      if (estRaw.isNotEmpty) {
        _estimationValueController.text = estRaw[0];
      }
      if (estRaw.length > 1) {
        _selectedTimeUnit = estRaw[1];
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategoryChartData();
    });
  }

  // Mengambil data real-time kategori dari Supabase
  Future<void> _fetchCategoryChartData() async {
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoadingChart = false); // 🟢 Matikan loading
        return;
      }

      final response = await supabase
          .from('services')
          .select('category')
          .eq('store_id', storeId);

      final List data = response as List;
      Map<String, int> counts = {};
      int total = 0;

      for (var item in data) {
        final cat = (item['category'] ?? 'Lainnya').toString();
        counts[cat] = (counts[cat] ?? 0) + 1;
        total++;
      }

      // Update daftar kategori jika ada kategori baru di DB
      List<String> updatedKategori = List.from(_kategoriOptions);
      counts.keys.forEach((cat) {
        if (!updatedKategori.contains(cat)) {
          updatedKategori.add(cat);
        }
      });

      if (mounted) {
        setState(() {
          _categoryCounts = counts;
          _totalServicesCount = total;
          _kategoriOptions = updatedKategori;
          if (_kategoriOptions.isNotEmpty && !_kategoriOptions.contains(_selectedCategory)) {
            _selectedCategory = _kategoriOptions.first;
          }
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChart = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _estimationValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        throw Exception('ID Toko tidak ditemukan. Silakan atur pengaturan toko.');
      }

      final estimationStr =
          '${_estimationValueController.text.trim()} $_selectedTimeUnit';

      final payload = {
        'store_id': storeId,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'estimation': estimationStr,
        'notes': _notesController.text.trim(),
        'is_active': true,
      };

      if (widget.serviceData == null) {
        await supabase.from('services').insert(payload);
      } else {
        await supabase
            .from('services')
            .update(payload)
            .eq('id', widget.serviceData!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil disimpan!'),
            backgroundColor: Color(0xFFED4C9D),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru', style: TextStyle(fontSize: 14)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED4C9D),
            ),
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

  List<PieChartSectionData> _generateChartSections() {
    if (_totalServicesCount == 0) {
      // Data dummy fallback jika belum ada layanan di Supabase
      return [
        PieChartSectionData(color: const Color(0xFF3B82F6), value: 21.4, title: 'Kiloan\n21.4%', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), titlePositionPercentageOffset: 1.55),
        PieChartSectionData(color: const Color(0xFFA78BFA), value: 57.1, title: 'Satuan\n57.1%', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), titlePositionPercentageOffset: 1.55),
        PieChartSectionData(color: const Color(0xFFFBBF24), value: 14.3, title: 'Sepatu dan tas\n14.3%', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), titlePositionPercentageOffset: 1.55),
        PieChartSectionData(color: const Color(0xFFFDE047), value: 7.1, title: 'Jacket\n7.1%', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), titlePositionPercentageOffset: 1.55),
      ];
    }

    int index = 0;
    return _categoryCounts.entries.map((entry) {
      final percentage = (entry.value / _totalServicesCount) * 100;
      final color = _chartColors[index % _chartColors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titlePositionPercentageOffset: 1.55,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgPink = Color(0xFFFFE5EC);
    const purpleBar = Color(0xFF5E0B5B);
    const primaryPink = Color(0xFFED4C9D);

    final isEdit = widget.serviceData != null;

    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        backgroundColor: bgPink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              Center(
                child: Text(
                  isEdit ? 'FORM EDIT LAYANAN' : 'FORM TAMBAH LAYANAN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Donut Chart Real Dynamic dari Supabase
              SizedBox(
                height: 200,
                child: _isLoadingChart
                    ? const Center(child: CircularProgressIndicator(color: primaryPink))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 42,
                          startDegreeOffset: -90,
                          sections: _generateChartSections(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Bar Options Kategori (Purple Bar)
              Container(
                color: purpleBar,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Tombol + Tambah Hijau
                      GestureDetector(
                        onTap: _showAddCategoryDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '+ Tambah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // List Kategori Dinamis
                      ..._kategoriOptions.map((cat) {
                                      final isSel = cat == _selectedCategory;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedCategory = cat),
                                        onLongPress: () => _confirmDeleteCategory(cat), // <-- TAMBAHKAN BARIS INI (Long Press untuk Hapus)
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSel ? Colors.white.withOpacity(0.25) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            cat,
                                            style: TextStyle(
                                              color: isSel ? Colors.white : Colors.white70,
                                              fontSize: 13,
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
              const SizedBox(height: 16),

              // Form Utama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layanan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Contoh : Cuci Komplit',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama layanan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Satuan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: ['kg', 'Pcs', 'meter'].map((unit) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: unit,
                                groupValue: _selectedUnit,
                                activeColor: primaryPink,
                                fillColor: WidgetStateProperty.all(_selectedUnit == unit ? primaryPink : Colors.white),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedUnit = val);
                                  }
                                },
                              ),
                              Text(
                                unit,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Biaya Layanan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'contoh : Rp. 8.000',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Biaya wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Estimasi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _estimationValueController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontFamily: 'Arial'),
                              decoration: InputDecoration(
                              	hintText: '5', // <-- Menggunakan hintText '5'
                           	    hintStyle: TextStyle(
                           	      color: Colors.grey.shade400,
                           	      fontFamily: 'Arial'
                           	    ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTimeUnit,
                                  isExpanded: true,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  items: ['Hari', 'Jam'].map((t) {
                                    return DropdownMenuItem(
                                        value: t, child: Text(t));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedTimeUnit = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const Expanded(flex: 1, child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Catatan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Opsional',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveService,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  isEdit
                                      ? 'PERBARUI LAYANAN'
                                      : 'SIMPAN LAYANAN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Arial',
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
