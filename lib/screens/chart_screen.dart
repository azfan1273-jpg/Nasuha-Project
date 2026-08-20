import 'package:flutter/material.dart';

class ReportChartWidget extends StatelessWidget {
  final List<dynamic> items;
  final bool isLoading;
  final double height;

  const ReportChartWidget({
    super.key,
    required this.items,
    this.isLoading = false,
    this.height = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.purple))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: items.length * 35.0 < 365 ? 365 : items.length * 35.0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CustomPaint(
                    painter: ChartPainter(items: items),
                  ),
                ),
              ),
      ),
    );
  }
}

// 🔹 Painter Line Chart Neon & Grid Background
class ChartPainter extends CustomPainter {
  final List<dynamic> items;

  ChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. GARIS GRID KOTAK-KOTAK
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    const int horizontalLines = 4;
    for (int i = 0; i <= horizontalLines; i++) {
      final double y = (size.height / horizontalLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (items.isNotEmpty) {
      final double stepX = size.width / (items.length < 2 ? 1 : items.length);
      for (int i = 0; i < items.length; i++) {
        final double x = (i * stepX) + (stepX / 2);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    if (items.isEmpty) return;

    // 2. LOGIKA PLOT POIN DATA
    final double stepX = size.width / (items.length < 2 ? 1 : items.length);

    double maxVal = 1.0;
    for (var item in items) {
      final double val = (item['total_price'] ?? item['amount'] ?? 0).toDouble();
      if (val > maxVal) maxVal = val;
    }

    final List<Offset> points = [];
    for (int i = 0; i < items.length; i++) {
      final double val = (items[i]['total_price'] ?? items[i]['amount'] ?? 0).toDouble();
      final double x = (i * stepX) + (stepX / 2);
      final double y = size.height - ((val / maxVal) * (size.height - 35)) - 15;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final linePath = Path();
      final fillPath = Path();

      linePath.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Gradien Bayangan
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFA3E635).withOpacity(0.35),
            const Color(0xFFA3E635).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      // Garis Neon
      final linePaint = Paint()
        ..color = const Color(0xFFA3E635)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);

      // Dot Poin
      final dotFillPaint = Paint()..color = Colors.white;
      final dotBorderPaint = Paint()
        ..color = const Color(0xFF7E22CE)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      for (var pt in points) {
        canvas.drawCircle(pt, 3.5, dotFillPaint);
        canvas.drawCircle(pt, 3.5, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}
