import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  final Map<DateTime, Map<String, bool>> _attendanceCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
  }

  Future<Map<String, bool>> _getAttendanceForDate(DateTime date) async {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    if (_attendanceCache.containsKey(dateOnly)) {
      return _attendanceCache[dateOnly]!;
    }

    // DEĞİŞİKLİK: Artık _auth.currentUser.uid yerine widget.studentId kullanılıyor
    final studentUid = widget.studentId;
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final querySnapshot = await _firestore
        .collection('attendance')
        .where('studentUid', isEqualTo: studentUid)
        .where('date', isEqualTo: formattedDate)
        .get();

    final dailyAttendance = {
      'Öğleden Önce': false,
      'Öğleden Sonra': false,
      'Akşam': false,
    };

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('session') && data.containsKey('status')) {
        if (dailyAttendance.containsKey(data['session'])) {
          dailyAttendance[data['session']] = (data['status'] == 'geldi');
        }
      }
    }
    _attendanceCache[dateOnly] = dailyAttendance;
    return dailyAttendance;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} Yoklama Durumu', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(primaryColor, secondaryColor),
            const SizedBox(height: 16),
            if (_selectedDate != null)
              Expanded(
                child: _buildDailyAttendanceDetails(_selectedDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Color primaryColor, Color secondaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'tr_TR',
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDate,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDate = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDate = focusedDay;
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
            leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAttendanceDetails(DateTime date) {
    return FutureBuilder<Map<String, bool>>(
      future: _getAttendanceForDate(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Bu tarih için yoklama verisi bulunamadı.', style: GoogleFonts.poppins()));
        }

        final attendance = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${DateFormat('d MMMM EEEE', 'tr_TR').format(date)} Detayı', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildAttendanceRow('Öğleden Önce', attendance['Öğleden Önce'] ?? false),
                _buildAttendanceRow('Öğleden Sonra', attendance['Öğleden Sonra'] ?? false),
                _buildAttendanceRow('Akşam', attendance['Akşam'] ?? false),
                _buildAttendanceSummary(attendance),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRow(String title, bool isPresent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16)),
          Icon(
            isPresent ? Icons.check_circle_outline : Icons.highlight_off,
            color: isPresent ? Colors.green.shade600 : Colors.red.shade600,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(Map<String, bool> attendance) {
    final totalCount = attendance.length;
    final presentCount = attendance.values.where((status) => status).length;
    final summaryText = '$totalCount dersten $presentCount tanesine katıldı.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(summaryText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}