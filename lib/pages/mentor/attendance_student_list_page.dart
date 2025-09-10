// lib/pages/mentor/attendance_student_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';

class AttendanceStudentListPage extends StatefulWidget {
  final String classId;
  final String className;
  final String timeSlot;

  const AttendanceStudentListPage({
    super.key,
    required this.classId,
    required this.className,
    required this.timeSlot,
  });

  @override
  State<AttendanceStudentListPage> createState() => _AttendanceStudentListPageState();
}

class _AttendanceStudentListPageState extends State<AttendanceStudentListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppUser> _students = [];
  Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndAttendance();
  }

  Future<void> _fetchStudentsAndAttendance() async {
    setState(() => _isLoading = true);
    try {
      // Sınıftaki öğrencileri çek
      final studentSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('class', isEqualTo: widget.classId)
          .get();
      _students = studentSnapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
      _students.sort((a,b) => a.name.compareTo(b.name));

      // Bu ders için daha önce yoklama alınmış mı diye kontrol et
      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: formattedDate)
          .where('session', isEqualTo: widget.timeSlot)
          .get();

      final Map<String, String> previousRecords = {
        for(var doc in attendanceSnapshot.docs) doc.data()['studentUid'] : doc.data()['status']
      };

      // Durumları başlat
      _attendanceStatus = {
        for (var student in _students)
          student.uid: previousRecords[student.uid] ?? 'belirsiz'
      };

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler yüklenirken hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAttendance(String studentId, String status) {
    setState(() => _attendanceStatus[studentId] = status);
  }

  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student.uid] = 'geldi';
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    WriteBatch batch = _firestore.batch();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String mentorId = FirebaseAuth.instance.currentUser!.uid;

    _attendanceStatus.forEach((studentId, status) {
      if (status != 'belirsiz') {
        DocumentReference docRef = _firestore.collection('attendance').doc('${today}_${studentId}_${widget.timeSlot}');
        batch.set(docRef, {
          'date': today,
          'session': widget.timeSlot,
          'studentUid': studentId,
          'status': status,
          'mentorUid': mentorId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yoklama başarıyla kaydedildi!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(); // Bir önceki sayfaya (etüt seçimine) dön
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydederken hata oluştu: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.timeSlot} Yoklaması'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllPresent,
            tooltip: 'Tümünü Var Olarak İşaretle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final status = _attendanceStatus[student.uid] ?? 'belirsiz';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${student.name} ${student.surname}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Text('No: ${student.schoolNumber ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(icon: Icon(Icons.check_circle, color: status == 'geldi' ? Colors.green : Colors.grey), onPressed: () => _markAttendance(student.uid, 'geldi')),
                      IconButton(icon: Icon(Icons.cancel, color: status == 'gelmedi' ? Colors.red : Colors.grey), onPressed: () => _markAttendance(student.uid, 'gelmedi')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAttendance,
        label: const Text('Yoklamayı Kaydet'),
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save),
      ),
    );
  }
}