import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSlotDetailPage extends StatefulWidget {
  final Map<String, dynamic> timeSlot;

  const TimeSlotDetailPage({super.key, required this.timeSlot});

  @override
  State<TimeSlotDetailPage> createState() => _TimeSlotDetailPageState();
}

class _TimeSlotDetailPageState extends State<TimeSlotDetailPage> {
  // TODO: Bu liste, o saatteki öğrencilerin gerçek program verileriyle doldurulacak.
  // Şimdilik örnek veri:
  final List<Map<String, String>> _studentsInSlot = [
    {'name': 'Ali Veli', 'task': 'TYT Matematik: Sayılar'},
    {'name': 'Ayşe Yılmaz', 'task': 'AYT Fizik: Vektörler'},
    {'name': 'Mehmet Kaya', 'task': 'Boş Etüt'},
    {'name': 'Zeynep Aslan', 'task': 'TYT Türkçe: Paragraf'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.timeSlot['range'] ?? 'Etüt Detayı',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _studentsInSlot.length,
        itemBuilder: (context, index) {
          final studentData = _studentsInSlot[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(studentData['name']![0]),
              ),
              title: Text(studentData['name']!),
              subtitle: Text(
                studentData['task']!,
                style: TextStyle(
                  color: studentData['task'] == 'Boş Etüt' ? Colors.grey : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}