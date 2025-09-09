import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:metabilim/pages/mentor/confirm_upload_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/pages/mentor/edit_book_page.dart';
import 'package:metabilim/pages/mentor/give_practices_page.dart';
import 'package:metabilim/pages/mentor/edit_practice_page.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final ImagePicker _picker = ImagePicker();

  Stream<List<DocumentSnapshot>> _createCombinedStream() {
    final booksStream = FirebaseFirestore.instance.collection('books').snapshots();
    final practicesStream = FirebaseFirestore.instance.collection('practices').snapshots();

    return Rx.combineLatest2(
      booksStream,
      practicesStream,
          (QuerySnapshot booksSnapshot, QuerySnapshot practicesSnapshot) {
        final List<DocumentSnapshot> allDocs = [...booksSnapshot.docs, ...practicesSnapshot.docs];
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final Timestamp tsA = aData['createdAt'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          final Timestamp tsB = bData['createdAt'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          return tsB.compareTo(tsA);
        });
        return allDocs;
      },
    );
  }

  Future<void> _pickImagesAndStartProcess(String materialType) async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty && mounted) {
      final List<File> imageFiles = pickedFiles.map((file) => File(file.path)).toList();
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ConfirmUploadPage(
          imageFiles: imageFiles,
          materialType: materialType,
        ),
      ));
    }
  }

  void _navigateToAddPractice() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const GivePracticesPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materyaller', style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _createCombinedStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veriler yüklenirken bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz eklenmiş bir materyaliniz yok.'));
          }
          final combinedItems = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: combinedItems.length,
            itemBuilder: (context, index) {
              final item = combinedItems[index];
              final data = item.data() as Map<String, dynamic>;
              final isBook = data.containsKey('bookType');
              if (isBook) {
                return _buildBookTile(item);
              } else {
                return _buildPracticeTile(item);
              }
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.note_alt_outlined),
            label: 'Deneme Ekle',
            labelStyle: GoogleFonts.poppins(),
            onTap: _navigateToAddPractice,
          ),
          SpeedDialChild(
            child: const Icon(Icons.auto_stories_outlined),
            label: 'Fasikül Ekle',
            labelStyle: GoogleFonts.poppins(),
            onTap: () => _pickImagesAndStartProcess('Fasikül'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.menu_book_outlined),
            label: 'Kitap Ekle',
            labelStyle: GoogleFonts.poppins(),
            onTap: () => _pickImagesAndStartProcess('Kitap'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTile(DocumentSnapshot doc) {
    final book = doc.data() as Map<String, dynamic>;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: Colors.blueGrey),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text('${book['subject']} - ${book['publisher']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text('Tür: ${book['bookType']}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditBookPage(bookId: doc.id, bookData: book))),
      ),
    );
  }

  Widget _buildPracticeTile(DocumentSnapshot doc) {
    final practice = doc.data() as Map<String, dynamic>;
    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.note_alt, color: Colors.teal),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text('${practice['subject']} - ${practice['publisher']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text('Adet: ${practice['count']}', style: GoogleFonts.poppins(color: Colors.grey[700])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditPracticePage(practiceId: doc.id, practiceData: practice))),
      ),
    );
  }
}