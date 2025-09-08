import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Event sınıfı Dashboard'dan alındı
class Event {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;

  Event({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

class HomeworkDetailPage extends StatefulWidget {
  final DocumentSnapshot scheduleDoc;

  const HomeworkDetailPage({super.key, required this.scheduleDoc});

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  late DateTime _selectedDate;
  late DateTime _startDate;
  late DateTime _endDate;

  final Set<String> _completedTasks = {};

  @override
  void initState() {
    super.initState();
    final data = widget.scheduleDoc.data() as Map<String, dynamic>;
    _startDate = (data['startDate'] as Timestamp).toDate();
    _endDate = (data['endDate'] as Timestamp).toDate();
    _selectedDate = _startDate; // Programın başlangıç tarihinden başla
  }

  void _changeDay(int amount) {
    setState(() {
      final newDate = _selectedDate.add(Duration(days: amount));
      // Sadece programın tarih aralığı içinde gezinmeye izin ver
      final startDateOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endDateOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);

      if (!newDate.isBefore(startDateOnly) && !newDate.isAfter(endDateOnly)) {
        _selectedDate = newDate;
        _completedTasks.clear();
      }
    });
  }

  Event _createEventFromTask(Map<String, dynamic> taskData, String time) {
    String title = 'Bilinmeyen Görev';
    String subtitle = '';
    IconData icon = Icons.task_outlined;
    Color iconColor = Colors.grey;

    final type = taskData['type'];

    if (type == 'topic' || type == 'practice') {
      title = '${(taskData['subject'] as String?)?.split('-').last ?? 'Ders'}: ${taskData['publisher'] ?? taskData['bookPublisher'] ?? ''}';
      subtitle = (type == 'topic') ? '${taskData['konu']} (${taskData['chunkPageRange'] ?? taskData['sayfa']})' : 'Deneme';
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
      subtitle = 'Bu saatte bir görevin yok.';
      icon = Icons.hourglass_empty;
      iconColor = Colors.grey.shade400;
    }

    return Event(title: title, subtitle: subtitle, time: time, icon: icon, iconColor: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleData = widget.scheduleDoc.data() as Map<String, dynamic>;
    final allSlots = scheduleData['dailySlots'] as Map<String, dynamic>;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotsForToday = allSlots[dateKey] as List<dynamic>? ?? [];

    final formattedStartDate = DateFormat.yMMMMd('tr_TR').format(_startDate);
    final formattedEndDate = DateFormat.yMMMMd('tr_TR').format(_endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Program Detayı', style: GoogleFonts.poppins()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text('$formattedStartDate - $formattedEndDate', style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateScroller(),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Günün Programı', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: slotsForToday.isEmpty
                ? Center(child: Text('Bugün için planlanmış bir etkinlik yok.', style: GoogleFonts.poppins()))
                : ListView.builder(
              padding: const EdgeInsets.only(top: 4.0),
              itemCount: slotsForToday.length,
              itemBuilder: (context, index) {
                final slot = slotsForToday[index];
                final time = (slot['time'] as String?) ?? '00:00 - 00:00';
                final task = (slot['task'] as Map<String, dynamic>?) ?? {'type': 'empty'};
                final Event event = _createEventFromTask(task, time);
                return _buildEventTile(event);
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

  Widget _buildEventTile(Event event) {
    final eventId = '${event.time}-${event.title}-${event.subtitle}';
    final isCompleted = _completedTasks.contains(eventId);

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: ListTile(
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isCompleted ? Icons.check_circle : event.icon, color: isCompleted ? Colors.green : event.iconColor, size: 28),
              const SizedBox(height: 2),
              Text(event.time.replaceAll(' - ', '\n'), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, height: 1.2), textAlign: TextAlign.center),
            ],
          ),
          title: Text(
            event.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              color: isCompleted ? Colors.grey.shade600 : Colors.black,
            ),
          ),
          subtitle: Text(
            event.subtitle,
            style: GoogleFonts.poppins(decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            if (event.icon != Icons.hourglass_empty && event.icon != Icons.star_border_outlined) {
              setState(() {
                if (isCompleted) {
                  _completedTasks.remove(eventId);
                } else {
                  _completedTasks.add(eventId);
                }
              });
            }
          },
        ),
      ),
    );
  }
}