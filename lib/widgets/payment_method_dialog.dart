import 'package:flutter/material.dart';

class PaymentMethodDialog extends StatefulWidget {
  const PaymentMethodDialog({super.key});

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  String _selectedMethod = 'Tunai';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Pilih Metode Pembayaran',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption('Tunai (Cash)', Icons.payments_outlined, 'Tunai'),
          _buildOption('QRIS / Transfer', Icons.qr_code_scanner, 'QRIS / Transfer'),
          _buildOption('Debit / EDC', Icons.credit_card, 'Debit'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Kembalikan null jika batal
          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context, _selectedMethod), // Kembalikan hasil pilihan
          child: const Text(
            'KONFIRMASI',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String title, IconData icon, String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedMethod,
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedMethod = val);
        }
      },
      activeColor: const Color(0xFF22C55E),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
