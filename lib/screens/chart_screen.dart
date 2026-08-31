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

    // 🟢 DONUT CHART PENGELUARAN
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
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                size: const Size(130, 130),
                painter: DonutChartPainter(data: pieData, totalExpense: totalExpense),
              ),
            ),
            const SizedBox(width: 20),
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

    // 🟢 PERBAIKAN LOGIKA PENGELOMPOKAN GRAFIK
    final Map<String, Map<String, double>> dailyMap = {};
    
    for (var item in items) {
      final String rawDate = item['created_at']?.toString() ?? '';
      if (rawDate.isEmpty) continue;
      
      // Gunakan YYYY-MM-DD sebagai key agar pengurutan tanggal akurat
      final String dateKey = rawDate.split('T')[0]; 
      final double amount = num.tryParse(item['total_price']?.toString() ?? '0')?.toDouble() ?? 0.0;
      final bool isLunas = (item['status_pembayaran'] ?? '').toString().toLowerCase() == 'lunas';
    
      dailyMap.putIfAbsent(dateKey, () => {'omset': 0.0, 'pendapatan': 0.0, 'pengeluaran': 0.0});
      dailyMap[dateKey]!['omset'] = (dailyMap[dateKey]!['omset'] ?? 0.0) + amount;
      if (isLunas) {
        dailyMap[dateKey]!['pendapatan'] = (dailyMap[dateKey]!['pendapatan'] ?? 0.0) + amount;
      }
    }
    
    for (var item in expenses) {
      final String rawDate = item['created_at']?.toString() ?? '';
      if (rawDate.isEmpty) continue;
      
      final String dateKey = rawDate.split('T')[0]; 
      final double amount = num.tryParse(item['amount']?.toString() ?? '0')?.toDouble() ?? 0.0;
    
      dailyMap.putIfAbsent(dateKey, () => {'omset': 0.0, 'pendapatan': 0.0, 'pengeluaran': 0.0});
      dailyMap[dateKey]!['pengeluaran'] = (dailyMap[dateKey]!['pengeluaran'] ?? 0.0) + amount;
    }
    
    // 1. Urutkan ISO Date string (YYYY-MM-DD) secara akurat dari tanggal lama ke baru
    final List<String> sortedDates = dailyMap.keys.toList()..sort();
    
    // 2. Petakan data dan ubah key menjadi format tampilan pendek
    final List<Map<String, dynamic>> chartData = sortedDates.map((isoDate) {
      final double o = dailyMap[isoDate]!['omset'] ?? 0.0;
      final double p = dailyMap[isoDate]!['pendapatan'] ?? 0.0;
      final double e = dailyMap[isoDate]!['pengeluaran'] ?? 0.0;
      return {
        'date': _formatShortDate(isoDate), // Diformat di sini khusus untuk tampilan label sumbu-X
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

// 🟢 PAINTER GRAFIK DENGAN DUKUNGAN TITIK NOL DI TENGAH (RUGI / UNTUNG)
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
    const double paddingLeft = 55.0;
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

    double maxVal = 0.0;
    double minVal = 0.0;

    for (var item in data) {
      final double v = (item[dataKey] as num).toDouble();
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }

    // 🟢 DUKUNGAN TITIK NOL DI TENGAH UNTUK TAB PROFIT / LOSS
    if (activeTab == 'Profit') {
      double bound = max(maxVal.abs(), minVal.abs());
      if (bound == 0) bound = 50000.0; // Fallback skala
      maxVal = bound;
      minVal = -bound;
    } else {
      if (maxVal == 0) maxVal = 50000.0;
      minVal = 0.0;
    }

    double range = maxVal - minVal;

    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.08)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const int steps = 4;

    // GAMBAR GARIS GRID DAN SUBTITEL Y-AXIS
    for (int i = 0; i <= steps; i++) {
      final double y = paddingTop + (chartHeight / steps) * i;
      final double currentVal = maxVal - ((range / steps) * i);

      // Garis Nol Merah Khusus
      if (activeTab == 'Profit' && currentVal.round() == 0) {
        final zeroPaint = Paint()
          ..color = Colors.redAccent.withOpacity(0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), zeroPaint);
      } else {
        canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      }

      textPainter.text = TextSpan(
        text: _formatLabel(currentVal),
        style: TextStyle(
          color: (activeTab == 'Profit' && currentVal < 0) ? Colors.redAccent : textColor.withOpacity(0.6),
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ),
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
      final double yZero = paddingTop + chartHeight - (((0 - minVal) / range) * chartHeight);

      final path = Path()..moveTo(points.first.dx, yZero);
      for (var pt in points) {
        path.lineTo(pt.dx, pt.dy);
      }
      path.lineTo(points.last.dx, yZero);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = (points.last.dy > yZero ? Colors.redAccent : lineThemeColor).withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(
        linePath,
        Paint()
          ..color = (points.last.dy > yZero ? Colors.redAccent : lineThemeColor)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (var pt in points) {
        final bool isLoss = pt.dy > yZero;
        final pointColor = isLoss ? Colors.redAccent : lineThemeColor;

        canvas.drawCircle(pt, 4.0, Paint()..color = pointColor);
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
