import 'package:flutter/material.dart';
import 'form_order_dialog.dart';
import 'form_pengeluaran_dialog.dart';

class BuatOrderDialog extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const BuatOrderDialog({super.key, required this.onOrderCreated});

  @override
  State<BuatOrderDialog> createState() => _BuatOrderDialogState();
}

class _BuatOrderDialogState extends State<BuatOrderDialog> {
  late PageController _pageController;
  int _activeTab = 0; // 0 = Form Order, 1 = Form Pengeluaran

  	static const Color _primaryPink = Color(0xFFE91E63);
    static const Color _trackBg = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _activeTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF5F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF5F7),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Buat Transaksi',
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildCustomTabBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _activeTab = index;
                    });
                  },
                  children: [
                    FormOrderDialog(
                      type: 'IN',
                      onOrderSuccess: widget.onOrderCreated,
                    ),
                    FormPengeluaranDialog(
                      onSuccess: widget.onOrderCreated,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

 Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 42,
      decoration: BoxDecoration(
        color: _trackBg,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          _buildTabItem(index: 0, title: 'Form Order'),
          _buildTabItem(index: 1, title: 'Form Pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String title}) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? _primaryPink : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _primaryPink.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
