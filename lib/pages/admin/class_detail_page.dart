// lib/pages/admin/class_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<DocumentSnapshot> _studentsInClass = [];
  List<DocumentSnapshot> _unassignedStudents = [];
  List<String> _initialStudentIdsInClass = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ### HATA BURADAYDI, DÜZELTİLDİ ###
  // Artık iki ayrı sorgu yerine tüm öğrenciler tek seferde çekilip uygulama içinde ayrıştırılıyor.
  // Bu, veri tutarlılığını garanti altına alıyor.
  Future<void> _loadAllStudents() async {
    setState(() => _isLoading = true);

    // 1. Adım: Tüm öğrencileri çek
    final allStudentsSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'Ogrenci').get();

    final List<DocumentSnapshot> inClass = [];
    final List<DocumentSnapshot> notInClass = [];

    // 2. Adım: Öğrencileri bu sınıfta olanlar ve olmayanlar olarak ayır
    for (var doc in allStudentsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['class'] == widget.classId) {
        inClass.add(doc);
      } else {
        notInClass.add(doc);
      }
    }

    if (mounted) {
      setState(() {
        _studentsInClass = inClass;
        _unassignedStudents = notInClass;
        _initialStudentIdsInClass = inClass.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    }
  }

  void _moveStudentToClass(DocumentSnapshot student) {
    setState(() {
      _unassignedStudents.remove(student);
      _studentsInClass.add(student);
      _hasChanges = true;
    });
  }

  void _moveStudentToUnassigned(DocumentSnapshot student) {
    setState(() {
      _studentsInClass.remove(student);
      _unassignedStudents.add(student);
      _hasChanges = true;
    });
  }

  // GÜNCELLENDİ: Bu fonksiyon artık bir öğrenciyi başka bir sınıftan alırken
  // o sınıfın 'students' listesini de güncelliyor.
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final batch = _firestore.batch();
    final classRef = _firestore.collection('classes').doc(widget.classId);

    final finalStudentIdsInClass = _studentsInClass.map((doc) => doc.id).toList();
    final addedStudents = _studentsInClass.where((doc) => !_initialStudentIdsInClass.contains(doc.id)).toList();
    final removedStudentIds = _initialStudentIdsInClass.where((id) => !finalStudentIdsInClass.contains(id)).toList();

    // 1. Adım: Mevcut sınıfın 'students' listesini son haliyle güncelle
    batch.update(classRef, {'students': finalStudentIdsInClass});

    // 2. Adım: Yeni eklenen öğrencilerin 'class' alanını güncelle ve eski sınıflarından çıkar
    for (var studentDoc in addedStudents) {
      final studentData = studentDoc.data() as Map<String, dynamic>;
      final oldClassId = studentData['class'] as String?;

      // Öğrencinin 'class' alanını bu sınıfın ID'si yap
      batch.update(_firestore.collection('users').doc(studentDoc.id), {'class': widget.classId});

      // Eğer öğrenci daha önce başka bir sınıftaysa, o sınıfın 'students' listesinden çıkar
      if (oldClassId != null && oldClassId.isNotEmpty) {
        batch.update(_firestore.collection('classes').doc(oldClassId), {
          'students': FieldValue.arrayRemove([studentDoc.id])
        });
      }
    }

    // 3. Adım: Sınıftan çıkarılan öğrencilerin 'class' alanını null yap (boşa çıkar)
    for (var studentId in removedStudentIds) {
      batch.update(_firestore.collection('users').doc(studentId), {'class': null});
    }

    try {
      await batch.commit();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        await _loadAllStudents();
        setState(() => _hasChanges = false);
      }
    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydederken bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUnassignedStudents = _unassignedStudents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = '${data['name']} ${data['surname']}'.toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.classId} Sınıfı Yönetimi', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_hasChanges)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Yaptığınız değişiklikleri kaydetmeyi unutmayın.',
                      style: GoogleFonts.poppins(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentList(
                  title: 'Sınıftaki Öğrenciler',
                  students: _studentsInClass,
                  onTap: _moveStudentToUnassigned,
                  icon: Icons.remove_circle_outline,
                  iconColor: Colors.redAccent,
                  showSearch: false,
                ),
                const VerticalDivider(width: 2),
                _buildStudentList(
                  title: 'Diğer Öğrenciler',
                  students: filteredUnassignedStudents,
                  onTap: _moveStudentToClass,
                  icon: Icons.add_circle_outline,
                  iconColor: Colors.green,
                  showSearch: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveChanges,
        label: const Text('Değişiklikleri Kaydet'),
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save),
      )
          : null,
    );
  }

  Widget _buildStudentList({
    required String title,
    required List<DocumentSnapshot> students,
    required void Function(DocumentSnapshot) onTap,
    required IconData icon,
    required Color iconColor,
    required bool showSearch,
  }) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Öğrenci ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('Öğrenci bulunmuyor.'))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final studentData = student.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text('${studentData['name']} ${studentData['surname']}'),
                  subtitle: Text('No: ${studentData['number'] ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: Icon(icon, color: iconColor),
                    onPressed: () => onTap(student),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}