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

  // ### HATA BURADAYDI, FONKSİYONUN İÇİ BOŞTU. ŞİMDİ DOLDURULDU. ###
  void _showCreateClassDialog() {
    final _formKey = GlobalKey<FormState>();
    String? selectedGrade;
    String? selectedBranch;

    final List<String> gradeLevels = ['9', '10', '11', '12', 'Mezun'];
    // A'dan L'ye kadar harf listesi oluşturur.
    final List<String> branchLetters = List.generate(12, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Sınıf Oluştur", style: GoogleFonts.poppins()),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sınıf Seviyesi'),
                  items: gradeLevels.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
                  onChanged: (value) => selectedGrade = value,
                  validator: (value) => value == null ? 'Lütfen seviye seçin.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Şube'),
                  items: branchLetters.map((branch) => DropdownMenuItem(value: branch, child: Text(branch))).toList(),
                  onChanged: (value) => selectedBranch = value,
                  validator: (value) => value == null ? 'Lütfen şube seçin.' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final className = '$selectedGrade-$selectedBranch';

                  // Aynı isimde sınıf var mı diye kontrol et
                  final existingClass = await _firestore.collection('classes').where('className', isEqualTo: className).limit(1).get();

                  if (existingClass.docs.isNotEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"$className" adında bir sınıf zaten mevcut.'), backgroundColor: Colors.red),
                      );
                    }
                    return;
                  }

                  // Yeni sınıfı Firestore'a ekle
                  await _firestore.collection('classes').add({
                    'className': className,
                    'grade': selectedGrade,
                    'branch': selectedBranch,
                    'students': [], // Başlangıçta boş öğrenci listesi
                    'activeTimetableId': null, // Başlangıçta aktif program yok
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$className" sınıfı başarıyla oluşturuldu.'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }
  // ### DÜZELTME BİTTİ ###


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

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final templateName = (template.data() as Map<String, dynamic>)['templateName'] ?? '';

                    return RadioListTile<String>(
                      title: Text(templateName),
                      value: template.id,
                      groupValue: currentTemplateId,
                      onChanged: (String? newTemplateId) {
                        if (newTemplateId != null) {
                          _firestoreService.setActiveTimetableForClass(classId, newTemplateId);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Program aktif edildi!'), backgroundColor: Colors.green),
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
          if (snapshot.hasError) {
            return const Center(child: Text("Bir hata oluştu."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Sistemde kayıtlı sınıf bulunmuyor."));
          }

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
        onPressed: _showCreateClassDialog,
        label: const Text('Yeni Sınıf Aç'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}