// lib/mentor_shell.dart - GÜNCELLENMİŞ VE DOĞRU ÇALIŞAN HALİ

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/attendance_class_list_page.dart';
import 'package:metabilim/pages/mentor/class_roster_page.dart';
import 'package:metabilim/pages/mentor/book_list_page.dart';
import 'package:metabilim/pages/mentor/take_attendance_page.dart';
import 'package:metabilim/pages/mentor/profile_page.dart';

class MentorShell extends StatefulWidget {
  const MentorShell({super.key});

  @override
  State<MentorShell> createState() => _MentorShellState();
}

class _MentorShellState extends State<MentorShell> {
  int _selectedIndex = 0;

  // Sayfaları yeni akışa göre düzenliyoruz
  static const List<Widget> _pages = <Widget>[
    ClassRosterPage(purpose: 'viewDetails'),  // Öğrenciler -> Sınıf Listesi
    BookListPage(),                           // Kitaplar
    ClassRosterPage(purpose: 'homeworkCheck'),// Ödev Kontrol -> Sınıf Listesi
    AttendanceClassListPage(),                     // Yoklama Al
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
        title: Text('Metabilim Mentor', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Öğrenciler'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Kitaplar'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Ödev Kontrol'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Yoklama Al'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}