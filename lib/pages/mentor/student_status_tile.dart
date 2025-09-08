import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'student_detail_page.dart';

class StatusInfo {
  final String text;
  final Color color;
  StatusInfo(this.text, this.color);
}

class StudentStatusTile extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentStatusTile({
    super.key,
    required this.studentId,
    required this.studentData, // EKSİK OLAN SATIR BUYDU, EKLENDİ
  });

  @override
  State<StudentStatusTile> createState() => _StudentStatusTileState();
}

class _StudentStatusTileState extends State<StudentStatusTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  StatusInfo _getCurrentStatus(DocumentSnapshot? scheduleDoc, BuildContext context) {
    if (scheduleDoc == null) {
      return StatusInfo('Program Atanmamış', Colors.grey);
    }

    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final allSlots = scheduleDoc.get('dailySlots') as Map<String, dynamic>;
    final slotsForToday = allSlots[dateKey] as List<dynamic>? ?? [];

    final currentTime = TimeOfDay.fromDateTime(now);

    final currentSlot = slotsForToday.firstWhereOrNull((slot) {
      final timeParts = (slot['time'] as String).split(' - ');
      if (timeParts.length != 2) return false;

      final startTimeParts = timeParts[0].split(':');
      final endTimeParts = timeParts[1].split(':');
      if (startTimeParts.length != 2 || endTimeParts.length != 2) return false;

      final startTime = TimeOfDay(hour: int.parse(startTimeParts[0]), minute: int.parse(startTimeParts[1]));
      final endTime = TimeOfDay(hour: int.parse(endTimeParts[0]), minute: int.parse(endTimeParts[1]));

      final startAsDouble = startTime.hour + startTime.minute / 60.0;
      final endAsDouble = endTime.hour + endTime.minute / 60.0;
      final currentAsDouble = currentTime.hour + currentTime.minute / 60.0;

      return currentAsDouble >= startAsDouble && currentAsDouble < endAsDouble;
    });

    if (currentSlot == null) {
      return StatusInfo('Etüt Saatleri Dışında', Colors.red);
    }

    final task = currentSlot['task'] as Map<String, dynamic>;
    final type = task['type'];

    if (type == 'empty') return StatusInfo('Boş Etüt', Colors.grey);
    if (type == 'fixed') return StatusInfo(task['title'] ?? 'Etkinlik', Theme.of(context).primaryColor);

    String statusText;
    if (type == 'digital') {
      statusText = 'Dijital Etüt: ${task['task']}';
    } else if (type == 'topic' || type == 'practice') {
      final subject = (task['subject'] as String).split('-').last;
      final topic = task['konu'] ?? 'Deneme';
      statusText = '$subject: $topic';
    } else {
      return StatusInfo('Etüt Saatleri Dışında', Colors.red);
    }

    return StatusInfo(statusText, Colors.green.shade700);
  }

  @override
  Widget build(BuildContext context) {
    final studentData = widget.studentData;
    final studentName = '${studentData['name']} ${studentData['surname']}';

    final scheduleStream = FirebaseFirestore.instance
        .collection('schedules')
        .where('studentUid', isEqualTo: widget.studentId)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: scheduleStream,
      builder: (context, snapshot) {
        StatusInfo statusInfo;
        if (snapshot.connectionState == ConnectionState.waiting) {
          statusInfo = StatusInfo('Yükleniyor...', Colors.grey);
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          statusInfo = StatusInfo('Program Atanmamış', Colors.grey);
        } else {
          statusInfo = _getCurrentStatus(snapshot.data!.docs.first, context);
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                studentData['name'] != null && studentData['name'].isNotEmpty ? studentData['name'][0] : 'Ö',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(studentName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text(
              statusInfo.text,
              style: GoogleFonts.poppins(color: statusInfo.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailPage(
                    studentId: widget.studentId,
                    studentName: studentName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}