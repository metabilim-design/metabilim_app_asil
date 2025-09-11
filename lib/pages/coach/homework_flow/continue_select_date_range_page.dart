import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/select_previous_schedule_page.dart';

class ContinueSelectDateRangePage extends StatefulWidget {
  final AppUser student;

  const ContinueSelectDateRangePage({Key? key, required this.student}) : super(key: key);

  @override
  _ContinueSelectDateRangePageState createState() => _ContinueSelectDateRangePageState();
}

class _ContinueSelectDateRangePageState extends State<ContinueSelectDateRangePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isChecking = false;

  Future<void> _checkForExistingSchedulesAndProceed() async {
    if (_rangeStart == null || _rangeEnd == null) return;

    setState(() => _isChecking = true);

    try {
      final existingSchedules = await FirebaseFirestore.instance
          .collection('schedules')
          .where('studentUid', isEqualTo: widget.student.uid)
          .get();

      bool hasOverlap = false;
      if (existingSchedules.docs.isNotEmpty) {
        for (var doc in existingSchedules.docs) {
          final data = doc.data();
          final existingStart = (data['startDate'] as Timestamp).toDate();
          final existingEnd = (data['endDate'] as Timestamp).toDate();
          final newStart = _rangeStart!;
          final newEnd = _rangeEnd!.add(const Duration(hours: 23, minutes: 59));

          if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
            hasOverlap = true;
            break;
          }
        }
      }

      if (mounted) {
        if (hasOverlap) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu tarihlerde veya bu tarih aralığını kapsayan başka bir program zaten mevcut.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SelectPreviousSchedulePage(
              student: widget.student,
              newStartDate: _rangeStart!,
              newEndDate: _rangeEnd!,
            ),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Program kontrol edilirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Tarih Aralığı Seç'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Devam edilecek programın uygulanacağı YENİ tarih aralığını seçin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: TableCalendar(
                locale: 'tr_TR',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _rangeSelectionMode,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _selectedDay = null;
                    _focusedDay = focusedDay;
                    _rangeStart = start;
                    _rangeEnd = end;
                  });
                },
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  rangeStartDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: (_rangeStart == null || _rangeEnd == null || _isChecking)
              ? null
              : _checkForExistingSchedulesAndProceed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isChecking
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Eski Program Seçimine Geç', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}