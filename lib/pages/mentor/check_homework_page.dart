// lib/pages/mentor/check_homework_page.dart - YENİ VE GELİŞMİŞ TAM KOD

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:metabilim/pages/student/dashboard_page.dart'; // Event modeli için

class CheckHomeworkPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const CheckHomeworkPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<CheckHomeworkPage> createState() => _CheckHomeworkPageState();
}

class _CheckHomeworkPageState extends State<CheckHomeworkPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  void _changeDay(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount));
    });
  }

  Event _createEventFromTask(Map<String, dynamic> taskData, String time) {
    final type = taskData['type'] as String?;
    // ... (Bu fonksiyon bir önceki cevaptakiyle aynı, burada tekrar yazmaya gerek yok)
    if (type == 'digital') {
      return Event(
        title: 'Dijital Etüt',
        subtitle: taskData['task'] as String? ?? 'Çevrimiçi çalışma',
        time: time,
        icon: Icons.laptop_chromebook_outlined,
        iconColor: Colors.teal,
      );
    }
    else if (type == 'topic') {
      final subject = (taskData['subject'] as String?)?.split('-').last.trim() ?? 'Ders';
      final publisher = taskData['bookPublisher'] as String? ?? '';
      final topic = taskData['konu'] as String? ?? 'Konu';
      final pageRange = taskData['chunkPageRange'] as String? ?? taskData['sayfa'] as String? ?? '';

      return Event(
        title: '$subject: $publisher',
        subtitle: '$topic ($pageRange)',
        time: time,
        icon: Icons.book_outlined,
        iconColor: Colors.blueGrey,
      );
    }
    else if (type == 'fixed') {
      return Event(
        title: taskData['title'] as String? ?? 'Etkinlik',
        subtitle: 'Etkinlik',
        time: time,
        icon: Icons.star_border_outlined,
        iconColor: Colors.orange,
      );
    }
    else if (type == 'practice') {
      final subject = (taskData['subject'] as String?)?.split('-').last.trim() ?? 'Ders';
      final publisher = taskData['publisher'] as String? ?? 'Deneme';
      return Event(
        title: '$subject: $publisher',
        subtitle: 'Deneme',
        time: time,
        icon: Icons.assessment_outlined,
        iconColor: Colors.purple,
      );
    }
    else if (type == 'empty') {
      return Event(
        title: 'Boş Etüt',
        subtitle: 'Bu saatte bir görevin yok.',
        time: time,
        icon: Icons.hourglass_empty,
        iconColor: Colors.grey.shade400,
      );
    }
    else {
      return Event(
        title: 'Bilinmeyen Görev',
        subtitle: 'Programda tanımlanmamış görev.',
        time: time,
        icon: Icons.help_outline,
        iconColor: Colors.grey,
      );
    }
  }

  // Veritabanına kontrol durumunu ve notu kaydeden fonksiyon
  void _updateCheckStatus(String noteId, {String? status, String? note}) {
    final mentorId = FirebaseAuth.instance.currentUser!.uid;
    final Map<String, dynamic> dataToUpdate = {
      'studentId': widget.studentId,
      'mentorId': mentorId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (status != null) {
      dataToUpdate['status'] = status;
    }
    if (note != null) {
      dataToUpdate['note'] = note;
    }

    _firestore.collection('homework_checks').doc(noteId).set(dataToUpdate, SetOptions(merge: true));
  }

  // Not ekleme diyaloğu
  void _showNoteDialog(String noteId, String? existingNote) {
    final noteController = TextEditingController(text: existingNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Etüt Notu', style: GoogleFonts.poppins()),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(hintText: 'Kontrol notunuzu girin...'),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              _updateCheckStatus(noteId, note: noteController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} - Ödev Kontrol', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          _buildDateScroller(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('schedules').where('studentUid', isEqualTo: widget.studentId).snapshots(),
              builder: (context, scheduleSnapshot) {
                // ... (Veri bekleme, hata ve program yoksa gösterilen kısımlar aynı)
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Öğrenciye atanmış program bulunamadı.', style: GoogleFonts.poppins()));
                }

                final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                final correctScheduleDoc = scheduleSnapshot.data!.docs.firstWhereOrNull((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startDate = (data['startDate'] as Timestamp).toDate();
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  return !selectedDateOnly.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) && !selectedDateOnly.isAfter(DateTime(endDate.year, endDate.month, endDate.day));
                });

                if (correctScheduleDoc == null) {
                  return Center(child: Text('Bu tarih için bir program bulunamadı.', style: GoogleFonts.poppins()));
                }

                final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final slots = (correctScheduleDoc.get('dailySlots') as Map<String, dynamic>)[dateKey] as List<dynamic>? ?? [];

                if (slots.isEmpty) {
                  return Center(child: Text('Bugün için görev yok.', style: GoogleFonts.poppins()));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index] as Map<String, dynamic>;
                    final task = (slot['task'] as Map<String, dynamic>?) ?? {'type': 'empty'};
                    final event = _createEventFromTask(task, slot['time'] ?? '00:00');

                    if(event.icon == Icons.hourglass_empty) {
                      return const SizedBox.shrink(); // Boş etütleri gösterme
                    }

                    final timeKey = event.time.replaceAll(RegExp(r'[^0-9]'), '');
                    final noteId = '${widget.studentId}_${dateKey}_$timeKey';
                    final checkStream = _firestore.collection('homework_checks').doc(noteId).snapshots();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: checkStream,
                      builder: (context, checkSnapshot) {
                        String status = 'unchecked';
                        String? note;
                        if (checkSnapshot.hasData && checkSnapshot.data!.exists) {
                          final data = checkSnapshot.data!.data() as Map<String, dynamic>?;
                          status = data?['status'] ?? 'unchecked';
                          note = data?['note'];
                        }

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(event.icon, color: event.iconColor, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(event.subtitle, style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                    ),
                                    Text(event.time, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                if (note != null && note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0, left: 4, right: 4),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(note, style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                                    ),
                                  ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCheckButton(
                                      icon: Icons.check_circle,
                                      label: 'Yapıldı',
                                      color: Colors.green,
                                      isSelected: status == 'done',
                                      onPressed: () => _updateCheckStatus(noteId, status: 'done'),
                                    ),
                                    _buildCheckButton(
                                      icon: Icons.cancel,
                                      label: 'Yapılmadı',
                                      color: Colors.red,
                                      isSelected: status == 'not_done',
                                      onPressed: () => _updateCheckStatus(noteId, status: 'not_done'),
                                    ),
                                    _buildCheckButton(
                                      icon: Icons.note_add,
                                      label: 'Not Ekle',
                                      color: Colors.blue,
                                      isSelected: note != null && note.isNotEmpty,
                                      onPressed: () => _showNoteDialog(noteId, note),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton({required IconData icon, required String label, required Color color, required bool isSelected, required VoidCallback onPressed}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 30),
          color: isSelected ? color : Colors.grey.shade400,
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildDateScroller() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _changeDay(-1)),
          Text(DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _changeDay(1)),
        ],
      ),
    );
  }
}