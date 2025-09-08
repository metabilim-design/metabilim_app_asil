import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Kullanıcıları role göre sıralı getiren stream
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('role')
      .snapshots();

  // Role göre ikon döndüren yardımcı fonksiyon
  IconData _getIconForRole(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      case 'Mentor':
        return Icons.school_outlined;
      case 'Ogrenci':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  // Role göre renk döndüren yardımcı fonksiyon
  Color _getColorForRole(BuildContext context, String role) {
    switch (role) {
      case 'Admin':
        return Colors.redAccent;
      case 'Mentor':
        return Theme.of(context).colorScheme.secondary; // turkuaz
      case 'Ogrenci':
        return Theme.of(context).primaryColor; // koyu mavi
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sistemde kayıtlı kullanıcı bulunmuyor.'));
          }

          final userCount = snapshot.data!.docs.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Sistemdeki Toplam Kullanıcı: $userCount',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    String name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
                    String role = data['role'] ?? 'Bilinmiyor';
                    String identifier = role == 'Ogrenci'
                        ? 'No: ${data['number'] ?? 'N/A'}'
                        : (data['username'] != null ? 'K.Adı: ${data['username']}' : '');

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: _getColorForRole(context, role).withOpacity(0.5), width: 1),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForRole(context, role).withOpacity(0.1),
                          foregroundColor: _getColorForRole(context, role),
                          child: Icon(_getIconForRole(role)),
                        ),
                        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text('$role | $identifier'),
                        // Bu sayfada düzenleme/silme butonu yok, sadece listeleme
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}