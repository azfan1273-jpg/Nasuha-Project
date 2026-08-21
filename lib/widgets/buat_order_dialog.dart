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

  static const Color _activeGreen = Color(0xFFBEF264);
  static const Color _inactiveGrey = Color(0xFFD1D5DB);

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
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              backgroundColor: const Color(0xFFFAF5F7),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final List<Widget> tabWidgets = [
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: 205,
        child: GestureDetector(
          onTap: () => _onTabTapped(1),
          child: ClipPath(
            clipper: RightTabClipper(),
            child: Container(
              color: _activeTab == 1 ? _activeGreen : _inactiveGrey,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'Form Pengeluaran',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: _activeTab == 1 ? Colors.black : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: 205,
        child: GestureDetector(
          onTap: () => _onTabTapped(0),
          child: ClipPath(
            clipper: LeftTabClipper(),
            child: Container(
              color: _activeTab == 0 ? _activeGreen : _inactiveGrey,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Form Order',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: _activeTab == 0 ? Colors.black : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    ];

    return Container(
      height: 42,
      color: const Color(0xFFFAF5F7),
      child: Stack(
        children: _activeTab == 1 ? tabWidgets : tabWidgets.reversed.toList(),
      ),
    );
  }
}

class LeftTabClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 10);
    path.quadraticBezierTo(0, 0, 10, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - 25, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RightTabClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(25, 0);
    path.lineTo(size.width - 10, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 10);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
