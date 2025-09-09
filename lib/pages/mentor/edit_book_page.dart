import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// YENİ MODEL: Konu, başlangıç ve bitiş sayfası için 3 ayrı controller
class TopicEditorController {
  final TextEditingController konuController;
  final TextEditingController startPageController;
  final TextEditingController endPageController;

  TopicEditorController({String konu = '', String startPage = '', String endPage = ''})
      : konuController = TextEditingController(text: konu),
        startPageController = TextEditingController(text: startPage),
        endPageController = TextEditingController(text: endPage);

  void dispose() {
    konuController.dispose();
    startPageController.dispose();
    endPageController.dispose();
  }

  // YENİ KAYIT FORMATI
  Map<String, dynamic> toMap() {
    return {
      'konu': konuController.text.trim(),
      'start_page': int.tryParse(startPageController.text.trim()) ?? 0,
      'end_page': int.tryParse(endPageController.text.trim()) ?? 0,
    };
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
  late List<TopicEditorController> _topicControllers;
  bool _isLoading = false;

  // Temel bilgileri de düzenlemek için controller'lar
  late TextEditingController _bookNameController;
  late TextEditingController _publisherController;
  // Diğer temel bilgiler için de değişkenler eklenebilir...

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Temel bilgileri doldur
    _bookNameController = TextEditingController(text: widget.bookData['bookType'] ?? '');
    _publisherController = TextEditingController(text: widget.bookData['publisher'] ?? '');

    // Konuları YENİ FORMATA göre oku
    final topicsList = List<Map<String, dynamic>>.from(widget.bookData['topics'] ?? []);
    _topicControllers = topicsList.map((topic) {
      return TopicEditorController(
        konu: topic['konu']?.toString() ?? '',
        startPage: topic['start_page']?.toString() ?? '', // alt çizgili
        endPage: topic['end_page']?.toString() ?? '',     // alt çizgili
      );
    }).toList();
  }

  @override
  void dispose() {
    _bookNameController.dispose();
    _publisherController.dispose();
    for (var controller in _topicControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> updatedTopics = _topicControllers.map((controller) => controller.toMap()).toList();

    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({
        'bookType': _bookNameController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'topics': updatedTopics, // YENİ FORMATTA KAYDET
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Bir önceki sayfaya 'güncellendi' bilgisiyle dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTopic() {
    setState(() => _topicControllers.add(TopicEditorController()));
  }

  void _removeTopic(int index) {
    setState(() {
      _topicControllers[index].dispose();
      _topicControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitabı Düzenle', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Temel Bilgiler', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bookNameController,
            decoration: InputDecoration(labelText: 'Kitap Türü', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _publisherController,
            decoration: InputDecoration(labelText: 'Yayınevi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const Divider(height: 32, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('İçindekiler', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: _addTopic, tooltip: 'Yeni Konu Ekle'),
            ],
          ),
          ..._buildTopicsList(),
        ],
      ),
    );
  }

  // YENİ FORMATA UYGUN WIDGET
  List<Widget> _buildTopicsList() {
    return List.generate(_topicControllers.length, (index) {
      final controller = _topicControllers[index];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.konuController,
                      decoration: InputDecoration(labelText: 'Konu Adı ${index + 1}'),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeTopic(index))
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.startPageController,
                      decoration: const InputDecoration(labelText: 'Baş. Sayfa'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.endPageController,
                      decoration: const InputDecoration(labelText: 'Bitiş Sayfa'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}