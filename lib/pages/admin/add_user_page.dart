import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // GÜNCELLENDİ: Farklı roller için kayıt mantığı
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
      // Veli ekleme şimdilik buradan kaldırıldı, daha sonra eklenebilir.
        result = "Veli ekleme işlemi yönetim paneline taşınacaktır.";
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

    if(mounted) {
      setState(() => _isLoading = false);
      if(result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı başarıyla eklendi!'), backgroundColor: Colors.green));
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
                items: ['Ogrenci', 'Mentor', 'Eğitim Koçu', 'Admin']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  if(value != null) setState(() => _selectedRole = value);
                },
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'İsim'),
              const SizedBox(height: 16),
              _buildTextField(_surnameController, 'Soyisim'),
              const SizedBox(height: 16),
              _buildTextField(_identifierController, _selectedRole == 'Ogrenci' ? 'Okul Numarası' : 'Kullanıcı Adı'),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()), validator: (v) => v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null, obscureText: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
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