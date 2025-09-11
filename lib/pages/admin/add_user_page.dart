import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/auth_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controller'lar
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Ogrenci';
  bool _isLoading = false;

  // --- YENİ EKLENEN KISIM: VELİ EKLEME İÇİN ---
  List<DocumentSnapshot> _students = [];
  String? _selectedStudentId;
  bool _isFetchingStudents = true;
  // --- BİTTİ ---

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // --- YENİ FONKSİYON: Tüm öğrencileri çeker ---
  Future<void> _fetchStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .orderBy('name')
          .get();
      if (mounted) {
        setState(() {
          _students = snapshot.docs;
          _isFetchingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öğrenciler yüklenirken bir hata oluştu: $e')),
        );
      }
    }
  }
  // --- BİTTİ ---

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? result;
    // GÜNCELLENDİ: Veli rolü için yeni case eklendi
    switch (_selectedRole) {
      case 'Ogrenci':
        result = await _authService.registerStudent(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          number: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
        break;
      case 'Veli':
        result = await _authService.registerParent(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
          studentUid: _selectedStudentId, // Seçilen öğrencinin ID'si gönderiliyor
        );
        break;
      case 'Mentor':
        result = await _authService.registerMentor(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
        break;
      case 'Eğitim Koçu':
        result = await _authService.registerCoach(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı başarıyla eklendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Kullanıcı Ekle', style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Ogrenci', 'Veli', 'Mentor', 'Eğitim Koçu', 'Admin']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                      // Rol değiştiğinde öğrenci seçimini sıfırla
                      _selectedStudentId = null;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'İsim'),
              const SizedBox(height: 16),
              _buildTextField(_surnameController, 'Soyisim'),
              const SizedBox(height: 16),
              _buildTextField(
                  _identifierController, _selectedRole == 'Ogrenci' ? 'Okul Numarası' : 'Kullanıcı Adı'),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
                  validator: (v) => v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                  obscureText: true),

              // --- YENİ EKLENEN KISIM: VELİ İÇİN ÖĞRENCİ SEÇİMİ ---
              if (_selectedRole == 'Veli') ...[
                const SizedBox(height: 16),
                if (_isFetchingStudents)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    hint: const Text('İlişkili Öğrenciyi Seçin'),
                    isExpanded: true,
                    items: _students.map((DocumentSnapshot document) {
                      final data = document.data()! as Map<String, dynamic>;
                      final studentName = '${data['name'] ?? ''} ${data['surname'] ?? ''}';
                      return DropdownMenuItem<String>(
                        value: document.id,
                        child: Text(studentName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStudentId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Öğrenci', border: OutlineInputBorder()),
                    validator: (value) => value == null ? 'Lütfen bir öğrenci seçin.' : null,
                  ),
              ],
              // --- BİTTİ ---

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text('Kullanıcıyı Ekle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => v!.isEmpty ? 'Bu alan boş olamaz' : null,
    );
  }
}