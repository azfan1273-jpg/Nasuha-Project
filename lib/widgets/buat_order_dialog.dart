// backup 01:18 minggu 16/8/26

import 'package:flutter/material.dart';
import '../main.dart';
import '../helpers/database_helper.dart';
import 'form_order_dialog.dart';
import 'form_pengeluaran_dialog.dart';

class BuatOrderDialog extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const BuatOrderDialog({super.key, required this.onOrderCreated});

  @override
  State<BuatOrderDialog> createState() => _BuatOrderDialogState();
}

class _BuatOrderDialogState extends State<BuatOrderDialog> {
  static const Color _bgDark = Color(0xFFFAF5F7);
  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  final List<Map<String, String>> _topCustomers = [];

  void _showFormOrder(BuildContext context, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => type == "OUT"

			// Jika dipencet dari tombol Pengeluaran (OUT)
      		? FormPengeluaranDialog(
                onSuccess: () {
         			 Navigator.pop(dialogContext); // Tutup Form Order
          			 Navigator.pop(context); // Tutup Menu Transaksi
         			 widget.onOrderCreated(); // Refresh Callback Dashboard
        		   },
      			 )

			// Jika dipencet dari tombol Buat Orders (IN)
      		: FormOrderDialog(
                  type: type,
                  onOrderSuccess: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                    widget.onOrderCreated();
                  },
                ),
    );
  }
  
    
    @override
    Widget build(BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _bgDark,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Menu Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _textBlack, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        title: 'Buat Orders',
                        subtitle: 'Cucian Masuk',
                        icon: Icons.add_shopping_cart_rounded,
                        colors: [const Color(0xFF34D399), const Color(0xFF059669)],
                        shadowColor: Colors.green.shade600,
                        onTap: () => _showFormOrder(context, 'IN'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        title: 'Pengeluaran',
                        subtitle: 'Biaya Toko',
                        icon: Icons.account_balance_wallet_rounded,
                        colors: [const Color(0xFFFB923C), const Color(0xFFE11D48)],
                        shadowColor: Colors.deepOrange.shade600,
                        onTap: () => _showFormOrder(context, 'OUT'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Top Customers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: _topCustomers.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada data pelanggan',
                            style: TextStyle(fontSize: 11, color: Colors.black38),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _topCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _topCustomers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _goldAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _textBlack,
                                            ),
                                          ),
                                          Text(
                                            customer['orders'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      customer['status'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: _goldAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  
    Widget _buildActionButton({
      required String title,
      required String subtitle,
      required IconData icon,
      required List<Color> colors,
      required Color shadowColor,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 95,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
