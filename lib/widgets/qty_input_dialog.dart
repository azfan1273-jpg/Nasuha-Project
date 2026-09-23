import 'package:flutter/material.dart';

class QtyInputDialog extends StatefulWidget {
  final String serviceName;
  final double price;
  final String unit;
  final double initialQty;
  final String title;
  final bool startEmpty; // <-- BARU: kalau true, input mulai kosong

  const QtyInputDialog({
    super.key,
    required this.serviceName,
    required this.price,
    required this.unit,
    this.initialQty = 0.0,
    this.title = 'Jumlah / Berat',
    this.startEmpty = true, // default: kosong
  });

  @override
  State<QtyInputDialog> createState() => _QtyInputDialogState();
}

class _QtyInputDialogState extends State<QtyInputDialog> {
  late TextEditingController _qtyController;
  late double _currentQty;

  @override
  void initState() {
    super.initState();

    if (widget.startEmpty) {
      // Mode tambah: kosong
      _currentQty = 0;
      _qtyController = TextEditingController(text: '');
    } else {
      // Mode edit: pre-fill dengan qty yang ada
      _currentQty = widget.initialQty;
      _qtyController = TextEditingController(
        text: _currentQty % 1 == 0
            ? _currentQty.toInt().toString()
            : _currentQty.toString(),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _formatRupiah(num number) {
    final String str = number.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.price * _currentQty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.serviceName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatRupiah(widget.price)} / ${widget.unit}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Contoh: 1.5',
              suffixText: widget.unit,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0;
              setState(() => _currentQty = parsed);
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 12)),
              Text(
                _formatRupiah(subtotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
          onPressed: () {
            final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
            if (qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Jumlah harus lebih dari 0!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, qty);
          },
          child: const Text(
            'SIMPAN',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
