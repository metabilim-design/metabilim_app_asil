import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Öğrenci ve görevini bir arada tutmak için bir model
class StudentTask {
  final String name;
  final String className;
  final String taskDescription;

  StudentTask({required this.name, required this.className, required this.taskDescription});
}

class EtutDetailPage extends StatefulWidget {
  final String timeSlot;

  const EtutDetailPage({super.key, required this.timeSlot});

  @override
  State<EtutDetailPage> createState() => _EtutDetailPageState();
}

class _EtutDetailPageState extends State<EtutDetailPage> {
  Future<List<StudentTask>> _fetchStudentsForSlot() async {
    final List<StudentTask> studentTasks = [];
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Tüm öğrencilerin bilgilerini (isim, sınıf) bir haritada toplayalım
    final studentsSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').get();
    final studentInfoMap = {for (var doc in studentsSnapshot.docs) doc.id: doc.data()};

    // Bugün aktif olan tüm programları çek
    final schedulesSnapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .get();

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final scheduleData = scheduleDoc.data();
      final studentId = scheduleData['studentUid'];
      final studentData = studentInfoMap[studentId];

      if (studentData != null) {
        final dailySlots = scheduleData['dailySlots'] as Map<String, dynamic>?;
        final todaySlots = dailySlots?[todayKey] as List<dynamic>?;

        if (todaySlots != null) {
          for (var slot in todaySlots) {
            if (slot['time'] == widget.timeSlot) {
              final taskData = slot['task'] as Map<String, dynamic>? ?? {};

              studentTasks.add(StudentTask(
                name: '${studentData['name']} ${studentData['surname']}',
                className: studentData['class'] ?? 'Sınıfsız',
                taskDescription: _getTaskDescription(taskData),
              ));
              break; // Bu öğrenci için doğru slotu bulduk, diğer slotlara bakmaya gerek yok
            }
          }
        }
      }
    }

    // Listeyi isme göre sıralayalım
    studentTasks.sort((a, b) => a.name.compareTo(b.name));
    return studentTasks;
  }

  String _getTaskDescription(Map<String, dynamic> task) {
    final type = task['type'];
    if (type == 'topic') {
      return '${task['subject']}: ${task['konu']}';
    } else if (type == 'practice') {
      return '${task['subject']}: Deneme Çözümü';
    } else if (type == 'digital') {
      return 'Dijital Etüt: ${task['task']}';
    } else if (type == 'fixed') {
      return task['title'] ?? 'Etkinlik';
    } else if (type == 'empty') {
      return 'Boş Etüt';
    }
    return 'Tanımsız Görev';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.timeSlot, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Etüt Detayları', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: FutureBuilder<List<StudentTask>>(
        future: _fetchStudentsForSlot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veriler yüklenirken bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bu saatte programı olan öğrenci bulunamadı.'));
          }

          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentTask = students[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  title: Text(studentTask.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Sınıf: ${studentTask.className}\nGörev: ${studentTask.taskDescription}',
                    style: GoogleFonts.poppins(height: 1.5),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}