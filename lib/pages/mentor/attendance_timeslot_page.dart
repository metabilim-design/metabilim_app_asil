// lib/pages/mentor/attendance_timeslot_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'attendance_student_list_page.dart'; // Son adımımız

class AttendanceTimeSlotPage extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceTimeSlotPage({super.key, required this.classId, required this.className});

  @override
  State<AttendanceTimeSlotPage> createState() => _AttendanceTimeSlotPageState();
}

class _AttendanceTimeSlotPageState extends State<AttendanceTimeSlotPage> {
  Future<List<String>> _getSlotsForToday() async {
    final firestore = FirebaseFirestore.instance;
    final classDoc = await firestore.collection('classes').doc(widget.classId).get();
    final activeTimetableId = classDoc.data()?['activeTimetableId'] as String?;

    if (activeTimetableId == null || activeTimetableId.isEmpty) return [];

    final templateDoc = await firestore.collection('schedule_templates').doc(activeTimetableId).get();
    if (!templateDoc.exists) return [];

    final timetable = templateDoc.data()?['timetable'] as Map<String, dynamic>? ?? {};
    final dayName = _getDayNameInTurkish(DateTime.now().weekday);
    final List<String> slots = List<String>.from(timetable[dayName] ?? []);
    slots.sort();
    return slots;
  }

  String _getDayNameInTurkish(int weekday) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Etüt Seç'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getSlotsForToday(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Etüt saatleri yüklenemedi.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Bu sınıf için bugün ayarlanmış etüt saati bulunmuyor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          final timeSlots = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final slot = timeSlots[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.access_time_filled_outlined, size: 40),
                  title: Text(slot, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => AttendanceStudentListPage(
                        classId: widget.classId,
                        className: widget.className,
                        timeSlot: slot,
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}