import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/models/user_model.dart'; // Projendeki AppUser modelinin olduğu yolu varsayıyorum

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ETÜT PROGRAMI ŞABLONLARI ---
  // BU FONKSİYONLAR YENİ EKLENDİ

  /// Firestore'da yeni bir etüt programı şablonu oluşturur.
  /// Başlangıçta sadece adı ve oluşturulma tarihi bulunur. Saatler daha sonra düzenlenir.
  Future<void> createScheduleTemplate(String templateName) async {
    try {
      await _db.collection('schedule_templates').add({
        'templateName': templateName,
        'createdAt': FieldValue.serverTimestamp(), // Sıralama için oluşturulma zamanını ekliyoruz
        'timetable': {}, // Başlangıçta boş bir timetable haritası
      });
    } catch (e) {
      debugPrint("Etüt şablonu oluşturulurken hata: $e");
      rethrow; // Hatayı UI katmanına tekrar fırlat
    }
  }

  /// Belirli bir sınıfın aktif etüt programını (şablon ID'sini) günceller.
  Future<void> setActiveTimetableForClass(String classId, String templateId) async {
    try {
      // 'classes' koleksiyonundaki ilgili sınıf dökümanını bul ve güncelle.
      await _db.collection('classes').doc(classId).update({
        'activeTimetableId': templateId,
      });
    } catch (e) {
      debugPrint("Sınıfın aktif programı ayarlanırken hata: $e");
      rethrow;
    }
  }


  // --- YENİ FONKSİYONLAR: SINIFLARA ÖZEL ETÜT SAATLERİ İÇİN ---

  /// Bir sınıfın haftalık etüt programını Firestore'a kaydeder veya günceller.
  /// `timetable` Map'i şöyle bir yapıda olmalı: {'pazartesi': ['09:00-09:45', '10:00-10:45'], 'sali': [...] }
  Future<void> saveClassTimetable(String classId, Map<String, dynamic> timetable) async {
    try {
      // 'class_timetables' adında yeni bir koleksiyon oluşturup, döküman ID'si olarak sınıfın ID'sini kullanarak kaydet.
      // Bu, her sınıfın kendi program dökümanı olmasını sağlar.
      await _db.collection('class_timetables').doc(classId).set(timetable);
    } catch (e) {
      debugPrint("Sınıf etüt programı kaydedilirken hata: $e");
      rethrow;
    }
  }

  /// Belirli bir sınıfın haftalık etüt programını Firestore'dan getirir.
  Future<DocumentSnapshot?> getClassTimetable(String classId) async {
    try {
      final doc = await _db.collection('class_timetables').doc(classId).get();
      if (doc.exists) {
        return doc;
      }
      return null; // Eğer o sınıf için henüz bir program oluşturulmamışsa null döner.
    } catch (e) {
      debugPrint("Sınıf etüt programı getirilirken hata: $e");
      return null;
    }
  }

  // --- MEVCUT VE DOĞRU ÇALIŞAN FONKSİYONLAR (DOKUNULMADI) ---

  Future<List<AppUser>> getStudentsForCoach() async {
    try {
      final String? coachId = FirebaseAuth.instance.currentUser?.uid;
      if (coachId == null) {
        throw Exception("Koç girişi yapılmamış veya UID bulunamadı.");
      }

      // 'users' koleksiyonunda, 'coachUid' alanı mevcut koçun ID'sine eşit olan tüm öğrencileri bul.
      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('coachUid', isEqualTo: coachId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("Bu koça atanmış öğrenci bulunamadı.");
        return [];
      }

      // Her bir dökümanı senin AppUser modeline çeviriyoruz
      return querySnapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Koçun öğrencileri getirilirken hata: $e");
      return [];
    }
  }

  Future<String?> getUserIdByStudentNumber(String studentNumber) async {
    try {
      // Senin modeline göre arama alanı 'number'
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