import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

// Arayüz için Event sınıfı
class Event {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isCompleted;

  Event({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isCompleted = false,
  });
}

class HomeworkCheckPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const HomeworkCheckPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<HomeworkCheckPage> createState() => _HomeworkCheckPageState();
}

class _HomeworkCheckPageState extends State<HomeworkCheckPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  void _changeDay(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount));
    });
  }

  // Firestore'dan gelen 'task' verisini arayüzde kullanacağımız 'Event' nesnesine dönüştürür
  Event _createEventFromTask(Map<String, dynamic> taskData, String time) {
    String title = 'Bilinmeyen Görev';
    String subtitle = '';
    IconData icon = Icons.task_outlined;
    Color iconColor = Colors.grey;
    bool isCompleted = (taskData['status'] == 'completed');

    final type = taskData['type'];

    if (type == 'topic' || type == 'practice') {
      title = '${(taskData['subject'] as String?)?.split('-').last ?? 'Ders'}: ${taskData['publisher'] ?? taskData['bookPublisher'] ?? ''}';
      subtitle = (type == 'topic') ? '${taskData['konu']} (${taskData['chunkPageRange'] ?? 'Sayfa: ${taskData['sayfa']}'})' : 'Deneme';
      icon = Icons.book_outlined;
      iconColor = Colors.blueGrey;
    } else if (type == 'digital') {
      title = 'Dijital Etüt';
      subtitle = taskData['task'] ?? '';
      icon = Icons.laptop_chromebook_outlined;
      iconColor = Colors.teal;
    } else if (type == 'fixed') {
      title = taskData['title'] ?? 'Etkinlik';
      subtitle = 'Etkinlik';
      icon = Icons.star_border_outlined;
      iconColor = Colors.orange;
    } else if (type == 'empty') {
      title = 'Boş Etüt';
      subtitle = 'Bu saate bir görev atanmamış.';
      icon = Icons.hourglass_empty;
      iconColor = Colors.grey.shade400;
    }

    return Event(title: title, subtitle: subtitle, time: time, icon: icon, iconColor: iconColor, isCompleted: isCompleted);
  }

  // Bir görevin durumunu veritabanında güncelleyen fonksiyon
  Future<void> _updateTaskStatus(DocumentReference scheduleRef, String dateKey, int taskIndex) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(scheduleRef);
        if (!freshSnap.exists) {
          throw Exception("Program belgesi bulunamadı!");
        }

        Map<String, dynamic> dailySlots = Map<String, dynamic>.from(freshSnap.get('dailySlots'));
        List<dynamic> tasksForDay = List<dynamic>.from(dailySlots[dateKey] ?? []);

        if (taskIndex < tasksForDay.length) {
          Map<String, dynamic> slot = Map<String, dynamic>.from(tasksForDay[taskIndex]);
          Map<String, dynamic> task = Map<String, dynamic>.from(slot['task']);

          // Durumu değiştir: completed -> assigned, assigned -> completed
          if (task['status'] == 'completed') {
            task['status'] = 'assigned';
          } else {
            task['status'] = 'completed';
          }

          slot['task'] = task;
          tasksForDay[taskIndex] = slot;
          dailySlots[dateKey] = tasksForDay;

          transaction.update(scheduleRef, {'dailySlots': dailySlots});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} Ödev Kontrol', style: GoogleFonts.poppins()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateScroller(),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Günün Programı', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF003366).withOpacity(0.8))),
          ),
          const SizedBox(height: 8.0),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('schedules').where('studentUid', isEqualTo: widget.studentId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Bu öğrenciye atanmış program bulunamadı.', style: GoogleFonts.poppins()));

                final allSchedules = snapshot.data!.docs;
                final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

                final correctScheduleDoc = allSchedules.firstWhereOrNull((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startDate = (data['startDate'] as Timestamp).toDate();
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  return !selectedDateOnly.isBefore(startDate) && !selectedDateOnly.isAfter(endDate);
                });

                if (correctScheduleDoc == null) return Center(child: Text('Bu tarih için bir program bulunamadı.', style: GoogleFonts.poppins()));

                final allSlots = correctScheduleDoc.get('dailySlots') as Map<String, dynamic>;
                final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final slotsForToday = allSlots[dateKey] as List<dynamic>? ?? [];

                if (slotsForToday.isEmpty) return Center(child: Text('Bugün için planlanmış bir etkinlik yok.', style: GoogleFonts.poppins()));

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4.0),
                  itemCount: slotsForToday.length,
                  itemBuilder: (context, index) {
                    final slot = slotsForToday[index];
                    final time = (slot['time'] as String?) ?? '00:00 - 00:00';
                    final task = (slot['task'] as Map<String, dynamic>?) ?? {'type': 'empty'};
                    final Event event = _createEventFromTask(task, time);

                    return _buildEventTile(event, () {
                      if (task['type'] != 'empty' && task['type'] != 'fixed') {
                        _updateTaskStatus(correctScheduleDoc.reference, dateKey, index);
                      }
                    });
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey), onPressed: () => _changeDay(-1)),
          Text(DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDate), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF003366))),
          IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueGrey), onPressed: () => _changeDay(1)),
        ],
      ),
    );
  }

  Widget _buildEventTile(Event event, VoidCallback onToggle) {
    return Opacity(
      opacity: event.isCompleted ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: ListTile(
          onTap: onToggle,
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(event.icon, color: event.iconColor, size: 28),
              const SizedBox(height: 2),
              Text(event.time.replaceAll(' - ', '\n'), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, height: 1.2), textAlign: TextAlign.center),
            ],
          ),
          title: Text(
            event.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: Text(
            event.subtitle,
            style: GoogleFonts.poppins(
              decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            event.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: event.isCompleted ? Colors.green : Colors.grey.shade400,
            size: 28,
          ),
        ),
      ),
    );
  }
}