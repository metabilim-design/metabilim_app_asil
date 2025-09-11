import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/student/dashboard_page.dart';
import 'pages/student/homework_page.dart';
import 'pages/student/exams_page.dart';
import 'pages/student/attendance_page.dart';
import 'pages/mentor/profile_page.dart';

class VeliShell extends StatefulWidget {
  const VeliShell({super.key});

  @override
  State<VeliShell> createState() => _VeliShellState();
}

class _VeliShellState extends State<VeliShell> {
  int _selectedIndex = 0;
  String? _studentUid;
  String _studentName = '...';
  String _parentName = '...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentLink();
  }

  Future<void> _fetchStudentLink() async {
    final parentUser = FirebaseAuth.instance.currentUser;
    if (parentUser == null) return;

    try {
      final parentDoc = await FirebaseFirestore.instance.collection('users').doc(parentUser.uid).get();
      final parentData = parentDoc.data();
      final studentId = parentData?['studentUid'] as String?;
      final parentName = parentData?['name'] as String?;

      if (studentId != null && studentId.isNotEmpty) {
        final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
        if (studentDoc.exists && mounted) {
          setState(() {
            _studentUid = studentId;
            _studentName = studentDoc.data()?['name'] ?? 'Öğrenci';
            _parentName = parentName ?? 'Veli';
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_studentUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Bu veli hesabına bağlı bir öğrenci bulunamadı. Lütfen kurum yöneticinizle iletişime geçin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ),
      );
    }

    // --- DEĞİŞİKLİK BURADA ---
    // Sayfa listesini build metodunun içine taşıdık ki _studentUid'yi kullanabilelim.
    final List<Widget> pages = <Widget>[
      DashboardPage(studentId: _studentUid!, studentName: _studentName, parentName: _parentName),
      HomeworkPage(studentId: _studentUid!), // Ödevler sayfasına öğrenci ID'sini gönderiyoruz
      ExamsPage(studentId: _studentUid!),    // Denemeler sayfasına öğrenci ID'sini gönderiyoruz
      AttendancePage(studentId: _studentUid!),
    ];
    // --- BİTTİ ---

    return Scaffold(
      appBar: AppBar(
        title: Text('Veli Paneli - $_studentName', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Ödevler'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Denemeler'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Yoklamalar'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}