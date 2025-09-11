import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/login_page.dart';
import 'package:metabilim/pages/admin/user_management_page.dart';
import 'package:metabilim/pages/admin/admin_dashboard_page.dart';
import 'package:metabilim/pages/admin/class_management_page.dart';
import 'package:metabilim/pages/admin/coach_management_page.dart';
import 'package:metabilim/pages/admin/digital_lesson_settings_page.dart';
import 'package:metabilim/pages/admin/exam_analysis_page.dart';
import 'package:metabilim/pages/admin/schedule_settings_page.dart';
// --- YENİ SAYFAMIZI IMPORT EDİYORUZ ---
import 'package:metabilim/pages/admin/computer_management_page.dart';


class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  // --- Sayfa listesine YENİ sayfamızı ekliyoruz ---
  static final List<Widget> _adminPages = <Widget>[
    const AdminDashboardPage(),
    const UserManagementPage(),
    const ClassManagementPage(),
    const CoachManagementPage(),
    const ExamAnalysisPage(),
    const ComputerManagementPage(), // YENİ EKLENDİ
    const DigitalLessonSettingsPage(),
    const ScheduleSettingsPage(),
  ];

  // --- Sayfa başlıkları listesini güncelliyoruz ---
  static const List<String> _pageTitles = <String>[
    'Genel Bakış',
    'Kullanıcı Yönetimi',
    'Sınıf Yönetimi',
    'Eğitim Koçu Yönetimi',
    'Sınav Sonucu Yükle',
    'Bilgisayar Yönetimi', // YENİ EKLENDİ
    'Dijital Ders Ayarları',
    'Etüt Şablon Ayarları',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Drawer'ı kapat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
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
            _buildDrawerItem(
                icon: Icons.upload_file_outlined,
                title: 'Sınav Sonucu Yükle',
                index: 4),
            // --- YENİ MENÜ ELEMANI ---
            _buildDrawerItem(
                icon: Icons.desktop_mac_outlined, // Yeni ikon
                title: 'Bilgisayar Yönetimi',
                index: 5),
            // --- DİĞERLERİNİN INDEX'LERİ GÜNCELLENDİ ---
            _buildDrawerItem(
                icon: Icons.computer_outlined,
                title: 'Dijital Ders Ayarları',
                index: 6),
            _buildDrawerItem(
                icon: Icons.timer_outlined,
                title: 'Etüt Şablon Ayarları',
                index: 7),

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