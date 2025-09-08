import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/student/dashboard_page.dart';
import 'package:metabilim/pages/student/homework_page.dart';
import 'package:metabilim/pages/student/exams_page.dart';
import 'package:metabilim/pages/student/attendance_page.dart';
import 'package:metabilim/pages/student/profile_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  // Alt barda basıldığında gösterilecek sayfaların listesi
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),    // Ana Sayfa
    HomeworkPage(),     // Ödevlerim
    ExamsPage(),        // Denemelerim
    AttendancePage(),   // Yoklamalarım
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metabilim Öğrenci', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false, // Geri tuşunu kaldırır
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Profil sayfasına git
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            label: 'Ödevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Denemeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Yoklamalar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Seçili ve seçili olmayan elemanların renkleri
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true, // Seçili olmayanların da yazısı görünsün
      ),
    );
  }
}