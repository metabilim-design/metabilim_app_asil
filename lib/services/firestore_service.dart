// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:metabilim/models/exam_result.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getUserIdByStudentNumber(String studentNumber) async {
    try {
      // --- DÜZELTME BURADA: 'studentNumber' yerine 'number' alanında arama yapılıyor ---
      final querySnapshot = await _db
          .collection('users')
          .where('number', isEqualTo: studentNumber.trim()) // 'studentNumber' -> 'number'
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

    debugPrint('$foundStudents/${results.length} öğrenci eşleştirildi ve kaydedilmek üzere hazırlandı.');

    if (foundStudents == 0 && results.isNotEmpty) {
      throw Exception('Hiçbir öğrenci numarası veritabanıyla eşleşmedi. Lütfen veritabanındaki "number" alanını ve PDF\'teki öğrenci numaralarını kontrol edin.');
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