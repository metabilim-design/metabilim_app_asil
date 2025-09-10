import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
// YENİ: Bir sonraki adımı import ediyoruz
import 'package:metabilim/pages/coach/homework_flow/continue_preview_schedule_page.dart';

class SelectPreviousSchedulePage extends StatefulWidget {
  final AppUser student;

  const SelectPreviousSchedulePage({Key? key, required this.student}) : super(key: key);

  @override
  _SelectPreviousSchedulePageState createState() => _SelectPreviousSchedulePageState();
}

class _SelectPreviousSchedulePageState extends State<SelectPreviousSchedulePage> {
  DocumentSnapshot? _selectedSchedule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Program Seç'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Hangi programdan devam etmek istediğinizi seçin.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('studentUid', isEqualTo: widget.student.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Programlar yüklenirken bir hata oluştu.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bu öğrenciye ait daha önce oluşturulmuş bir program bulunamadı.'));
                }

                final schedules = snapshot.data!.docs;
                schedules.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final Timestamp tsA = aData['startDate'] ?? Timestamp(0, 0);
                  final Timestamp tsB = bData['startDate'] ?? Timestamp(0, 0);
                  return tsB.compareTo(tsA);
                });

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final scheduleDoc = schedules[index];
                    final data = scheduleDoc.data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();

                    final formattedStartDate = DateFormat.yMMMMd('tr_TR').format(startDate);
                    final formattedEndDate = DateFormat.yMMMMd('tr_TR').format(endDate);
                    final isSelected = _selectedSchedule?.id == scheduleDoc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text('Program', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text('$formattedStartDate - $formattedEndDate', style: GoogleFonts.poppins()),
                        onTap: () {
                          setState(() {
                            _selectedSchedule = scheduleDoc;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedSchedule == null
              ? null
              : () {
            // --- DEĞİŞİKLİK BURADA ---
            // Artık yeni oluşturduğumuz önizleme sayfasına yönlendiriyoruz.
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ContinuePreviewSchedulePage(
                student: widget.student,
                previousScheduleDoc: _selectedSchedule!,
              ),
            ));
            // --- BİTTİ ---
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}