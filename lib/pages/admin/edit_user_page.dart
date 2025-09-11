import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserPage({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controller'lar
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _identifierController;

  // State değişkenleri
  late String _selectedRole;
  bool _isLoading = false;

  // Sadece Veli için kullanılacak liste
  List<DocumentSnapshot> _students = [];
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _surnameController = TextEditingController(text: widget.userData['surname'] ?? '');
    _selectedRole = widget.userData['role'] ?? 'Ogrenci';
    _selectedStudentId = widget.userData['studentUid'];

    // Rol'e göre başlangıç kimlik bilgisini ayarla
    if (_selectedRole == 'Ogrenci') {
      _identifierController = TextEditingController(text: widget.userData['number'] ?? '');
    } else {
      _identifierController = TextEditingController(text: widget.userData['username'] ?? '');
    }

    // Sadece veli rolü için öğrencileri çek, gereksiz sorgu yapma
    if (_selectedRole == 'Veli') {
      _fetchStudents();
    }
  }

  Future<void> _fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').get();
    if (mounted) {
      setState(() => _students = snapshot.docs);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'role': _selectedRole,
      };

      // --- DEĞİŞİKLİK BURADA: MANTIK SADELEŞTİRİLDİ ---
      // Role göre kaydedilecek ve silinecek alanları yönet
      if (_selectedRole == 'Ogrenci') {
        updatedData['number'] = _identifierController.text.trim();
        // Öğrenci için alakasız alanları sil
        updatedData['username'] = FieldValue.delete();
        updatedData['studentUid'] = FieldValue.delete();
      } else if (_selectedRole == 'Veli') {
        updatedData['username'] = _identifierController.text.trim();
        updatedData['studentUid'] = _selectedStudentId;
        // Veli için alakasız alanları sil
        updatedData['number'] = FieldValue.delete();
        updatedData['class'] = FieldValue.delete();
        updatedData['coachUid'] = FieldValue.delete();
      } else { // Mentor, Koç, Admin
        updatedData['username'] = _identifierController.text.trim();
        // Bu roller için alakasız alanları sil
        updatedData['number'] = FieldValue.delete();
        updatedData['class'] = FieldValue.delete();
        updatedData['coachUid'] = FieldValue.delete();
        updatedData['studentUid'] = FieldValue.delete();
      }
      // --- BİTTİ ---

      await _firestore.collection('users').doc(widget.userId).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı bilgileri güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcıyı Düzenle', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rol değiştirme hala aktif
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
                items: ['Ogrenci', 'Veli', 'Mentor', 'Eğitim Koçu', 'Admin'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                      if (newValue == 'Veli' && _students.isEmpty) {
                        _fetchStudents();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'İsim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Soyisim', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Soyisim boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(labelText: _selectedRole == 'Ogrenci' ? 'Okul Numarası' : 'Kullanıcı Adı', border: const OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
              ),

              // --- DEĞİŞİKLİK BURADA: ÖĞRENCİ İÇİN SINIF VE KOÇ SORULARI KALDIRILDI ---
              if (_selectedRole == 'Veli') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  hint: const Text('İlişkili Öğrenciyi Seçin'),
                  isExpanded: true,
                  items: _students.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('${data['name']} ${data['surname']}'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedStudentId = value),
                  decoration: const InputDecoration(labelText: 'Öğrenci', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Lütfen bir öğrenci seçin.' : null,
                ),
              ],
              // --- BİTTİ ---

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _updateUser,
                icon: const Icon(Icons.save_outlined),
                label: Text('Değişiklikleri Kaydet', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}