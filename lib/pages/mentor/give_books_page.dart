import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiveBooksPage extends StatefulWidget {
  final List<dynamic> topics;
  final String materialType;

  const GiveBooksPage({
    super.key,
    required this.topics,
    required this.materialType,
  });

  @override
  State<GiveBooksPage> createState() => _GiveBooksPageState();
}

class _GiveBooksPageState extends State<GiveBooksPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controller'lar
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _lastPageController = TextEditingController();

  // State değişkenleri
  String? _selectedLevel;
  String? _selectedBookType;
  String? _selectedSubject;
  String? _selectedPublicationYear;
  int _difficultyRating = 3;

  // Listeler
  final List<String> _tytSubjects = ['Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'];
  final List<String> _aytSubjects = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'];
  final List<String> _publicationYears = List.generate(10, (index) => '${2016 + index}-${2017 + index}').reversed.toList();
  List<String> _currentSubjects = [];

  @override
  void initState() {
    super.initState();
    _currentSubjects = _tytSubjects;
    _selectedLevel = 'TYT';
    _selectedBookType = widget.materialType == 'Kitap' ? 'Soru Bankası' : 'Fasikül';
  }

  @override
  void dispose() {
    _publisherController.dispose();
    _lastPageController.dispose();
    super.dispose();
  }

  Future<void> _saveMaterialToFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    // Bu kontrol sayesinde aşağıdaki ! işaretlerini güvenle kullanabiliriz.
    if (_selectedLevel == null || _selectedBookType == null || _selectedPublicationYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm seçimleri yapın.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('books').add({
        'level': _selectedLevel!,
        'bookType': _selectedBookType!,
        'publicationYear': _selectedPublicationYear!,
        'subject': _selectedSubject!, // DÜZELTME BURADA
        'publisher': _publisherController.text.trim(),
        'difficulty': _difficultyRating,
        'lastPage': int.tryParse(_lastPageController.text.trim()) ?? 0,
        'topics': widget.topics,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.materialType} başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt sırasında bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.materialType} Bilgilerini Girin', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Seviye Seçin'),
              _buildChoiceList(['TYT', 'AYT'], _selectedLevel, (value) {
                setState(() {
                  _selectedLevel = value;
                  _selectedSubject = null;
                  _currentSubjects = value == 'TYT' ? _tytSubjects : _aytSubjects;
                });
              }),
              const SizedBox(height: 24),
              _buildSectionTitle('Materyal Türü'),
              _buildChoiceList(['Soru Bankası', 'Konu Anlatımı', 'Fasikül'], _selectedBookType, (value) {
                setState(() => _selectedBookType = value);
              }),
              const SizedBox(height: 24),
              _buildSectionTitle('Basım Yılı'),
              _buildChoiceList(_publicationYears, _selectedPublicationYear, (value) {
                setState(() => _selectedPublicationYear = value);
              }),
              const SizedBox(height: 24),
              _buildSectionTitle('Ders Seçin'),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Ders Seçiniz'),
                value: _selectedSubject,
                items: _currentSubjects.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
                validator: (value) => value == null ? 'Lütfen bir ders seçin.' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Yayınevi'),
              TextFormField(
                controller: _publisherController,
                decoration: _inputDecoration('Yayınevi Adı'),
                validator: (value) => value!.trim().isEmpty ? 'Lütfen yayınevi girin.' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Son Sayfa Numarası'),
              TextFormField(
                controller: _lastPageController,
                decoration: _inputDecoration('Kitabın/Fasikülün son sayfası'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value!.trim().isEmpty ? 'Lütfen son sayfayı girin.' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Zorluk Derecesi'),
              _buildRatingBar(),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveMaterialToFirebase,
                icon: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.done, color: Colors.white),
                label: Text('Onayla ve Bitir', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _difficultyRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _difficultyRating = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600));

  InputDecoration _inputDecoration(String hintText) => InputDecoration(
    hintText: hintText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );

  Widget _buildChoiceList(List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(option, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary)),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (bool selected) { if (selected) onChanged(option); },
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}