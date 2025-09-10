// lib/pages/mentor/class_roster_page.dart - GÜNCELLENMİŞ TAM KOD

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
// ESKİ: import 'package:firebase_auth/firebase_auth.dart'; // Artık mentor ID'sine ihtiyacımız yok
import 'package:metabilim/pages/mentor/student_list_page.dart';

class ClassRosterPage extends StatelessWidget {
  final String purpose;

  const ClassRosterPage({super.key, required this.purpose});

  @override
  Widget build(BuildContext context) {
    // ESKİ: const mentorId = FirebaseAuth.instance.currentUser?.uid; // Bu satırı sildik.

    return Scaffold(
      appBar: AppBar(
        title: Text(
          purpose == 'homeworkCheck' ? 'Ödev Kontrol - Sınıf Seç' : 'Sınıflar',
          style: GoogleFonts.poppins(),
        ),
        // mentor_shell'de AppBar olduğu için bu sayfada otomatik geri butonu olmasın
        // Not: Bu satır, shell yapısına göre isteğe bağlıdır.
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- DEĞİŞİKLİK BURADA ---
        // Sorgudan ".where('mentorId', isEqualTo: mentorId)" kısmını kaldırdık.
        // Artık veritabanındaki TÜM sınıfları getirir.
        stream: FirebaseFirestore.instance
            .collection('classes')
            .snapshots(),
        // --- BİTTİ ---
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Hata mesajını daha genel hale getirdik.
            return const Center(child: Text('Sisteme kayıtlı sınıf bulunamadı.'));
          }

          var classDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: classDocs.length,
            itemBuilder: (context, index) {
              var classDoc = classDocs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: Text(classDoc['className'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentListPage(
                          classId: classDoc.id,
                          purpose: purpose,
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