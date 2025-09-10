// lib/pages/coach/weekly_check_view_page.dart - YENİ DOSYA

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:metabilim/pages/student/dashboard_page.dart'; // Event modeli için

class WeeklyCheckViewPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const WeeklyCheckViewPage({super.key, required this.studentId, required this.studentName});

  @override
  State<WeeklyCheckViewPage> createState() => _WeeklyCheckViewPageState();
}

class _WeeklyCheckViewPageState extends State<WeeklyCheckViewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  void _changeDay(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount));
    });
  }

  Event _createEventFromTask(Map<String, dynamic> taskData, String time) {
    final type = taskData['type'] as String?;
    // ... (Bu fonksiyon bir önceki cevaptakiyle aynı)
    if (type == 'digital') {
      return Event(title: 'Dijital Etüt', subtitle: taskData['task'] as String? ?? 'Çevrimiçi çalışma', time: time, icon: Icons.laptop_chromebook_outlined, iconColor: Colors.teal);
    } else if (type == 'topic') {
      final subject = (taskData['subject'] as String?)?.split('-').last.trim() ?? 'Ders';
      final publisher = taskData['bookPublisher'] as String? ?? '';
      final topic = taskData['konu'] as String? ?? 'Konu';
      final pageRange = taskData['chunkPageRange'] as String? ?? taskData['sayfa'] as String? ?? '';
      return Event(title: '$subject: $publisher', subtitle: '$topic ($pageRange)', time: time, icon: Icons.book_outlined, iconColor: Colors.blueGrey);
    } else if (type == 'empty') {
      return Event(title: 'Boş Etüt', subtitle: 'Bu saatte bir görevin yok.', time: time, icon: Icons.hourglass_empty, iconColor: Colors.grey.shade400);
    } else {
      return Event(title: 'Bilinmeyen Görev', subtitle: 'Programda tanımlanmamış görev.', time: time, icon: Icons.help_outline, iconColor: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName, style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          _buildDateScroller(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('schedules').where('studentUid', isEqualTo: widget.studentId).snapshots(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) return Center(child: Text('Program bulunamadı.', style: GoogleFonts.poppins()));

                final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                final correctScheduleDoc = scheduleSnapshot.data!.docs.firstWhereOrNull((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startDate = (data['startDate'] as Timestamp).toDate();
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  return !selectedDateOnly.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) && !selectedDateOnly.isAfter(DateTime(endDate.year, endDate.month, endDate.day));
                });

                if (correctScheduleDoc == null) return Center(child: Text('Bu tarih için bir program bulunamadı.', style: GoogleFonts.poppins()));

                final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final slots = (correctScheduleDoc.get('dailySlots') as Map<String, dynamic>)[dateKey] as List<dynamic>? ?? [];

                if (slots.isEmpty) return Center(child: Text('Bugün için görev yok.', style: GoogleFonts.poppins()));

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index] as Map<String, dynamic>;
                    final task = (slot['task'] as Map<String, dynamic>?) ?? {'type': 'empty'};
                    final event = _createEventFromTask(task, slot['time'] ?? '00:00');

                    if (event.icon == Icons.hourglass_empty) return const SizedBox.shrink();

                    final timeKey = event.time.replaceAll(RegExp(r'[^0-9]'), '');
                    final noteId = '${widget.studentId}_${dateKey}_$timeKey';
                    final checkStream = _firestore.collection('homework_checks').doc(noteId).snapshots();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: checkStream,
                      builder: (context, checkSnapshot) {
                        Widget checkStatusWidget = const SizedBox.shrink();
                        String? note;

                        if (checkSnapshot.hasData && checkSnapshot.data!.exists) {
                          final data = checkSnapshot.data!.data() as Map<String, dynamic>?;
                          final status = data?['status'];
                          note = data?['note'];

                          if (status == 'done') {
                            checkStatusWidget = const Icon(Icons.check_circle, color: Colors.green, size: 28);
                          } else if (status == 'not_done') {
                            checkStatusWidget = const Icon(Icons.cancel, color: Colors.red, size: 28);
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(event.icon, color: event.iconColor),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                          Text(event.subtitle, style: GoogleFonts.poppins()),
                                        ],
                                      ),
                                    ),
                                    checkStatusWidget,
                                  ],
                                ),
                                if (note != null && note.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(note, style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                                  ),
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