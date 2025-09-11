import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'homework_detail_page.dart';

class HomeworkPage extends StatefulWidget {
  // --- YENİ EKLENDİ ---
  final String? studentId;
  const HomeworkPage({super.key, this.studentId});
  // --- BİTTİ ---

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  // --- DEĞİŞİKLİK BURADA ---
  late Stream<QuerySnapshot> _schedulesStream;
  late String _targetStudentId;

  @override
  void initState() {
    super.initState();
    // Veli bakıyorsa onun verdiği ID'yi, öğrenci bakıyorsa kendi ID'sini kullan
    _targetStudentId = widget.studentId ?? FirebaseAuth.instance.currentUser!.uid;

    // Sorguyu bu ID'ye göre oluştur
    _schedulesStream = FirebaseFirestore.instance
        .collection('schedules')
        .where('studentUid', isEqualTo: _targetStudentId)
        .snapshots();
  }
  // --- BİTTİ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ödev Programlarım', style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _schedulesStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Henüz atanmış bir program bulunmuyor.', style: GoogleFonts.poppins()));
          }

          final schedules = snapshot.data!.docs;
          schedules.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final Timestamp tsA = aData['startDate'] ?? Timestamp(0, 0);
            final Timestamp tsB = bData['startDate'] ?? Timestamp(0, 0);
            return tsB.compareTo(tsA);
          });

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: schedules.map((DocumentSnapshot document) {
              final data = document.data()! as Map<String, dynamic>;
              final startDate = (data['startDate'] as Timestamp).toDate();
              final endDate = (data['endDate'] as Timestamp).toDate();

              final formattedStartDate = DateFormat.yMMMMd('tr_TR').format(startDate);
              final formattedEndDate = DateFormat.yMMMMd('tr_TR').format(endDate);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text('Program', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('$formattedStartDate - $formattedEndDate', style: GoogleFonts.poppins()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeworkDetailPage(scheduleDoc: document),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}