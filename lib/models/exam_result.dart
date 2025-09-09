// lib/models/exam_result.dart

class LessonResult {
  final String lessonName;
  final double correct;
  final double wrong;
  final double net;

  LessonResult({
    required this.lessonName,
    required this.correct,
    required this.wrong,
    required this.net,
  });

  factory LessonResult.fromJson(Map<String, dynamic> json) {
    return LessonResult(
      lessonName: json['lessonName'] ?? 'Bilinmiyor',
      correct: (json['correct'] as num?)?.toDouble() ?? 0.0,
      wrong: (json['wrong'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonName': lessonName,
      'correct': correct,
      'wrong': wrong,
      'net': net,
    };
  }
}

class StudentExamResult {
  final String examName;
  final String studentNumber;
  final String fullName;
  final String className;
  final double totalCorrect;
  final double totalWrong;
  final double totalNet;
  final double score;
  final int overallRank;
  final int classRank;
  final List<LessonResult> lessonResults;
  final String examType; // YENİ: Sınav türünü (TYT, AYT, BRANŞ) tutacak alan

  StudentExamResult({
    required this.examName,
    required this.studentNumber,
    required this.fullName,
    required this.className,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalNet,
    required this.score,
    required this.overallRank,
    required this.classRank,
    required this.lessonResults,
    required this.examType, // YENİ
  });

  factory StudentExamResult.fromJson(Map<String, dynamic> json) {
    var lessonsFromJson = json['lessonResults'] as List<dynamic>? ?? [];
    List<LessonResult> lessonList = lessonsFromJson.map((i) => LessonResult.fromJson(i)).toList();

    return StudentExamResult(
      examName: json['examName'] ?? 'İsimsiz Sınav',
      studentNumber: json['studentNumber'] ?? '',
      fullName: json['fullName'] ?? 'İsimsiz',
      className: json['className'] ?? 'Sınıfsız',
      totalCorrect: (json['totalCorrect'] as num?)?.toDouble() ?? 0.0,
      totalWrong: (json['totalWrong'] as num?)?.toDouble() ?? 0.0,
      totalNet: (json['totalNet'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      overallRank: (json['overallRank'] as num?)?.toInt() ?? 0,
      classRank: (json['classRank'] as num?)?.toInt() ?? 0,
      lessonResults: lessonList,
      examType: json['examType'] ?? 'BRANŞ', // YENİ: Veritabanında yoksa varsayılan olarak BRANŞ ata
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examName': examName,
      'studentNumber': studentNumber,
      'fullName': fullName,
      'className': className,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'totalNet': totalNet,
      'score': score,
      'overallRank': overallRank,
      'classRank': classRank,
      'lessonResults': lessonResults.map((e) => e.toJson()).toList(),
      'examType': examType, // YENİ
    };
  }
}