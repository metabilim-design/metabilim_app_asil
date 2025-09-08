import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;

  // YENİ: Eski şifre için de controller ekledik
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String _name = '';
  String _surname = '';
  String _username = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // ... (Bu fonksiyon aynı kalıyor)
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _name = userData.get('name') ?? '';
          _surname = userData.get('surname') ?? '';
          _username = userData.get('username') ?? '';
          _email = userData.get('email') ?? '';
          _isLoading = false;
        });
      }
    }
  }

  // GÜNCELLENDİ: Şifre değiştirme mantığı
  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showFeedback("Yeni şifreler eşleşmiyor.", isError: true);
        return;
      }

      setState(() => _isLoading = true);
      String? errorMessage = await _authService.changePassword(
        oldPassword: _oldPasswordController.text, // Eski şifreyi gönderiyoruz
        newPassword: _newPasswordController.text,
      );
      setState(() => _isLoading = false);

      if (errorMessage == null) {
        _showFeedback("Şifreniz başarıyla güncellendi.");
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        FocusScope.of(context).unfocus();
      } else {
        _showFeedback(errorMessage, isError: true);
      }
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    // ... (Bu fonksiyon aynı kalıyor)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profilim', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profil Bilgileri
            _buildInfoTile(Icons.person, 'İsim', '$_name $_surname'),
            _buildInfoTile(Icons.alternate_email, 'Kullanıcı Adı', _username),
            _buildInfoTile(Icons.email, 'Email', _email),

            const Divider(height: 40, thickness: 1),

            // Şifre Değiştirme Formu
            Text('Şifre Değiştir', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // YENİ: Eski şifre alanı eklendi
                  TextFormField(
                    controller: _oldPasswordController,
                    decoration: const InputDecoration(labelText: 'Mevcut Şifre', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (value) => (value?.length ?? 0) < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Şifreyi Güncelle', style: GoogleFonts.poppins()), // Buton metnini güncelledik
            ),

            const SizedBox(height: 40),
            // Çıkış Yap Butonu
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.logout),
              label: Text('Çıkış Yap', style: GoogleFonts.poppins()),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    // ... (Bu fonksiyon aynı kalıyor)
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}