// lib/models/user_model.dart
class AppUser {
  final String uid;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String? schoolNumber; // Okul Numarası
  final String? classId; // Sınıf ID'si
  final String? className; // HATA İÇİN EKLENDİ: Sınıf Adı
  final String? coachUid; // Atanmış koçun UID'si

  AppUser({
    required this.uid,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    this.schoolNumber,
    this.classId,
    this.className, // HATA İÇİN EKLENDİ
    this.coachUid,
  });

  // HATA İÇİN EKLENDİ: withClassName adında bir kopyalama metodu
  // Bu metod, mevcut kullanıcı bilgilerini koruyarak sadece sınıf adını ekler.
  AppUser withClassName(String? newClassName) {
    return AppUser(
      uid: uid,
      name: name,
      surname: surname,
      email: email,
      role: role,
      schoolNumber: schoolNumber,
      classId: classId,
      className: newClassName, // Sadece sınıf adı güncellenir
      coachUid: coachUid,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Ogrenci',
      schoolNumber: data['number'], // Veritabanındaki adı 'number'
      classId: data['class'], // Veritabanındaki adı 'class'
      coachUid: data['coachUid'],
      // className burada doldurulmaz, çünkü user dökümanında bu bilgi yok.
      // Bu bilgi, sonradan veritabanından okunarak eklenecek.
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'role': role,
      'number': schoolNumber,
      'class': classId,
      'coachUid': coachUid,
    };
  }
}