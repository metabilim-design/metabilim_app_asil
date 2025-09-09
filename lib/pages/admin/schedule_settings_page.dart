import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/edit_schedule_template_page.dart';
import 'package:metabilim/services/firestore_service.dart';

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  void _showCreateProgramDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Etüt Şablonu Oluştur", style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Şablon Adı (Örn: Yaz Programı)'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Ad boş olamaz.' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final templateName = nameController.text.trim();
                  await _firestoreService.createScheduleTemplate(templateName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$templateName" başarıyla oluşturuldu.'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProgram(String templateId, String programName) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şablonu Sil'),
        content: Text('"$programName" adlı şablonu kalıcı olarak silmek istediğinizden emin misiniz? Bu şablonu kullanan sınıfların programı boş olacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('schedule_templates').doc(templateId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$programName" silindi.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('schedule_templates').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz oluşturulmuş bir etüt şablonu yok.'));
          }

          final templates = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final templateDoc = templates[index];
              final templateData = templateDoc.data() as Map<String, dynamic>;
              final programName = templateData['templateName'] ?? 'İsimsiz Şablon';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(programName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Düzenle', onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditScheduleTemplatePage(templateId: templateDoc.id, programName: programName))),
                      ),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Sil', onPressed: () => _deleteProgram(templateDoc.id, programName)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProgramDialog,
        label: const Text('Yeni Şablon Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}