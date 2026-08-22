import 'package:flutter/material.dart';

class DaftarOrderByStatusScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> orders;

  const DaftarOrderByStatusScreen({
    super.key,
    required this.title,
    required this.orders,
  });

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFCE7F3),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Tidak ada orderan pada kategori ini.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      order['customer'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(order['services'] ?? '-'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatRupiah(order['total'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          order['status'] ?? '-',
                          style: const TextStyle(fontSize: 10, color: Colors.pink),
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
