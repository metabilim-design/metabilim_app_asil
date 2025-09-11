import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/coach/coach_student_list_page.dart';
import 'package:metabilim/pages/coach/homework_flow/homework_start_page.dart';
import 'package:metabilim/pages/mentor/book_list_page.dart';
import 'package:metabilim/pages/mentor/profile_page.dart';

class EgitimKocuShell extends StatefulWidget {
  const EgitimKocuShell({super.key});

  @override
  State<EgitimKocuShell> createState() => _EgitimKocuShellState();
}

class _EgitimKocuShellState extends State<EgitimKocuShell> {
  int _selectedIndex = 0;

  // --- GÜNCELLEME BURADA ---
  // Sayfa listesi artık hangi sekmeden gelindiğini bilecek şekilde oluşturuluyor.
  static final List<Widget> _pages = <Widget>[
    const CoachStudentListPage(navigationSource: 'ogrenciler'), // 0: Öğrenciler sekmesi
    const HomeworkStartPage(),                                  // 1: Ödev Ver sekmesi
    const CoachStudentListPage(navigationSource: 'deneme'),     // 2: Deneme Sonuçları sekmesi
    const BookListPage(),                                       // 3: Materyaller sekmesi
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
        title: Text('Eğitim Koçu Paneli', style: GoogleFonts.poppins()),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Öğrenciler'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Ödev Ver'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Deneme Sonuçları'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Materyaller'),
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