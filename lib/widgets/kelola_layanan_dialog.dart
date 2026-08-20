import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class KelolaLayananDialog extends StatefulWidget {
  const KelolaLayananDialog({super.key});

  @override
  State<KelolaLayananDialog> createState() => _KelolaLayananDialogState();
}

class _KelolaLayananDialogState extends State<KelolaLayananDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  // Fetch daftar layanan dari Supabase
  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('services')
          .select()
          .order('name', ascending: true);

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

  // Format ke Rupiah
  String _formatRupiah(double value) {
    final number = value.round().toString();
    final chars = number.split('').reversed.toList();
    final chunks = <String>[];

    for (int i = 0; i < chars.length; i += 3) {
      final end = (i + 3 < chars.length) ? i + 3 : chars.length;
      chunks.add(chars.sublist(i, end).reversed.join());
    }

    return 'Rp ${chunks.reversed.join('.')}';
  }

  // Dialog Form Tambah / Edit Layanan
  Future<void> _showFormLayananDialog([Map<String, dynamic>? existingService]) async {
    final nameController = TextEditingController(text: existingService?['name'] ?? '');
    final priceController = TextEditingController(
      text: existingService != null ? (existingService['price'] as num).toInt().toString() : '',
    );
    final estimationController = TextEditingController(
      text: existingService?['estimation'] ?? '',
    );
    String selectedUnit = existingService?['unit'] ?? 'Kg';
    final isEdit = existingService != null;

    final units = ['Kg', 'Pcs', 'Meter', 'Pasang', 'Paket', 'Lainnya'];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Layanan' : 'Tambah Layanan Baru',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textBlack),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Nama Layanan',
                      hintText: 'Contoh: Cuci Setrika',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Harga (Rp)',
                            hintText: '7000',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedUnit,
                              isExpanded: true,
                              style: const TextStyle(color: _textBlack, fontSize: 12),
                              items: units.map((u) {
                                return DropdownMenuItem(value: u, child: Text(u));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedUnit = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Input Estimasi Selesai
                  TextField(
                    controller: estimationController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Estimasi Selesai',
                      hintText: 'Contoh: 2 Hari / 5 Jam',
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
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();

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

                    final payload = {
                      'name': name,
                      'unit': selectedUnit,
                      'price': price,
                      'estimation': estimationController.text.trim(),
                    };

                    try {
                      if (isEdit) {
                        await supabase
                            .from('services')
                            .update(payload)
                            .eq('id', existingService['id']);
                      } else {
                        await supabase.from('services').insert(payload);
                      }

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      _fetchServices();
                    } catch (e) {
                      debugPrint('Error save service: $e');
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEdit ? 'UPDATE' : 'SIMPAN',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hapus Layanan
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
        _fetchServices();
      } catch (e) {
        debugPrint('Error delete service: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 385,
        height: 550,
        child: Container(
          decoration: BoxDecoration(
            color: _bgDark,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: _bgDark,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Kelola Layanan Laundry',
                style: TextStyle(color: _textBlack, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: _goldAccent,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Tambah Layanan',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showFormLayananDialog(),
            ),
            body: RefreshIndicator(
              onRefresh: _fetchServices,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.dry_cleaning_outlined, size: 56, color: Colors.black26),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum Ada Layanan Tersimpan',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tekan tombol "+ Tambah Layanan" untuk menambahkan.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.black38),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final item = _services[index];
                            final price = (item['price'] as num).toDouble();
                            final unit = item['unit'] ?? 'Kg';
                            final estimation = item['estimation'] ?? '';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black12, width: 0.5),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _cardDark,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_laundry_service_rounded, color: _goldAccent, size: 20),
                                ),
                                title: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textBlack),
                                ),
                                subtitle: Text(
                                  '${_formatRupiah(price)} / $unit' +
                                      (estimation.toString().isNotEmpty ? ' • $estimation' : ''),
                                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                      onPressed: () => _showFormLayananDialog(item),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                      onPressed: () => _deleteService(item['id'], item['name'] ?? ''),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
