import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/class_roster_page.dart';
import 'package:metabilim/pages/mentor/study_schedule_view_page.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

// Hangi görünümün aktif olduğunu tutan enum
enum MentorView { classView, studyView }

class _StudentListPageState extends State<StudentListPage> {
  MentorView _currentView = MentorView.classView;

  // Admin panelinde tanımlı olan sınıf seviyeleri ve şubeler
  final List<String> _gradeLevels = ['9', '10', '11', '12', 'Mezun'];
  final List<String> _branchLetters = List.generate(12, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));

  @override
  Widget build(BuildContext context) {
    // Tüm olası sınıf adlarını oluşturuyoruz (örn: "9-A", "9-B"...)
    final List<String> allPossibleClasses = [];
    for (var grade in _gradeLevels) {
      for (var branch in _branchLetters) {
        allPossibleClasses.add('$grade-$branch');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentView == MentorView.classView ? 'Sınıf Listesi' : 'Etüt Programı', style: GoogleFonts.poppins()),
        centerTitle: true,
        // Görünümler arası geçiş butonu
        actions: [
          IconButton(
            icon: Icon(_currentView == MentorView.classView ? Icons.access_time_filled_outlined : Icons.class_outlined),
            tooltip: _currentView == MentorView.classView ? 'Etüt Görünümüne Geç' : 'Sınıf Görünümüne Geç',
            onPressed: () {
              setState(() {
                _currentView = _currentView == MentorView.classView ? MentorView.studyView : MentorView.classView;
              });
            },
          ),
        ],
      ),
      // Aktif görünüme göre ilgili sayfayı göster
      body: _currentView == MentorView.classView
          ? _buildClassView(allPossibleClasses)
          : const StudyScheduleViewPage(), // Yeni Etüt Görünümü sayfası
    );
  }

  // Sınıf Görünümünü oluşturan widget
  Widget _buildClassView(List<String> classList) {
    return StreamBuilder<QuerySnapshot>(
      // Tüm öğrencileri bir kere çekip sınıflara göre gruplayacağız
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Öğrenciler yüklenemedi.'));
        }

        // Öğrencileri sınıflarına göre bir haritada grupla
        final studentCountByClass = <String, int>{};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            // DÜZELTME: Veriyi güvenli bir şekilde okuyoruz
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('class')) {
              final studentClass = data['class'] as String?;
              if (studentClass != null) {
                studentCountByClass[studentClass] = (studentCountByClass[studentClass] ?? 0) + 1;
              }
            }
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: classList.length,
          itemBuilder: (context, index) {
            final className = classList[index];
            final studentCount = studentCountByClass[className] ?? 0;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(className.split('-')[0], style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text('$className Sınıfı', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('$studentCount öğrenci kayıtlı'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Sınıfa tıklandığında, o sınıftaki öğrencileri gösteren yeni sayfaya git
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ClassRosterPage(className: className),
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }
}