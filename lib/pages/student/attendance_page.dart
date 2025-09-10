// lib/pages/student/attendance_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Her bir etüt saatinin yoklama durumunu tutacak bir model
class AttendanceStatus {
  final String timeSlot;
  final String status; // 'geldi', 'gelmedi', 'alınmadı'

  AttendanceStatus({required this.timeSlot, required this.status});
}

class AttendancePage extends StatefulWidget {
  final String? studentId;
  const AttendancePage({super.key, this.studentId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _targetStudentId;

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    _targetStudentId = widget.studentId ?? FirebaseAuth.instance.currentUser!.uid;
  }

  // ### BU FONKSİYON TAMAMEN YENİLENDİ ###
  // Artık öğrencinin sınıf programına göre yoklama verilerini çekiyor.
  Future<List<AttendanceStatus>> _getAttendanceForDate(DateTime date) async {
    // 1. Adım: Öğrencinin sınıfını ve aktif programını bul
    final userDoc = await _firestore.collection('users').doc(_targetStudentId).get();
    final classId = userDoc.data()?['class'] as String?;

    if (classId == null || classId.isEmpty) {
      return []; // Öğrenci bir sınıfa atanmamışsa boş liste döndür
    }

    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final activeTimetableId = classDoc.data()?['activeTimetableId'] as String?;

    if (activeTimetableId == null || activeTimetableId.isEmpty) {
      return []; // Sınıfa program atanmamışsa boş liste döndür
    }

    final templateDoc = await _firestore.collection('schedule_templates').doc(activeTimetableId).get();
    if (!templateDoc.exists) return [];

    final timetable = templateDoc.data()?['timetable'] as Map<String, dynamic>? ?? {};
    final dayName = _getDayNameInTurkish(date.weekday);

    // 2. Adım: O gün için geçerli etüt saatlerini şablondan çek
    final List<String> studySlots = List<String>.from(timetable[dayName] ?? []);
    if (studySlots.isEmpty) {
      return []; // O gün için etüt ayarlanmamışsa boş liste döndür
    }
    studySlots.sort(); // Saatleri sırala

    // 3. Adım: Öğrencinin o güne ait tüm yoklama kayıtlarını çek
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final querySnapshot = await _firestore
        .collection('attendance')
        .where('studentUid', isEqualTo: _targetStudentId)
        .where('date', isEqualTo: formattedDate)
        .get();

    final Map<String, String> attendanceRecords = {
      for (var doc in querySnapshot.docs) doc.data()['session']: doc.data()['status']
    };

    // 4. Adım: Etüt saatlerini ve yoklama kayıtlarını birleştir
    final List<AttendanceStatus> dailyAttendance = [];
    for (var slot in studySlots) {
      dailyAttendance.add(AttendanceStatus(
        timeSlot: slot,
        status: attendanceRecords[slot] ?? 'alınmadı',
      ));
    }

    return dailyAttendance;
  }

  String _getDayNameInTurkish(int weekday) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Arayüz kodunda bir değişiklik yok, sadece _getAttendanceForDate fonksiyonu değişti.
    // ... Geri kalan build metodu ve diğer widget'lar aynı kalabilir ...
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            todayDecoration: BoxDecoration(color: secondaryColor.withOpacity(0.5), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAttendanceDetails(DateTime date) {
    return FutureBuilder<List<AttendanceStatus>>(
      future: _getAttendanceForDate(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Veri yüklenemedi: ${snapshot.error}', style: GoogleFonts.poppins()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Bu tarih için programınızda etüt bulunmuyor.', style: GoogleFonts.poppins()));
        }

        final attendanceList = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  '${DateFormat('d MMMM EEEE', 'tr_TR').format(date)} Yoklama Detayı',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: attendanceList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return _buildAttendanceRow(attendance.timeSlot, attendance.status);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRow(String timeSlot, String status) {
    IconData icon;
    Color color;
    String statusText;

    switch (status) {
      case 'geldi':
        icon = Icons.check_circle_outline;
        color = Colors.green.shade600;
        statusText = 'Geldi';
        break;
      case 'gelmedi':
        icon = Icons.highlight_off;
        color = Colors.red.shade600;
        statusText = 'Gelmedi';
        break;
      default: // 'alınmadı' durumu
        icon = Icons.radio_button_unchecked;
        color = Colors.grey.shade500;
        statusText = 'Yoklama Alınmadı';
    }

    return ListTile(
      leading: Icon(Icons.access_time_filled, color: Theme.of(context).primaryColor),
      title: Text(timeSlot, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(statusText, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }
}