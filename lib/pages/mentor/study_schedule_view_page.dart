import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/pages/mentor/etut_detail_page.dart'; // Yeni sayfayı import ediyoruz

class StudyScheduleViewPage extends StatefulWidget {
  const StudyScheduleViewPage({super.key});

  @override
  State<StudyScheduleViewPage> createState() => _StudyScheduleViewPageState();
}

class _StudyScheduleViewPageState extends State<StudyScheduleViewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('settings').doc('schedule_times').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Etüt saatleri ayarlanmamış.'));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Etüt saatleri yüklenemedi.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> weekdaySlots = data['weekdayTimes'] ?? [];
        final List<dynamic> saturdaySlots = data['saturdayTimes'] ?? [];

        final today = DateTime.now().weekday;
        final isSaturday = today == DateTime.saturday;
        final slots = isSaturday ? saturdaySlots : weekdaySlots;

        if (slots.isEmpty) {
          return Center(child: Text( isSaturday ? "Cumartesi için etüt saati ayarlanmamış." : "Hafta içi için etüt saati ayarlanmamış."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final timeSlot = slots[index] as String;

            // DÜZELTME: ExpansionTile yerine ListTile kullanıldı
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                leading: Icon(Icons.access_time_filled, color: Theme.of(context).primaryColor),
                title: Text(
                  '$timeSlot Arası',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Tıklandığında yeni detay sayfasına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EtutDetailPage(timeSlot: timeSlot),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}