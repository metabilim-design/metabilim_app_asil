import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/class_detail_page.dart'; // Yeni oluşturacağımız sayfa

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni sınıf oluşturma dialoğunu gösterir
  void _showCreateClassDialog() {
    final _formKey = GlobalKey<FormState>();
    String? selectedGrade;
    String? selectedBranch;

    final List<String> gradeLevels = ['9', '10', '11', '12', 'Mezun'];
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
                  decoration: const InputDecoration(labelText: 'Sınıf Düzeyi', border: OutlineInputBorder()),
                  items: gradeLevels.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
                  onChanged: (value) => selectedGrade = value,
                  validator: (value) => value == null ? 'Lütfen seçim yapın' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Şube', border: OutlineInputBorder()),
                  items: branchLetters.map((branch) => DropdownMenuItem(value: branch, child: Text(branch))).toList(),
                  onChanged: (value) => selectedBranch = value,
                  validator: (value) => value == null ? 'Lütfen seçim yapın' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final className = '$selectedGrade-$selectedBranch';
                  // Aynı isimde bir sınıf olup olmadığını kontrol et
                  final doc = await _firestore.collection('classes').doc(className).get();
                  if (doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$className zaten mevcut!'), backgroundColor: Colors.red),
                    );
                  } else {
                    await _firestore.collection('classes').doc(className).set({
                      'className': className,
                      'grade': selectedGrade,
                      'branch': selectedBranch,
                      'students': [], // Başlangıçta boş öğrenci listesi
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$className başarıyla oluşturuldu!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('classes').orderBy('className').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz oluşturulmuş bir sınıf yok.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Sınıflar yüklenemedi.'));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classDoc = classes[index];
              final classData = classDoc.data() as Map<String, dynamic>;
              final studentList = classData['students'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(classData['grade'] ?? '?'),
                  ),
                  title: Text(classData['className'] ?? 'İsimsiz Sınıf', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('${studentList.length} öğrenci'),
                  trailing: const Icon(Icons.arrow_forward_ios),
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