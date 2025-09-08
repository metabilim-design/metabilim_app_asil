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

  // Değişiklikleri geçici olarak tutacak listeler
  List<DocumentSnapshot> _studentsInClass = [];
  List<DocumentSnapshot> _unassignedStudents = [];

  // Sayfa ilk açıldığında sınıftaki öğrencilerin ID'lerini sakla
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

  // GÜNCELLENDİ: Sayfa açıldığında tüm ilgili öğrencileri bir kere yükler
  Future<void> _loadAllStudents() async {
    setState(() => _isLoading = true);
    // 1. Adım: Bu sınıfa ait öğrencileri çek
    final classSnapshot = await _firestore.collection('users').where('class', isEqualTo: widget.classId).get();

    // 2. Adım: Hiçbir sınıfı olmayan (gerçekten boştaki) öğrencileri çek
    // Bu sorgu, bir öğrencinin başka bir sınıftaysa burada görünmesini engeller.
    final unassignedSnapshot = await _firestore.collection('users').where('class', isEqualTo: null).where('role', isEqualTo: 'Ogrenci').get();

    if (mounted) {
      setState(() {
        _studentsInClass = classSnapshot.docs;
        _unassignedStudents = unassignedSnapshot.docs;
        // Başlangıç durumunu kaydet (kimlerin bu sınıfta olduğunu bilmek için)
        _initialStudentIdsInClass = classSnapshot.docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    }
  }

  // Bir öğrenciyi boştaki listesinden bu sınıfa taşır
  void _moveStudentToClass(DocumentSnapshot student) {
    setState(() {
      _unassignedStudents.remove(student);
      _studentsInClass.add(student);
      _hasChanges = true;
    });
  }

  // Bir öğrenciyi bu sınıftan boştaki listesine taşır
  void _moveStudentToUnassigned(DocumentSnapshot student) {
    setState(() {
      _studentsInClass.remove(student);
      _unassignedStudents.add(student);
      _hasChanges = true;
    });
  }

  // GÜNCELLENDİ: Tüm değişiklikleri akıllı bir şekilde tek seferde kaydeder
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final batch = _firestore.batch();
    final classRef = _firestore.collection('classes').doc(widget.classId);

    // Son durumdaki öğrenci ID listeleri
    final finalStudentIdsInClass = _studentsInClass.map((doc) => doc.id).toList();

    // Kimler eklendi, kimler çıkarıldı?
    final addedStudentIds = finalStudentIdsInClass.where((id) => !_initialStudentIdsInClass.contains(id)).toList();
    final removedStudentIds = _initialStudentIdsInClass.where((id) => !finalStudentIdsInClass.contains(id)).toList();

    // 1. Adım: Sınıfın 'students' listesini son haliyle güncelle
    batch.update(classRef, {'students': finalStudentIdsInClass});

    // 2. Adım: Sınıfa yeni eklenen her öğrencinin 'class' alanını bu sınıfın ID'si yap
    for (var studentId in addedStudentIds) {
      batch.update(_firestore.collection('users').doc(studentId), {'class': widget.classId});
    }

    // 3. Adım: Sınıftan çıkarılan her öğrencinin 'class' alanını null yap (boşa çıkar)
    for (var studentId in removedStudentIds) {
      batch.update(_firestore.collection('users').doc(studentId), {'class': null});
    }

    try {
      await batch.commit();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        // Değişiklikler kaydedildiği için sayfanın durumunu veritabanından yeniden yükle
        // Bu, en doğru ve en güncel hali görmemizi sağlar.
        await _loadAllStudents();
        setState(() {
          _hasChanges = false;
        });
      }
    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydederken bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
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
                  title: 'Boştaki Öğrenciler',
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