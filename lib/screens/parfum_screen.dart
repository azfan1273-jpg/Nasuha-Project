import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ParfumScreen extends StatefulWidget {
  const ParfumScreen({super.key});

  @override
  State<ParfumScreen> createState() => _ParfumScreenState();
}

class _ParfumScreenState extends State<ParfumScreen> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFFF3E0);
  static const Color _orangeAccent = Color(0xFFFF9200);
  static const Color _textBlack = Color(0xFF111827);

  List<Map<String, dynamic>> _parfums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParfums();
  }

  Future<void> _fetchParfums() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('parfums')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _parfums = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch parfums: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showFormParfumDialog([Map<String, dynamic>? item]) async {
      final nameController = TextEditingController(text: item?['name'] ?? '');
      final isEdit = item != null;
  
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            isEdit ? 'Edit Parfum' : 'Tambah Parfum Baru',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nama Parfum',
              hintText: 'Masukkan nama aroma...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _orangeAccent),
              onPressed: () async {
                final val = nameController.text.trim();
                if (val.isEmpty) return;
  
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
  
                try {
                  if (isEdit) {
                    await supabase
                        .from('parfums')
                        .update({'name': val})
                        .eq('id', item['id']);
                  } else {
                    await supabase
                        .from('parfums')
                        .insert({'name': val});
                  }
                  _fetchParfums();
                } catch (e) {
                  debugPrint('Error save parfum: $e');
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

  Future<void> _deleteParfum(int id) async {
    try {
      await supabase.from('parfums').delete().eq('id', id);
      _fetchParfums();
    } catch (e) {
      debugPrint('Error delete parfum: $e');
    }
  }

  	  @override
	  Widget build(BuildContext context) {
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
                      'Kelola Parfum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
	    
	            floatingActionButton: FloatingActionButton.extended(
	              backgroundColor: _orangeAccent,
	              icon: const Icon(Icons.add_rounded, color: Colors.white),
	              label: const Text('Tambah Parfum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
	              onPressed: () => _showFormParfumDialog(),
	            ),
	            body: _isLoading
	                ? const Center(child: CircularProgressIndicator(color: _orangeAccent))
	                : ListView.builder(
	                    padding: const EdgeInsets.all(16),
	                    itemCount: _parfums.length,
	                    itemBuilder: (context, index) {
	                      final item = _parfums[index];
	                      return Card(
	                        elevation: 0,
	                        margin: const EdgeInsets.only(bottom: 8),
	                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
	                        child: ListTile(
	                          leading: Container(
	                            padding: const EdgeInsets.all(8),
	                            decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(8)),
	                            child: const Icon(Icons.local_florist_rounded, color: _orangeAccent, size: 20),
	                          ),
	                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
	                          trailing: Row(
	                            mainAxisSize: MainAxisSize.min,
	                            children: [
	                              IconButton(
	                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
	                                onPressed: () => _showFormParfumDialog(item),
	                              ),
	                              IconButton(
	                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
	                                onPressed: () => _deleteParfum(item['id']),
	                              ),
	                            ],
	                          ),
	                        ),
	                      );
	                    },
	                  ),
    );
  }
}
