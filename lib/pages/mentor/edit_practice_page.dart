import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPracticePage extends StatefulWidget {
  final String practiceId;
  final Map<String, dynamic> practiceData;

  const EditPracticePage({
    super.key,
    required this.practiceId,
    required this.practiceData,
  });

  @override
  State<EditPracticePage> createState() => _EditPracticePageState();
}

class _EditPracticePageState extends State<EditPracticePage> {
  // Seçimler için değişkenler
  late String? _selectedLevel;
  late String? _selectedSubject;
  late String? _selectedPublicationYear;
  late TextEditingController _publisherController;
  late TextEditingController _countController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Listeler
  final List<String> _tytSubjects = ['Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'];
  final List<String> _aytSubjects = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'];
  final List<String> _publicationYears = List.generate(10, (index) => '${2016 + index}-${2017 + index}').reversed.toList();
  List<String> _currentSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.practiceData['level'];
    _selectedPublicationYear = widget.practiceData['publicationYear'];
    _selectedSubject = widget.practiceData['subject'];
    _publisherController = TextEditingController(text: widget.practiceData['publisher'] ?? '');
    _countController = TextEditingController(text: (widget.practiceData['count'] ?? 0).toString());

    if (_selectedLevel == 'TYT') {
      _currentSubjects = _tytSubjects;
    } else if (_selectedLevel == 'AYT') {
      _currentSubjects = _aytSubjects;
    }
  }

  @override
  void dispose() {
    _publisherController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('practices')
          .doc(widget.practiceId)
          .update({
        'level': _selectedLevel,
        'publicationYear': _selectedPublicationYear,
        'subject': _selectedSubject,
        'publisher': _publisherController.text.trim(),
        'count': int.tryParse(_countController.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deneme başarıyla güncellendi!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Güncelleme sırasında hata oluştu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deneme Bilgilerini Düzenle', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
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
                  if (value == 'TYT') _currentSubjects = _tytSubjects;
                  else _currentSubjects = _aytSubjects;
                });
              }),
              const SizedBox(height: 24),
              _buildSectionTitle('Basım Yılı Seçin'),
              _buildChoiceList(_publicationYears, _selectedPublicationYear, (value) => setState(() => _selectedPublicationYear = value)),
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
                validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen yayınevi bilgisini girin.' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Deneme Adedi'),
              TextFormField(
                controller: _countController,
                decoration: _inputDecoration('İçindeki deneme sayısı'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen adedi girin.' : null,
              ),
              const SizedBox(height: 40),
              // GÜNCELLEME BURADA
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.primary, // Arka plan rengi eklendi
                ),
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.done, color: Colors.white),
                label: Text('Değişiklikleri Kaydet', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600));

  InputDecoration _inputDecoration(String hintText) => InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.poppins(),
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