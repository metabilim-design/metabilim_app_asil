import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CoachDetailPage extends StatefulWidget {
  final String coachId;
  final String coachName;

  const CoachDetailPage({super.key, required this.coachId, required this.coachName});

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
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

  // Bir öğrenciye bu koçu atar
  Future<void> _assignCoachToStudent(String studentId) async {
    await _firestore.collection('users').doc(studentId).update({'coachUid': widget.coachId});
  }

  // Bir öğrencinin koç atamasını kaldırır
  Future<void> _removeCoachFromStudent(String studentId) async {
    await _firestore.collection('users').doc(studentId).update({'coachUid': null});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.coachName} Yönetimi', style: GoogleFonts.poppins()),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Koça Atanmış Öğrenciler
          Expanded(
            child: _buildStudentList(
              title: 'Atanmış Öğrenciler',
              stream: _firestore.collection('users').where('coachUid', isEqualTo: widget.coachId).snapshots(),
              onTap: _removeCoachFromStudent,
              icon: Icons.remove_circle_outline,
              iconColor: Colors.redAccent,
              showSearch: false,
            ),
          ),
          const VerticalDivider(width: 2),
          // Boştaki Öğrenciler (Henüz koçu olmayanlar)
          Expanded(
            child: _buildStudentList(
              title: 'Boştaki Öğrenciler',
              stream: _firestore.collection('users').where('coachUid', isEqualTo: null).where('role', isEqualTo: 'Ogrenci').snapshots(),
              onTap: _assignCoachToStudent,
              icon: Icons.add_circle_outline,
              iconColor: Colors.green,
              showSearch: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList({
    required String title,
    required Stream<QuerySnapshot> stream,
    required Future<void> Function(String) onTap,
    required IconData icon,
    required Color iconColor,
    required bool showSearch,
  }) {
    return Column(
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
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Öğrenci bulunmuyor.'));
              }

              var students = snapshot.data!.docs;

              if (showSearch && _searchQuery.isNotEmpty) {
                students = students.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = '${data['name']} ${data['surname']}'.toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final studentData = student.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('${studentData['name']} ${studentData['surname']}'),
                    subtitle: Text('No: ${studentData['number'] ?? 'N/A'}'),
                    trailing: IconButton(
                      icon: Icon(icon, color: iconColor),
                      onPressed: () => onTap(student.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}