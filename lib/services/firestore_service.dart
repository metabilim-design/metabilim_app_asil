import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/models/user_model.dart';

// YENİ MODELLER İÇİN IMPORT (BİR SONRAKİ ADIMDA OLUŞTURACAĞIZ)
// import 'package-metabilim/models/homework_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SINIFLARA PROGRAM ATAMA İÇİN YENİ FONKSİYONLAR ---

  // Belirli bir sınıftaki tüm öğrencileri getiren fonksiyon
  Future<List<AppUser>> getStudentsByClass(String classId) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('classId', isEqualTo: classId)
          .get();
      return querySnapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Sınıftaki öğrenciler getirilirken hata: $e");
      return [];
    }
  }

  // Admin tarafından oluşturulan bir programı, bir sınıftaki tüm öğrencilere dağıtan fonksiyon
  // TODO: Bu fonksiyonu bir sonraki adımlarda dolduracağız.
  // Future<void> assignScheduleToClass(HomeworkSchedule schedule, String classId) async {
  //   final students = await getStudentsByClass(classId);
  //   final batch = _db.batch();

  //   for (final student in students) {
  //     // Her öğrenci için 'schedules' alt koleksiyonuna yeni bir döküman oluştur
  //     final scheduleRef = _db.collection('users').doc(student.uid).collection('schedules').doc();
  //     batch.set(scheduleRef, schedule.toMap());
  //   }

  //   await batch.commit();
  //   debugPrint('${students.length} öğrenciye program başarıyla atandı.');
  // }


  // --- MEVCUT VE DOĞRU ÇALIŞAN FONKSİYONLAR (DOKUNMUYORUZ) ---

  Future<List<AppUser>> getStudentsForCoach() async {
    try {
      final String? coachId = FirebaseAuth.instance.currentUser?.uid;
      if (coachId == null) {
        throw Exception("Koç girişi yapılmamış veya UID bulunamadı.");
      }
      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('coachUid', isEqualTo: coachId)
          .get();
      if (querySnapshot.docs.isEmpty) {
        debugPrint("Bu koça atanmış öğrenci bulunamadı.");
        return [];
      }
      return querySnapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Koçun öğrencileri getirilirken hata: $e");
      return [];
    }
  }

  Future<String?> getUserIdByStudentNumber(String studentNumber) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('number', isEqualTo: studentNumber.trim())
          .where('role', isEqualTo: 'Ogrenci')
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Öğrenci ID alınırken hata: $e');
      return null;
    }
  }

  Future<void> saveExamResults(List<StudentExamResult> results, String examName) async {
    final batch = _db.batch();
    final examDocRef = _db.collection('exams').doc();

    batch.set(examDocRef, {
      'examName': examName,
      'examDate': Timestamp.now(),
      'studentCount': results.length,
      'examType': results.isNotEmpty ? results.first.examType : 'BRANŞ',
    });

    int foundStudents = 0;
    for (var result in results) {
      final studentNumberFromPdf = result.studentNumber.trim();
      final userId = await getUserIdByStudentNumber(studentNumberFromPdf);

      if (userId != null) {
        final resultDocRef = examDocRef.collection('results').doc(userId);
        batch.set(resultDocRef, result.toJson());
        foundStudents++;
      } else {
        debugPrint('UYARI: PDF\'ten okunan "${studentNumberFromPdf}" numaralı öğrenci veritabanında bulunamadı.');
      }
    }

    if (foundStudents == 0 && results.isNotEmpty) {
      throw Exception('Hiçbir öğrenci numarası veritabanıyla eşleşmedi.');
    }

    await batch.commit();
  }

  Future<List<StudentExamResult>> getStudentExams(String userId) async {
    try {
      final examsSnapshot = await _db.collection('exams').orderBy('examDate', descending: true).get();
      final List<StudentExamResult> studentResults = [];

      for (var examDoc in examsSnapshot.docs) {
        final resultDoc = await examDoc.reference.collection('results').doc(userId).get();
        if (resultDoc.exists) {
          studentResults.add(StudentExamResult.fromJson(resultDoc.data()!));
        }
      }
      return studentResults;
    } catch (e) {
      debugPrint('Öğrenci sınavları getirilirken hata: $e');
      return [];
    }
  }
}