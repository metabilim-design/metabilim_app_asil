import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metabilim/models/user_model.dart';
// YENİ: Bir sonraki adımı import ediyoruz
import 'package:metabilim/pages/coach/homework_flow/select_previous_schedule_page.dart';

class ContinueSelectStudentPage extends StatefulWidget {
  const ContinueSelectStudentPage({Key? key}) : super(key: key);

  @override
  _ContinueSelectStudentPageState createState() => _ContinueSelectStudentPageState();
}

class _ContinueSelectStudentPageState extends State<ContinueSelectStudentPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _allStudents = [];
  List<AppUser> _filteredStudents = [];
  AppUser? _selectedStudent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _loadStudents() async {
    final coachId = FirebaseAuth.instance.currentUser?.uid;
    if (coachId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Ogrenci')
          .where('coachUid', isEqualTo: coachId)
          .get();

      final students = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öğrenciler yüklenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final studentName = '${student.name} ${student.surname}'.toLowerCase();
        return studentName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devam Et - Öğrenci Seç'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Öğrenci Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? const Center(child: Text('Size atanmış öğrenci bulunamadı.'))
                : ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final isSelected = _selectedStudent?.uid == student.uid;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text('${student.name} ${student.surname}'),
                    subtitle: Text(student.classId ?? 'Sınıfı Yok'),
                    onTap: () {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedStudent == null
              ? null
              : () {
            // --- DEĞİŞİKLİK BURADA ---
            // Artık bir sonraki adım olan program seçme sayfasına yönlendiriyoruz.
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SelectPreviousSchedulePage(student: _selectedStudent!),
            ));
            // --- BİTTİ ---
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}