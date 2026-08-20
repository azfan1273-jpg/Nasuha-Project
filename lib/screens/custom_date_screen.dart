import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

class CustomDateScreen extends StatefulWidget {
  final DateTimeRange? initialRange;

  const CustomDateScreen({super.key, this.initialRange});

  @override
  State<CustomDateScreen> createState() => _CustomDateScreenState();
}

class _CustomDateScreenState extends State<CustomDateScreen> {
  static const Color _bgSoft = Color(0xFFFAF5F7);
  static const Color _textDark = Color(0xFF111827);
  static const Color _primaryPurple = Color(0xFF7E22CE);

  late List<DateTime?> _selectedDates;

  @override
  void initState() {
    super.initState();
    final defaultStart = DateTime.now().subtract(const Duration(days: 7));
    final defaultEnd = DateTime.now();

    _selectedDates = [
      widget.initialRange?.start ?? defaultStart,
      widget.initialRange?.end ?? defaultEnd,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: SizedBox(
          width: 385, // 🔒 Terkunci Presisi 385px
          child: Scaffold(
            backgroundColor: _bgSoft,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: _textDark),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Pilih Rentang Tanggal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // KONTEN KALENDER MODERN
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CalendarDatePicker2(
                        config: CalendarDatePicker2Config(
                          calendarType: CalendarDatePicker2Type.range,
                          selectedDayHighlightColor: _primaryPurple,
                          selectedRangeHighlightColor: const Color(0xFFF3E8FF),
                          selectedRangeDayTextStyle: const TextStyle(
                            color: _primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                          weekdayLabelTextStyle: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          controlsTextStyle: const TextStyle(
                            color: _textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          dayTextStyle: const TextStyle(
                            color: _textDark,
                            fontSize: 12,
                          ),
                          todayTextStyle: const TextStyle(
                            color: _primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                          dayBorderRadius: BorderRadius.circular(8),
                        ),
                        value: _selectedDates,
                        onValueChanged: (dates) {
                          setState(() => _selectedDates = dates);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TOMBOL AKSI BAWAH
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.black26),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'BATAL',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA3E635),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (_selectedDates.length == 2 &&
                                  _selectedDates[0] != null &&
                                  _selectedDates[1] != null) {
                                final range = DateTimeRange(
                                  start: _selectedDates[0]!,
                                  end: _selectedDates[1]!,
                                );
                                Navigator.pop(context, range);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              'TERAPKAN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
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
    );
  }
}
