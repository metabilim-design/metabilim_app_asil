// lib/pages/admin/computer_management_page.dart - YENİ DOSYA

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ComputerManagementPage extends StatefulWidget {
  const ComputerManagementPage({super.key});

  @override
  State<ComputerManagementPage> createState() => _ComputerManagementPageState();
}

class _ComputerManagementPageState extends State<ComputerManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _computerNameController = TextEditingController();

  void _showAddComputerDialog() {
    _computerNameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Bilgisayar Ekle", style: GoogleFonts.poppins()),
          content: TextField(
            controller: _computerNameController,
            decoration: const InputDecoration(
              labelText: "Bilgisayar Adı (Örn: PC-10)",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Ekle"),
              onPressed: () async {
                final computerName = _computerNameController.text.trim().toUpperCase();
                if (computerName.isNotEmpty) {
                  final existing = await _firestore
                      .collection('computers')
                      .where('name', isEqualTo: computerName)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$computerName" adında bir bilgisayar zaten mevcut.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    await _firestore.collection('computers').add({
                      'name': computerName,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$computerName" başarıyla eklendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String docId, String computerName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Silmeyi Onayla", style: GoogleFonts.poppins()),
          content: Text('"$computerName" adlı bilgisayarı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Sil"),
              onPressed: () async {
                await _firestore.collection('computers').doc(docId).delete();
                // İlgili dijital schedule'ı da sil
                await _firestore.collection('digital_schedules').doc(computerName).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$computerName" ve programı silindi.')),
                );
              },
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
        stream: _firestore.collection('computers').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Bir hata oluştu."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Henüz hiç bilgisayar eklenmemiş.\nEklemek için '+' butonuna tıklayın.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final computers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: computers.length,
            itemBuilder: (context, index) {
              final computer = computers[index];
              final computerName = computer['name'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.computer),
                  title: Text(computerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(computer.id, computerName),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddComputerDialog,
        child: const Icon(Icons.add),
        tooltip: "Yeni Bilgisayar Ekle",
      ),
    );
  }
}