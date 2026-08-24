import 'dart:math';
import 'package:flutter/material.dart';

class ReportChartWidget extends StatelessWidget {
  final List<dynamic> items; // Orders
  final List<dynamic> expenses; // Expenses
  final String activeTab; // 'Omset', 'Pendapatan', 'Pengeluaran', 'Profit'
  final bool isLoading;
  final double height;

  const ReportChartWidget({
    super.key,
    required this.items,
    this.expenses = const [],
    required this.activeTab,
    this.isLoading = false,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFFEC4899)),
      );
    }

    // 🔴 KHUSUS TAB PENGELUARAN: TAMPILKAN DONUT CHART BY KATEGORI
    if (activeTab == 'Pengeluaran') {
      final Map<String, double> categoryMap = {};
      double totalExpense = 0.0;

      for (var item in expenses) {
        final String category = item['category']?.toString() ?? 'Lain-lain';
        final double amount = ((item['amount'] ?? 0) as num).toDouble();
        categoryMap[category] = (categoryMap[category] ?? 0.0) + amount;
        totalExpense += amount;
      }

      if (categoryMap.isEmpty || totalExpense == 0) {
        return Container(
          height: height,
          alignment: Alignment.center,
          child: const Text('Belum ada data pengeluaran', style: TextStyle(fontSize: 11, color: Colors.black38)),
        );
      }

      final List<Color> palette = [
        const Color(0xFFEF4444),
        const Color(0xFFF97316),
        const Color(0xFFFBBF24),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
        const Color(0xFF06B6D4),
      ];

      final List<Map<String, dynamic>> pieData = [];
      int colorIdx = 0;
      categoryMap.forEach((cat, amt) {
        pieData.add({
          'category': cat,
          'amount': amt,
          'percentage': (amt / totalExpense) * 100,
          'color': palette[colorIdx % palette.length],
        });
        colorIdx++;
      });

      return Container(
        height: height,
        color: Colors.white,
        child: Row(
          children: [
            // Donut Chart
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: DonutChartPainter(data: pieData, totalExpense: totalExpense),
              ),
            ),
            const SizedBox(width: 16),
            // Legend Kategori
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: pieData.length,
                itemBuilder: (context, idx) {
                  final item = pieData[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: item['color'], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['category'],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(item['percentage'] as double).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // 🔵 TAB OMSET, PENDAPATAN, PROFIT: TAMPILKAN LINE CHART
    final Map<String, Map<String, double>> dailyMap = {};

    for (var item in items) {
      final String rawDate = item['created_at']?.toString() ?? '';
      if (rawDate.isEmpty) continue;
      final String dateKey = _formatShortDate(rawDate);
      final double amount = ((item['total_price'] ?? 0) as num).toDouble();
      final bool isLunas = item['status_pembayaran'] == 'Lunas';

      dailyMap.putIfAbsent(dateKey, () => {'omset': 0.0, 'pendapatan': 0.0, 'pengeluaran': 0.0});
      dailyMap[dateKey]!['omset'] = (dailyMap[dateKey]!['omset'] ?? 0.0) + amount;
      if (isLunas) {
        dailyMap[dateKey]!['pendapatan'] = (dailyMap[dateKey]!['pendapatan'] ?? 0.0) + amount;
      }
    }

    for (var item in expenses) {
      final String rawDate = item['created_at']?.toString() ?? '';
      if (rawDate.isEmpty) continue;
      final String dateKey = _formatShortDate(rawDate);
      final double amount = ((item['amount'] ?? 0) as num).toDouble();

      dailyMap.putIfAbsent(dateKey, () => {'omset': 0.0, 'pendapatan': 0.0, 'pengeluaran': 0.0});
      dailyMap[dateKey]!['pengeluaran'] = (dailyMap[dateKey]!['pengeluaran'] ?? 0.0) + amount;
    }

    final List<String> sortedDates = dailyMap.keys.toList()..sort();
    final List<Map<String, dynamic>> chartData = sortedDates.map((dateKey) {
      final double o = dailyMap[dateKey]!['omset'] ?? 0.0;
      final double p = dailyMap[dateKey]!['pendapatan'] ?? 0.0;
      final double e = dailyMap[dateKey]!['pengeluaran'] ?? 0.0;
      return {
        'date': dateKey,
        'omset': o,
        'pendapatan': p,
        'pengeluaran': e,
        'profit': p - e,
      };
    }).toList();

    if (chartData.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const Text('Belum ada transaksi pada periode ini', style: TextStyle(fontSize: 11, color: Colors.black38)),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white,
      child: CustomPaint(
        painter: DynamicLineChartPainter(data: chartData, activeTab: activeTab),
      ),
    );
  }

  String _formatShortDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoString.split('T')[0];
    }
  }
}

// 🍩 DONUT CHART PAINTER
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double totalExpense;

  DonutChartPainter({required this.data, required this.totalExpense});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 22.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;

    for (var item in data) {
      final sweepAngle = ((item['amount'] as double) / totalExpense) * 2 * pi;
      paint.color = item['color'];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 📈 LINE CHART PAINTER (ADAPTIF VARIABEL ACTIVE TAB)
class DynamicLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String activeTab;

  DynamicLineChartPainter({required this.data, required this.activeTab});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 45.0;
    const double paddingBottom = 25.0;
    const double paddingTop = 12.0;
    const double paddingRight = 12.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    String dataKey = 'omset';
    Color lineThemeColor = const Color(0xFFA855F7); // Purple untuk Omset

    if (activeTab == 'Pendapatan') {
      dataKey = 'pendapatan';
      lineThemeColor = const Color(0xFF0284C7); // Blue
    } else if (activeTab == 'Profit') {
      dataKey = 'profit';
      lineThemeColor = const Color(0xFF16A34A); // Green
    }

    double maxVal = 100000.0;
    for (var item in data) {
      final double v = (item[dataKey] as num).toDouble();
      if (v > maxVal) maxVal = v;
    }

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const int steps = 3;

    for (int i = 0; i <= steps; i++) {
      final double y = paddingTop + (chartHeight / steps) * i;
      final double currentVal = maxVal - ((maxVal / steps) * i);

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: _formatCompactRupiah(currentVal),
        style: TextStyle(color: Colors.grey.shade700, fontSize: 9.5, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - (textPainter.height / 2)));
    }

    final double stepX = data.length == 1 ? chartWidth / 2 : chartWidth / (data.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final double x = data.length == 1 ? paddingLeft + (chartWidth / 2) : paddingLeft + (i * stepX);
      final double val = (data[i][dataKey] as num).toDouble();
      final double y = paddingTop + chartHeight - ((val / maxVal) * chartHeight);

      points.add(Offset(x, y));

      textPainter.text = TextSpan(
        text: data[i]['date'].toString(),
        style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - paddingBottom + 6));
    }

    // Shading Fill
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, paddingTop + chartHeight);
      for (var pt in points) {
        path.lineTo(pt.dx, pt.dy);
      }
      path.lineTo(points.last.dx, paddingTop + chartHeight);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = lineThemeColor.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );

      // Line & Dots
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineThemeColor
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (var pt in points) {
        canvas.drawCircle(pt, 4.0, Paint()..color = lineThemeColor);
        canvas.drawCircle(pt, 4.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  String _formatCompactRupiah(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)} jt';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)} rb';
    return val.toInt().toString();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
