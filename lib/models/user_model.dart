class AppUser {
  final String uid;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String? schoolNumber; // Öğrenciler için
  final String? username;     // Diğer roller için
  final String? studentUid;   // Veliler için
  final String? coachUid;     // Öğrenciler için
  final String? classId;      // Öğrenciler için

  AppUser({
    required this.uid,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    this.schoolNumber,
    this.username,
    this.studentUid,
    this.coachUid,
    this.classId,
  });

  // Firestore'dan gelen veriyi AppUser modeline dönüştürmek için
  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      schoolNumber: data['number'], // Firestore'da 'number' olarak kayıtlı
      username: data['username'],
      studentUid: data['studentUid'],
      coachUid: data['coachUid'],
      classId: data['class'], // Firestore'da 'class' olarak kayıtlı
    );
  }
}