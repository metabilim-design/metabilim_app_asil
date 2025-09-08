import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ComputerSchedulePage extends StatefulWidget {
  final String computerId;
  final String computerName;

  const ComputerSchedulePage({super.key, required this.computerId, required this.computerName});

  @override
  State<ComputerSchedulePage> createState() => _ComputerSchedulePageState();
}

class _ComputerSchedulePageState extends State<ComputerSchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _daysOfWeek = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  Map<String, List<String>> _studySlots = {};
  Map<String, DocumentSnapshot> _allStudents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _daysOfWeek.length, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Tüm öğrencileri ve etüt saatlerini başta bir kere çekelim
    final studentsSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Ogrenci').get();
    final scheduleSettingsDoc = await FirebaseFirestore.instance.collection('settings').doc('schedule_times').get();

    if (mounted) {
      setState(() {
        _allStudents = {for (var doc in studentsSnapshot.docs) doc.id: doc};
        if (scheduleSettingsDoc.exists) {
          final data = scheduleSettingsDoc.data()!;
          _studySlots = { for (var day in _daysOfWeek) day: List<String>.from(data[day] ?? []) };
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Öğrenci seçme dialoğunu gösterir
  Future<void> _showStudentSelectionDialog(String day, String timeSlot) async {
    String? selectedStudentId;

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('$timeSlot için Öğrenci Seç'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _allStudents.values.map((doc) {
                  final student = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('${student['name']} ${student['surname']}'),
                    onTap: () {
                      selectedStudentId = doc.id;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal'))],
          );
        });

    if (selectedStudentId != null) {
      // Seçim yapıldıysa veritabanını güncelle
      await FirebaseFirestore.instance.collection('digital_schedules').doc(widget.computerName).set({
        'schedule': {
          day: {timeSlot: selectedStudentId}
        }
      }, SetOptions(merge: true)); // merge:true ile belgenin tamamını silmeden sadece ilgili alanı güncelleriz
    }
  }

  // Atamayı kaldırma
  Future<void> _removeAssignment(String day, String timeSlot) async {
    await FirebaseFirestore.instance.collection('digital_schedules').doc(widget.computerName).set({
      'schedule': {
        day: {timeSlot: FieldValue.delete()} // Sadece o saat dilimini siler
      }
    }, SetOptions(merge: true));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.computerName} Programı'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _daysOfWeek.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: _daysOfWeek.map((day) => _buildDaySchedule(day)).toList(),
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final slotsForDay = _studySlots[day] ?? [];
    if (slotsForDay.isEmpty) {
      return Center(child: Text('$day için etüt saati tanımlanmamış.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('digital_schedules').doc(widget.computerName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final scheduleData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final daySchedule = (scheduleData['schedule'] as Map<String, dynamic>?)?[day] as Map<String, dynamic>? ?? {};

        return ListView.builder(
          itemCount: slotsForDay.length,
          itemBuilder: (context, index) {
            final timeSlot = slotsForDay[index];
            final studentId = daySchedule[timeSlot];
            final studentDoc = _allStudents[studentId];
            final studentName = studentDoc != null ? '${studentDoc['name']} ${studentDoc['surname']}' : 'Boş';

            return ListTile(
              title: Text(timeSlot, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(studentName, style: TextStyle(color: studentDoc != null ? Colors.black : Colors.grey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (studentDoc != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => _removeAssignment(day, timeSlot),
                      tooltip: 'Atamayı Kaldır',
                    ),
                  ElevatedButton(
                    onPressed: () => _showStudentSelectionDialog(day, timeSlot),
                    child: Text(studentDoc != null ? 'Değiştir' : 'Ata'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}