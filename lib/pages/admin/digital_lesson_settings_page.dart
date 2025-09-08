import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/admin/computer_schedule_page.dart'; // Yeni oluşturacağımız sayfa

class DigitalLessonSettingsPage extends StatefulWidget {
  const DigitalLessonSettingsPage({super.key});

  @override
  State<DigitalLessonSettingsPage> createState() => _DigitalLessonSettingsPageState();
}

class _DigitalLessonSettingsPageState extends State<DigitalLessonSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddComputerDialog() {
    final computerNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Bilgisayar Ekle", style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: computerNameController,
              decoration: const InputDecoration(labelText: 'Bilgisayar Adı (Örn: Bilgisayar 1)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bilgisayar adı boş olamaz.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = computerNameController.text.trim();
                  // Yeni bilgisayarı 'computers' koleksiyonuna ekle
                  await _firestore.collection('computers').add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
                  // Aynı anda bu bilgisayar için boş bir dijital program belgesi oluştur
                  await _firestore.collection('digital_schedules').doc(name).set({'computerName': name});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$name" başarıyla eklendi.'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Ekle'),
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
        stream: _firestore.collection('computers').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sistemde kayıtlı bilgisayar yok.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bilgisayarlar yüklenemedi.'));
          }

          final computers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: computers.length,
            itemBuilder: (context, index) {
              final computerDoc = computers[index];
              final computerData = computerDoc.data() as Map<String, dynamic>;
              final computerName = computerData['name'] ?? 'İsimsiz';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.computer, size: 40),
                  title: Text(computerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Haftalık programı düzenlemek için dokunun'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Bilgisayarın adını (ID'si olarak kullanıyoruz) detay sayfasına gönder
                        builder: (context) => ComputerSchedulePage(computerId: computerDoc.id, computerName: computerName),
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
        onPressed: _showAddComputerDialog,
        label: const Text('Yeni Bilgisayar Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}