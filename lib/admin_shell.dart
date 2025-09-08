// lib/admin_shell.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/login_page.dart';
import 'package:metabilim/pages/admin/user_management_page.dart';
import 'package:metabilim/pages/admin/schedule_settings_page.dart';
import 'package:metabilim/pages/admin/admin_dashboard_page.dart';
import 'package:metabilim/pages/admin/class_management_page.dart';
import 'package:metabilim/pages/admin/coach_management_page.dart';
import 'package:metabilim/pages/admin/digital_lesson_settings_page.dart';
// --- DEĞİŞİKLİK BURADA ---
// Eski 'upload_exam_page.dart' importu kaldırıldı, yerine doğrusu eklendi.
import 'package:metabilim/pages/admin/exam_analysis_page.dart';
// --- BİTTİ ---

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  // --- DEĞİŞİKLİK BURADA: Menüdeki sayfa listesi güncellendi ---
  static final List<Widget> _adminPages = <Widget>[
    const AdminDashboardPage(),
    const UserManagementPage(),
    const ClassManagementPage(),
    const CoachManagementPage(),
    const ExamAnalysisPage(), // YENİ VE DOĞRU SAYFA BURADA
    const DigitalLessonSettingsPage(),
    const ScheduleSettingsPage(),
  ];

  static const List<String> _pageTitles = <String>[
    'Genel Bakış',
    'Kullanıcı Yönetimi',
    'Sınıf Yönetimi',
    'Eğitim Koçu Yönetimi',
    'Sınav Sonucu Yükle', // Başlık aynı kalabilir
    'Dijital Ders Ayarları',
    'Etüt Saat Ayarları',
  ];
  // ---------------------------------------------

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: GoogleFonts.poppins(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text('Admin Paneli',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600)),
            ),
            _buildDrawerItem(
                icon: Icons.dashboard_outlined, title: 'Genel Bakış', index: 0),
            _buildDrawerItem(
                icon: Icons.people_alt_outlined,
                title: 'Kullanıcı Yönetimi',
                index: 1),
            _buildDrawerItem(
                icon: Icons.class_outlined, title: 'Sınıf Yönetimi', index: 2),
            _buildDrawerItem(
                icon: Icons.school_outlined,
                title: 'Eğitim Koçu Yönetimi',
                index: 3),

            // --- Menüdeki ilgili eleman ---
            _buildDrawerItem(
                icon: Icons.upload_file_outlined,
                title: 'Sınav Sonucu Yükle',
                index: 4),
            // -------------------------------

            _buildDrawerItem(
                icon: Icons.computer_outlined,
                title: 'Dijital Ders Ayarları',
                index: 5),
            _buildDrawerItem(
                icon: Icons.timer_outlined,
                title: 'Etüt Saat Ayarları',
                index: 6),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _adminPages.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon, required String title, required int index}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
    );
  }
}