// lib/pages/admin/digital_lesson_settings_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'computer_schedule_page.dart'; // YENİ OLUŞTURACAĞIMIZ SAYFAYA YÖNLENDİRECEK

class DigitalLessonSettingsPage extends StatefulWidget {
  const DigitalLessonSettingsPage({super.key});

  @override
  State<DigitalLessonSettingsPage> createState() => _DigitalLessonSettingsPageState();
}

class _DigitalLessonSettingsPageState extends State<DigitalLessonSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Sınıfları çekiyoruz
        stream: FirebaseFirestore.instance.collection('classes').orderBy('className').snapshots(),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sistemde kayıtlı sınıf bulunmuyor.'));
          }

          final classes = classSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final className = (classDoc.data() as Map<String, dynamic>)['className'] ?? 'İsimsiz Sınıf';

              // Her sınıf için bir ExpansionTile (açılır-kapanır menü)
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ExpansionTile(
                  leading: const Icon(Icons.class_, size: 40),
                  title: Text(className, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Öğrencileri görmek için dokunun'),
                  children: [
                    _buildStudentListOfClass(classDoc.id)
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Sınıfa tıklandığında o sınıftaki öğrencileri listeleyen widget
  Widget _buildStudentListOfClass(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('class', isEqualTo: classId)
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator());
        }
        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
          return const ListTile(title: Text('Bu sınıfta öğrenci bulunmuyor.'));
        }

        final students = studentSnapshot.data!.docs;

        return Column(
          children: students.map((doc) {
            final student = AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('${student.name} ${student.surname}'),
              subtitle: Text('Okul No: ${student.schoolNumber ?? 'N/A'}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Öğrenciye tıklandığında YENİ atama sayfasına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComputerSchedulePage(student: student),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}