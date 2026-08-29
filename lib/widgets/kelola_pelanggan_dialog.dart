import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

final supabase = Supabase.instance.client;

class KelolaPelangganDialog extends StatefulWidget {
  const KelolaPelangganDialog({super.key});

  @override
  State<KelolaPelangganDialog> createState() => _KelolaPelangganDialogState();
}

class _KelolaPelangganDialogState extends State<KelolaPelangganDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch / Cari Pelanggan dari Supabase
  Future<void> _fetchCustomers([String keyword = '']) async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<SettingsProvider>().storeId;
      if (storeId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 🟢 FIX 1: Wajib tambahkan filter store_id pada kueri select
      var query = supabase.from('customers').select().eq('store_id', storeId);
      
      if (keyword.trim().isNotEmpty) {
        final kw = keyword.trim();
        query = query.or('name.ilike.%$kw%,phone.ilike.%$kw%');
      }

      final data = await query.order('name', ascending: true);

      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch customers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pelanggan: $e')),
        );
      }
    }
  }

  // Dialog Form Tambah / Edit Pelanggan
  Future<void> _showFormPelangganDialog([Map<String, dynamic>? existingCustomer]) async {
    final nameController = TextEditingController(text: existingCustomer?['name'] ?? '');
    final phoneController = TextEditingController(text: existingCustomer?['phone'] ?? '');
    final addressController = TextEditingController(text: existingCustomer?['address'] ?? '');
    final isEdit = existingCustomer != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textBlack),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Contoh: Ahmad Subagjo',
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
                  labelText: 'No. WhatsApp / HP',
                  hintText: '08123456789',
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
                  labelText: 'Alamat (Opsional)',
                  hintText: 'Jl. Mawar No. 12',
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
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama Pelanggan wajib diisi!')),
                  );
                  return;
                }
                final settings = context.read<SettingsProvider>();
                final payload = {
                  'name': name,
                  'phone': phone.isEmpty ? '-' : phone,
                  'address': address.isEmpty ? '-' : address,
                  if (!isEdit) 'store_id': settings.storeId,
                };

                try {
                  if (isEdit) {
                    await supabase
                        .from('customers')
                        .update(payload)
                        .eq('id', existingCustomer['id']);
                  } else {
                    await supabase.from('customers').insert(payload);
                  }

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _fetchCustomers(_searchController.text);
                } catch (e) {
                  debugPrint('Error save customer: $e');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan pelanggan: $e')),
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
  }

  // Hapus Pelanggan
  Future<void> _deleteCustomer(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pelanggan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus pelanggan "$name"?'),
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
        await supabase.from('customers').delete().eq('id', id);
        _fetchCustomers(_searchController.text);
      } catch (e) {
        debugPrint('Error delete customer: $e');
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
                'Kelola Pelanggan',
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
              icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Tambah Pelanggan',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showFormPelangganDialog(),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _fetchCustomers(val),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama / No. HP...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _fetchCustomers(_searchController.text),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _customers.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.people_outline_rounded, size: 56, color: Colors.black26),
                                      SizedBox(height: 12),
                                      Text(
                                        'Belum Ada Pelanggan',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Tekan tombol "+ Tambah Pelanggan" di bawah\nuntuk menambahkan pelanggan baru.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 11, color: Colors.black38),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                                itemCount: _customers.length,
                                itemBuilder: (context, index) {
                                  final item = _customers[index];
                                  final phone = item['phone'] ?? '-';
                                  final address = item['address'] ?? '-';

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.black12, width: 0.5),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      leading: const CircleAvatar(
                                        backgroundColor: _cardDark,
                                        child: Icon(Icons.person_rounded, color: _goldAccent, size: 20),
                                      ),
                                      title: Text(
                                        item['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textBlack),
                                      ),
                                      subtitle: Text(
                                        '$phone • $address',
                                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                            onPressed: () => _showFormPelangganDialog(item),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                            onPressed: () => _deleteCustomer(item['id'], item['name'] ?? ''),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
