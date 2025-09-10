import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/students_by_class_page.dart'; // Bir sonraki adımda oluşturacağımız sayfa

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sınıflar', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false, // Geri tuşunu kaldır
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Veritabanındaki 'classes' koleksiyonundan tüm sınıfları çek
        stream: _firestore.collection('classes').orderBy('className').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Sınıflar yüklenirken bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sisteme kayıtlı sınıf bulunamadı.'));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final className = classDoc['className'] ?? 'İsimsiz Sınıf';
              final classId = classDoc.id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: const Icon(Icons.class_, color: Colors.blueGrey, size: 32),
                  title: Text(className, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Tıklanan sınıfın ID'si ve adıyla yeni sayfaya git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentsByClassPage(
                          classId: classId,
                          className: className,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}