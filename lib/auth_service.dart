import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu email/kullanıcı adı zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz bir email formatı girdiniz.';
      case 'user-not-found':
        return 'Bu kullanıcı adı veya numaraya sahip bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Mevcut şifrenizi yanlış girdiniz.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // GÜNCELLENDİ: Öğrenci kaydı sadeleştirildi. Sınıf ve koç ataması artık buradan yapılmıyor.
  Future<String?> registerStudent({
    required String name,
    required String surname,
    required String number,
    required String password,
  }) async {
    String email = '$number@metabilim.app';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'surname': surname,
          'number': number,
          'email': email,
          'role': 'Ogrenci',
          'class': null, // Başlangıçta sınıfı yok
          'coachUid': null, // Başlangıçta koçu yok
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  Future<String?> registerMentor({
    required String name,
    required String surname,
    required String username,
    required String password,
  }) async {
    String email = '$username@metabilim.mentor';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'surname': surname,
          'username': username,
          'email': email,
          'role': 'Mentor',
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  Future<String?> registerCoach({
    required String name,
    required String surname,
    required String username,
    required String password,
  }) async {
    String email = '$username@metabilim.coach';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'surname': surname,
          'username': username,
          'email': email,
          'role': 'Eğitim Koçu',
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  // GÜNCELLENDİ: Veli kaydı artık ilişkili öğrencinin ID'sini (studentUid) alıyor
  Future<String?> registerParent({
    required String name,
    required String surname,
    required String username,
    required String password,
    required String? studentUid,
  }) async {
    if (studentUid == null) {
      return 'Lütfen velinin bağlanacağı öğrenciyi seçin.';
    }
    String email = '$username@metabilim.parent';
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'surname': surname,
          'username': username,
          'email': email,
          'role': 'Veli',
          'studentUid': studentUid, // Öğrenci bağlantısını veritabanına kaydediyoruz
        });
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
    return 'Bilinmeyen bir hata oluştu.';
  }

  String _getEmailSuffixForRole(String role) {
    switch (role) {
      case 'Ogrenci': return '@metabilim.app';
      case 'Mentor': return '@metabilim.mentor';
      case 'Eğitim Koçu': return '@metabilim.coach';
      case 'Veli': return '@metabilim.parent';
      case 'Admin': return '@metabilim.admin';
      default: return '';
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
    required String role,
  }) async {
    String suffix = _getEmailSuffixForRole(role);
    if (suffix.isEmpty) {
      return {'success': false, 'message': 'Geçersiz rol belirtildi.'};
    }
    String email = '$identifier$suffix';

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return {'success': true, 'role': doc.get('role')};
      }
      return {'success': false, 'message': 'Kullanıcı bulunamadı.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.get('role');
    } catch (e) {
      return null;
    }
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword
  }) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential( email: user.email!, password: oldPassword );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        return null;
      } on FirebaseAuthException catch (e) {
        return _getErrorMessage(e.code);
      } catch (e) { return "Şifre güncellenirken bir hata oluştu."; }
    }
    return "Önce giriş yapmanız gerekiyor.";
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}