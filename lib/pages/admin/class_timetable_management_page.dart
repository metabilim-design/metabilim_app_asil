import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/pages/admin/edit_class_timetable_page.dart';

class ClassTimetableManagementPage extends StatelessWidget {
  const ClassTimetableManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sınıf Etüt Programları", style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 'classes' koleksiyonundaki tüm sınıfları dinle
        stream: FirebaseFirestore.instance.collection('classes').orderBy('className').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Sınıflar yüklenirken bir hata oluştu."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Sisteme henüz sınıf eklenmemiş."));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final className = (classDoc.data() as Map<String, dynamic>)['className'] ?? 'İsimsiz Sınıf';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: Text(className, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.edit_calendar_outlined, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditClassTimetablePage(
                          classId: classDoc.id,
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
