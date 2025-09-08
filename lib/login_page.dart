import 'package:flutter/material.dart';
import 'package:metabilim/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Gerekli Shell (Ana İskelet) sayfalarını import ediyoruz
import 'package:metabilim/student_shell.dart';
import 'package:metabilim/mentor_shell.dart';
import 'package:metabilim/admin_shell.dart';
import 'package:metabilim/egitim_kocu_shell.dart';
import 'package:metabilim/veli_shell.dart'; // Veli için oluşturulan shell

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Ogrenci';
  bool _isLoading = false;

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      var result = await _authService.signIn(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        _showFeedback('${result['role']} olarak giriş yapıldı.');

        // GÜNCELLENDİ: Tüm roller için yönlendirme mevcut
        switch (result['role']) {
          case 'Ogrenci':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentShell()));
            break;
          case 'Mentor':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MentorShell()));
            break;
          case 'Admin':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  AdminShell()));
            break;
          case 'Eğitim Koçu':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EgitimKocuShell()));
            break;
          case 'Veli':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VeliShell()));
            break;
        }
      } else {
        _showFeedback(result['message'], isError: true);
      }
    }
  }

  // GÜNCELLENDİ: Tüm roller için etiketler
  String getIdentifierLabel() {
    switch (_selectedRole) {
      case 'Ogrenci': return 'Okul Numarası';
      case 'Mentor': return 'Kullanıcı Adı';
      case 'Eğitim Koçu': return 'Kullanıcı Adı';
      case 'Veli': return 'Kullanıcı Adı';
      case 'Admin': return 'Admin Kullanıcı Adı';
      default: return 'Kimlik';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/image_0d0f89.png', height: 120),
                    const SizedBox(height: 50),
                    // GÜNCELLENDİ: Tüm roller dropdown'a eklendi
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Giriş Tipi', border: OutlineInputBorder()),
                      items: ['Ogrenci', 'Veli', 'Mentor', 'Eğitim Koçu', 'Admin'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedRole = newValue!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _identifierController,
                      decoration: InputDecoration(labelText: getIdentifierLabel(), border: const OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Şifre boş olamaz' : null,
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _login,
                      child: Text('Giriş Yap', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}