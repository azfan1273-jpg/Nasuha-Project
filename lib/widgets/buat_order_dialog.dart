import 'package:flutter/material.dart';
import '../main.dart';

class BuatOrderDialog extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const BuatOrderDialog({super.key, required this.onOrderCreated});

  @override
  State<BuatOrderDialog> createState() => _BuatOrderDialogState();
}

class _BuatOrderDialogState extends State<BuatOrderDialog> {
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalController = TextEditingController();
  bool _isLoading = false;

  Future<void> _simpanOrder() async {
    if (_customerController.text.isEmpty || _totalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Pelanggan & Total Wajib Diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double totalNum = double.tryParse(_totalController.text) ?? 0.0;

      // Insert langsung ke Supabase Cloud
      await supabase.from('orders').insert({
        'customer_name': _customerController.text,
        'phone': _phoneController.text.isEmpty ? '-' : _phoneController.text,
        'total': totalNum,
        'status': 'Antrian',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onOrderCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Berhasil Dibuat ke Supabase!')),
        );
      }
    } catch (e) {
      debugPrint('Error simpan order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Buat Order Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customerController,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'No. HP / WhatsApp',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'Total Biaya (Rp)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _simpanOrder,
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('SIMPAN ORDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
