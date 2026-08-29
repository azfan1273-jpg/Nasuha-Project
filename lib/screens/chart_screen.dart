import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
    final settings = context.watch<SettingsProvider>();

    if (isLoading) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: settings.accentColor),
      );
    }

    // 🟢 1. TAB PENGELUARAN: DONUT CHART (DIPOSISIKAN DI TENGAH TANPA TEKS TOTAL)
    if (activeTab == 'Pengeluaran') {
      final Map<String, double> categoryMap = {};
      double totalExpense = 0.0;

      for (var item in expenses) {
        final String category = item['category']?.toString() ?? 'Lain-lain';
        final double amount = num.tryParse(item['amount']?.toString() ?? '0')?.toDouble() ?? 0.0;
        categoryMap[category] = (categoryMap[category] ?? 0.0) + amount;
        totalExpense += amount;
      }

      if (categoryMap.isEmpty || totalExpense == 0) {
        return Container(
          height: height,
          alignment: Alignment.center,
          color: settings.cardDark,
          child: Text('Belum ada data pengeluaran', style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.5))),
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
        color: settings.cardDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🟢 DONUT CHART MURNI (TANPA TEKS DI TENGAH)
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                size: const Size(130, 130),
                painter: DonutChartPainter(data: pieData, totalExpense: totalExpense),
              ),
            ),
            const SizedBox(width: 20),
            // LEGEND KATEGORI PENGELUARAN
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: settings.textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(item['percentage'] as double).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: settings.textColor.withOpacity(0.6)),
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

    // 🟢 2. TAB OMSET, PENDAPATAN, PROFIT: LINE CHART
    final Map<String, Map<String, double>> dailyMap = {};

    for (var item in items) {
      final String rawDate = item['created_at']?.toString() ?? '';
      if (rawDate.isEmpty) continue;
      final String dateKey = _formatShortDate(rawDate);
      final double amount = num.tryParse(item['total_price']?.toString() ?? '0')?.toDouble() ?? 0.0;
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
      final double amount = num.tryParse(item['amount']?.toString() ?? '0')?.toDouble() ?? 0.0;

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
        'profit': o - e,
      };
    }).toList();

    if (chartData.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        color: settings.cardDark,
        child: Text('Belum ada transaksi pada periode ini', style: TextStyle(fontSize: 11, color: settings.textColor.withOpacity(0.5))),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      color: settings.cardDark,
      child: CustomPaint(
        painter: DynamicLineChartPainter(
          data: chartData,
          activeTab: activeTab,
          textColor: settings.textColor,
          accentColor: settings.accentColor,
        ),
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

// 🟢 DONUT CHART PAINTER
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double totalExpense;

  DonutChartPainter({required this.data, required this.totalExpense});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 20.0;

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

// 🟢 LINE CHART PAINTER
class DynamicLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String activeTab;
  final Color textColor;
  final Color accentColor;

  DynamicLineChartPainter({
    required this.data,
    required this.activeTab,
    required this.textColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 50.0;
    const double paddingBottom = 25.0;
    const double paddingTop = 12.0;
    const double paddingRight = 12.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    String dataKey = 'omset';
    Color lineThemeColor = accentColor;

    if (activeTab == 'Pendapatan') {
      dataKey = 'pendapatan';
      lineThemeColor = const Color(0xFF0284C7);
    } else if (activeTab == 'Profit') {
      dataKey = 'profit';
      lineThemeColor = const Color(0xFF16A34A);
    }

    double maxVal = 10000.0;
    double minVal = 0.0;

    for (var item in data) {
      final double v = (item[dataKey] as num).toDouble();
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }

    if (activeTab == 'Profit' && minVal < 0) {
      double absMax = max(maxVal.abs(), minVal.abs());
      maxVal = absMax;
      minVal = -absMax;
    }

    double range = maxVal - minVal;
    if (range == 0) range = 10000.0;

    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.08)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const int steps = 4;

    if (activeTab == 'Profit' && minVal < 0) {
      final double yZero = paddingTop + chartHeight - (((0 - minVal) / range) * chartHeight);
      final zeroLinePaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.5)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(paddingLeft, yZero),
        Offset(size.width - paddingRight, yZero),
        zeroLinePaint,
      );
    }

    for (int i = 0; i <= steps; i++) {
      final double y = paddingTop + (chartHeight / steps) * i;
      final double currentVal = maxVal - ((range / steps) * i);

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: _formatLabel(currentVal),
        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 9.5, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - (textPainter.height / 2)));
    }

    final double stepX = data.length == 1 ? chartWidth / 2 : chartWidth / (data.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final double x = data.length == 1 ? paddingLeft + (chartWidth / 2) : paddingLeft + (i * stepX);
      final double val = (data[i][dataKey] as num).toDouble();
      
      final double y = paddingTop + chartHeight - (((val - minVal) / range) * chartHeight);
      points.add(Offset(x, y));

      textPainter.text = TextSpan(
        text: data[i]['date'].toString(),
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - paddingBottom + 6));
    }

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
          ..color = lineThemeColor.withOpacity(0.10)
          ..style = PaintingStyle.fill,
      );

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

  String _formatLabel(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    String formatted;

    if (absVal >= 1000000) {
      formatted = '${(absVal / 1000000).toStringAsFixed(1)}M';
    } else if (absVal >= 1000) {
      formatted = '${(absVal / 1000).toStringAsFixed(0)}k';
    } else {
      formatted = absVal.toInt().toString();
    }

    return isNegative ? '-$formatted' : formatted;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
