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
  List<DocumentSnapshot> _coaches = [];
  String? _selectedCoachId;
  String? _selectedGrade;
  String? _selectedBranch;

  // Sabit Listeler
  final List<String> _gradeLevels = ['9', '10', '11', '12', 'Mezun'];
  final List<String> _branchLetters = List.generate(12, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _surnameController = TextEditingController(text: widget.userData['surname'] ?? '');
    _selectedRole = widget.userData['role'] ?? 'Ogrenci';
    _selectedCoachId = widget.userData['coachUid'];

    // Sınıf bilgisini ayrıştırma
    if (_selectedRole == 'Ogrenci') {
      _identifierController = TextEditingController(text: widget.userData['number'] ?? '');
      final className = widget.userData['class'] as String?;
      if (className != null && className.contains('-')) {
        final parts = className.split('-');
        _selectedGrade = parts[0];
        _selectedBranch = parts[1];
      }
    } else {
      _identifierController = TextEditingController(text: widget.userData['username'] ?? '');
    }

    _fetchCoaches();
  }

  Future<void> _fetchCoaches() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Eğitim Koçu').get();
    if (mounted) {
      setState(() => _coaches = snapshot.docs);
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

      if (_selectedRole == 'Ogrenci') {
        updatedData['number'] = _identifierController.text.trim();
        updatedData['class'] = '${_selectedGrade}-${_selectedBranch}';
        updatedData['coachUid'] = _selectedCoachId;
        updatedData['username'] = FieldValue.delete(); // Diğer rollere ait alanı sil
      } else {
        updatedData['username'] = _identifierController.text.trim();
        updatedData['number'] = FieldValue.delete();
        updatedData['class'] = FieldValue.delete();
        updatedData['coachUid'] = FieldValue.delete();
      }

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
    bool isStudent = _selectedRole == 'Ogrenci';

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
              // Rol değiştirme yeteneği korunuyor
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
                items: ['Ogrenci', 'Mentor', 'Eğitim Koçu', 'Veli', 'Admin'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedRole = newValue!),
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
                decoration: InputDecoration(labelText: isStudent ? 'Okul Numarası' : 'Kullanıcı Adı', border: const OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Bu alan boş olamaz' : null,
              ),

              if (isStudent) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        hint: const Text('Sınıf'),
                        items: _gradeLevels.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
                        onChanged: (value) => setState(() => _selectedGrade = value),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        validator: (v) => v == null ? 'Zorunlu' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        hint: const Text('Şube'),
                        items: _branchLetters.map((branch) => DropdownMenuItem(value: branch, child: Text(branch))).toList(),
                        onChanged: (value) => setState(() => _selectedBranch = value),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        validator: (v) => v == null ? 'Zorunlu' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCoachId,
                  hint: const Text('Eğitim Koçu Seçin'),
                  items: _coaches.map((doc) {
                    final coach = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text('${coach['name']} ${coach['surname']}'));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCoachId = value),
                  decoration: const InputDecoration(labelText: 'Eğitim Koçu', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Koç seçimi zorunludur' : null,
                ),
              ],

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