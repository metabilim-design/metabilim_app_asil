import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/class_detail_page.dart';
import 'package:metabilim/services/firestore_service.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  void _showCreateClassDialog() {
    // ... Bu fonksiyonun içeriği aynı, dokunmuyoruz ...
  }

  // YENİ FONKSİYON: Bir sınıf için etüt şablonu seçme dialoğunu gösterir
  void _showAssignScheduleDialog(String classId, String currentTemplateId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Etüt Programı Ata", style: GoogleFonts.poppins()),
          content: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('schedule_templates').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final templates = snapshot.data!.docs;
              if (templates.isEmpty) return const Text("Önce Etüt Ayarları'ndan bir şablon oluşturun.");

              return Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final templateName = (template.data() as Map<String, dynamic>)['templateName'] ?? '';
                    final bool isSelected = template.id == currentTemplateId;

                    return RadioListTile<String>(
                      title: Text(templateName),
                      value: template.id,
                      groupValue: currentTemplateId,
                      onChanged: (String? newTemplateId) {
                        if (newTemplateId != null) {
                          _firestoreService.setActiveTimetableForClass(classId, newTemplateId);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Program aktif edildi!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('classes').orderBy('className').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // ... Hata ve boş liste kontrolü aynı ...

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final classData = classDoc.data() as Map<String, dynamic>;
              final studentList = classData['students'] as List<dynamic>? ?? [];
              final activeTemplateId = classData['activeTimetableId'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(classData['grade'] ?? '?'),
                  ),
                  title: Text(classData['className'] ?? 'İsimsiz Sınıf', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('${studentList.length} öğrenci'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // YENİ BUTON: Sınıfa program atamak için
                      IconButton(
                        icon: Icon(Icons.playlist_add_check_circle_outlined, color: Theme.of(context).primaryColor),
                        tooltip: 'Aktif Etüt Programını Seç',
                        onPressed: () => _showAssignScheduleDialog(classDoc.id, activeTemplateId),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailPage(classId: classDoc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog, // Bu fonksiyonun içeriği değişmedi
        label: const Text('Yeni Sınıf Aç'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}