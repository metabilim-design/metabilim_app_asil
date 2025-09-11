// lib/pages/admin/computer_schedule_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:collection/collection.dart'; // for firstWhereOrNull

class ComputerSchedulePage extends StatefulWidget {
  final AppUser student;

  const ComputerSchedulePage({super.key, required this.student});

  @override
  State<ComputerSchedulePage> createState() => _ComputerSchedulePageState();
}

class _ComputerSchedulePageState extends State<ComputerSchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _daysOfWeek = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  bool _isLoading = true;

  Map<String, List<String>> _studentTimetable = {}; // Öğrencinin sınıfının programı
  List<DocumentSnapshot> _computers = []; // Mevcut tüm bilgisayarlar

  // Örn: {'Bilgisayar 1': {'Pazartesi_09:00-09:40': 'ogrenciId123'}}
  Map<String, Map<String, String>> _allDigitalAssignments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _daysOfWeek.length, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Tüm bilgisayarları çek
      final computersSnapshot = await firestore.collection('computers').orderBy('name').get();
      _computers = computersSnapshot.docs;

      // 2. Öğrencinin sınıf programını çek
      if (widget.student.classId != null && widget.student.classId!.isNotEmpty) {
        final classDoc = await firestore.collection('classes').doc(widget.student.classId).get();
        final templateId = classDoc.data()?['activeTimetableId'];
        if (templateId != null) {
          final templateDoc = await firestore.collection('schedule_templates').doc(templateId).get();
          final timetableData = templateDoc.data()?['timetable'] as Map<String, dynamic>? ?? {};
          _studentTimetable = timetableData.map((key, value) => MapEntry(key, List<String>.from(value)));
        }
      }

      // 3. Tüm dijital etüt atamalarını çek
      _allDigitalAssignments.clear(); // Haritayı temizle
      final digitalSchedulesSnapshot = await firestore.collection('digital_schedules').get();
      for (var doc in digitalSchedulesSnapshot.docs) {
        final computerName = doc.id; // Döküman ID'si bilgisayarın adıdır
        final schedule = doc.data()['schedule'] as Map<String, dynamic>? ?? {};
        _allDigitalAssignments[computerName] = {};
        schedule.forEach((day, slots) {
          (slots as Map<String, dynamic>).forEach((timeSlot, studentId) {
            _allDigitalAssignments[computerName]!['${day}_$timeSlot'] = studentId.toString();
          });
        });
      }
    } catch (e) {
      debugPrint("Veri yüklenirken hata: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SON DÜZELTİLMİŞ, NİHAİ FONKSİYON ---
  Future<void> _assignStudentToComputer(String day, String timeSlot, String computerName) async {
    final firestore = FirebaseFirestore.instance;
    final studentId = widget.student.uid;
    final uniqueKey = '${day}_$timeSlot';

    WriteBatch batch = firestore.batch();

    // 1. Bu öğrencinin bu saatte başka bir bilgisayarda mevcut bir ataması var mı diye bul.
    final currentAssignment = _allDigitalAssignments.entries
        .firstWhereOrNull((entry) => entry.value[uniqueKey] == studentId);

    // 2. Eğer mevcut bir ataması varsa, o eski atamayı SİL.
    // Bu yöntem, diğer öğrencilerin atamalarını etkilemez.
    if (currentAssignment != null) {
      final oldComputerName = currentAssignment.key;
      final oldDocRef = firestore.collection('digital_schedules').doc(oldComputerName);
      batch.update(oldDocRef, {
        'schedule.$day.$timeSlot': FieldValue.delete(),
      });
    }

    // 3. Yeni atamayı YAP. `set` ve `merge:true` kullanarak döküman olmasa bile oluşturur
    // ve diğer saatleri ezmeden veriyi doğru bir şekilde ekler.
    final newDocRef = firestore.collection('digital_schedules').doc(computerName);
    batch.set(newDocRef, {
      'schedule': {
        day: {
          timeSlot: studentId
        }
      }
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      _loadInitialData(); // Arayüzü güncelle
    } catch (e) {
      debugPrint("Dijital etüt ataması sırasında hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atama yapılırken bir hata oluştu: $e')),
        );
      }
    }
  }


  Future<void> _removeAssignment(String day, String timeSlot, String computerName) async {
    await FirebaseFirestore.instance.collection('digital_schedules').doc(computerName).update({
      'schedule.$day.$timeSlot': FieldValue.delete(),
    });
    _loadInitialData(); // Arayüzü güncelle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Dijital Etüt Ata', style: GoogleFonts.poppins()),
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
    final slotsForDay = _studentTimetable[day] ?? [];
    if (slotsForDay.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('$day için öğrencinin programında etüt saati yok.', textAlign: TextAlign.center, style: GoogleFonts.poppins()),
      ));
    }

    return ListView.builder(
      itemCount: slotsForDay.length,
      itemBuilder: (context, index) {
        final timeSlot = slotsForDay[index];
        final uniqueKey = '${day}_$timeSlot';

        final currentAssignment = _allDigitalAssignments.entries
            .firstWhereOrNull((entry) => entry.value[uniqueKey] == widget.student.uid);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(timeSlot, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text(
              currentAssignment != null ? 'Atandı: ${currentAssignment.key}' : 'Atama yapılmadı',
              style: GoogleFonts.poppins(color: currentAssignment != null ? Colors.green.shade700 : Colors.red.shade700),
            ),
            trailing: currentAssignment != null ?
            IconButton(icon: const Icon(Icons.close), onPressed: () => _removeAssignment(day, timeSlot, currentAssignment.key), tooltip: "Atamayı Kaldır",)
                : const Icon(Icons.keyboard_arrow_down),
            children: _computers.map((computer) {
              final computerData = computer.data() as Map<String, dynamic>;
              final computerName = computerData['name'] ?? computer.id;

              final assignedStudentId = _allDigitalAssignments[computerName]?[uniqueKey];
              final bool isOccupied = assignedStudentId != null;
              final bool isThisStudent = assignedStudentId == widget.student.uid;

              return ListTile(
                title: Text(computerName, style: GoogleFonts.poppins()),
                trailing: ElevatedButton(
                  onPressed: (isOccupied && !isThisStudent) ? null : () => _assignStudentToComputer(day, timeSlot, computerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isThisStudent ? Colors.green : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: Text(isThisStudent ? 'Atandı' : (isOccupied ? 'Dolu' : 'Ata')),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}