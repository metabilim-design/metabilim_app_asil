import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/edit_schedule_template_page.dart'; // Yeni oluşturacağımız sayfa

class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni program oluşturma dialoğunu gösterir
  void _showCreateProgramDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Program Oluştur", style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Program Adı (Örn: Yaz Programı)'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Program adı boş olamaz.' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final programName = nameController.text.trim();
                  // Yeni program şablonunu 'schedule_templates' koleksiyonuna ekle
                  await _firestore.collection('schedule_templates').add({
                    'programName': programName,
                    'createdAt': FieldValue.serverTimestamp(),
                    // Başlangıçta her gün için boş saat listeleri
                    'schedule': {
                      'Pazartesi': [], 'Salı': [], 'Çarşamba': [], 'Perşembe': [],
                      'Cuma': [], 'Cumartesi': [], 'Pazar': [],
                    },
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$programName" başarıyla oluşturuldu.'), backgroundColor: Colors.green),
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

  // Bir programı aktif program olarak ayarlar
  Future<void> _setActiveProgram(String templateId) async {
    await _firestore.collection('settings').doc('active_schedule').set({'activeTemplateId': templateId});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program başarıyla aktif edildi!'), backgroundColor: Colors.green),
    );
  }

  // Bir program şablonunu siler
  Future<void> _deleteProgram(String templateId, String programName) async {
    // Önce kullanıcıdan onay al
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programı Sil'),
        content: Text('"$programName" adlı programı kalıcı olarak silmek istediğinizden emin misiniz?'),
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
      body: StreamBuilder<DocumentSnapshot>(
        // Aktif programın ID'sini dinle
        stream: _firestore.collection('settings').doc('active_schedule').snapshots(),
        builder: (context, activeScheduleSnapshot) {
          final activeTemplateId = (activeScheduleSnapshot.data?.data() as Map<String, dynamic>?)?['activeTemplateId'];

          return StreamBuilder<QuerySnapshot>(
            // Tüm program şablonlarını dinle
            stream: _firestore.collection('schedule_templates').orderBy('createdAt').snapshots(),
            builder: (context, templatesSnapshot) {
              if (templatesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!templatesSnapshot.hasData || templatesSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Henüz oluşturulmuş bir program yok.'));
              }

              final templates = templatesSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final templateDoc = templates[index];
                  final templateData = templateDoc.data() as Map<String, dynamic>;
                  final programName = templateData['programName'] ?? 'İsimsiz Program';
                  final bool isActive = templateDoc.id == activeTemplateId;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: isActive ? Colors.green.shade50 : null,
                    elevation: isActive ? 4 : 2,
                    child: ListTile(
                      leading: Icon(isActive ? Icons.check_circle : Icons.calendar_today_outlined, color: isActive ? Colors.green : Colors.grey),
                      title: Text(programName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text(isActive ? 'Aktif Program' : 'Aktif Değil'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Düzenle', onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditScheduleTemplatePage(templateId: templateDoc.id, programName: programName))),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Sil', onPressed: () => _deleteProgram(templateDoc.id, programName)),
                        ],
                      ),
                      onTap: isActive ? null : () => _setActiveProgram(templateDoc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProgramDialog,
        label: const Text('Yeni Program Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}