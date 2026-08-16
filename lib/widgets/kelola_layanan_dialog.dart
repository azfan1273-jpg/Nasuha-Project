import 'package:flutter/material.dart';

class KelolaLayananDialog extends StatelessWidget {
  const KelolaLayananDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kelola Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(Icons.dry_cleaning_rounded, size: 48, color: Color(0xFFD97706)),
              const SizedBox(height: 12),
              const Text('Fitur Kelola Layanan (Siap Didesain)', style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
