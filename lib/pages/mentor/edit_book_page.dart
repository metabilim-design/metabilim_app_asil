import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Her bir konu satırının controller'larını tutmak için yardımcı bir sınıf
class TopicEditorController {
  final TextEditingController konuController;
  final TextEditingController sayfaController;

  TopicEditorController({required String konu, required String sayfa})
      : konuController = TextEditingController(text: konu),
        sayfaController = TextEditingController(text: sayfa);

  // Bellek sızıntılarını önlemek için
  void dispose() {
    konuController.dispose();
    sayfaController.dispose();
  }
}

class EditBookPage extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const EditBookPage({
    super.key,
    required this.bookId,
    required this.bookData,
  });

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  // Her bir konu/sayfa çifti için controller listesi
  late List<TopicEditorController> _topicControllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Firestore'dan gelen 'topics' listesini al
    final topicsList = List<Map<String, dynamic>>.from(widget.bookData['topics'] ?? []);
    _topicControllers = topicsList.map((topic) {
      return TopicEditorController(
        konu: topic['konu']?.toString() ?? '',
        sayfa: topic['sayfa']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  void dispose() {
    // Tüm controller'ları temizle
    for (var controller in _topicControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Değişiklikleri Firebase'e kaydetme fonksiyonu
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    // Controller'lardaki güncel verilerden yeni bir 'topics' listesi oluştur
    List<Map<String, String>> updatedTopics = _topicControllers.map((controller) {
      return {
        'konu': controller.konuController.text.trim(),
        'sayfa': controller.sayfaController.text.trim(),
      };
    }).toList();

    // Kaydetmeden önce listeyi sayfa numarasına göre sırala
    updatedTopics.sort((a, b) {
      final pageA = int.tryParse(a['sayfa'] ?? '0') ?? 9999;
      final pageB = int.tryParse(b['sayfa'] ?? '0') ?? 9999;
      return pageA.compareTo(pageB);
    });

    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({
        'topics': updatedTopics, // Güncellenmiş ve sıralanmış listeyi kaydet
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konuları Düzenle', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${widget.bookData['subject']} - ${widget.bookData['publisher']}',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _topicControllers.length,
              itemBuilder: (context, index) {
                final controller = _topicControllers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Konu için metin alanı
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: controller.konuController,
                            decoration: InputDecoration(
                              labelText: 'Konu ${index + 1}',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sayfa için metin alanı
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: controller.sayfaController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Sayfa',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}