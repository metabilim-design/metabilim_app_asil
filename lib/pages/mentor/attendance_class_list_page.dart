// lib/pages/mentor/attendance_class_list_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_timeslot_page.dart'; // Bir sonraki adımımız

class AttendanceClassListPage extends StatelessWidget {
  const AttendanceClassListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').orderBy('className').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Sınıflar yüklenirken bir hata oluştu.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sistemde kayıtlı sınıf bulunmuyor.'));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final classData = classDoc.data() as Map<String, dynamic>;
              final className = classData['className'] ?? 'İsimsiz Sınıf';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.class_outlined, size: 40),
                  title: Text(className, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Yoklama almak için sınıfı seçin'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => AttendanceTimeSlotPage(
                        classId: classDoc.id,
                        className: className,
                      ),
                    ));
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