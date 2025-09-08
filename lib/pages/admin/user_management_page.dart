import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/add_user_page.dart';
import 'package:metabilim/pages/admin/edit_user_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('role')
      .orderBy('name')
      .snapshots();

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'Admin': return Icons.admin_panel_settings_outlined;
      case 'Mentor': return Icons.school_outlined;
      case 'Eğitim Koçu': return Icons.school_outlined; // İkonu mentor ile aynı tuttuk
      case 'Ogrenci': return Icons.person_outline;
      case 'Veli': return Icons.escalator_warning_outlined;
      default: return Icons.person;
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı başarıyla silindi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Kullanıcı silinemedi. $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kullanıcıyı Sil'),
          content: Text('$userName adlı kullanıcıyı kalıcı olarak silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(userId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('Sistemde kayıtlı kullanıcı bulunmuyor.'));

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              String name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
              String role = data['role'] ?? 'Bilinmiyor';

              // GÜNCELLENDİ: Öğrenci için Sınıf bilgisini de gösterecek şekilde düzenlendi
              String identifier;
              if (role == 'Ogrenci') {
                String studentClass = data['class'] ?? 'Sınıf Yok';
                String studentNumber = data['number'] ?? 'No Yok';
                identifier = 'Sınıf: $studentClass | No: $studentNumber';
              } else {
                identifier = data['username'] != null ? 'K.Adı: ${data['username']}' : '';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                    child: Icon(_getIconForRole(role)),
                  ),
                  title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('$role | $identifier'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                        tooltip: 'Düzenle',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => EditUserPage(userId: document.id, userData: data),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Sil',
                        onPressed: () {
                          _showDeleteConfirmationDialog(document.id, name);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kullanıcı Ekle'),
      ),
    );
  }
}