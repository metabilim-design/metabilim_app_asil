import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/continue_preview_schedule_page.dart';

class SelectPreviousSchedulePage extends StatefulWidget {
  final AppUser student;
  // --- YENİ ---
  // Bir önceki sayfadan yeni tarih aralığını alıyoruz.
  final DateTime newStartDate;
  final DateTime newEndDate;

  const SelectPreviousSchedulePage({
    Key? key,
    required this.student,
    required this.newStartDate,
    required this.newEndDate,
  }) : super(key: key);

  @override
  _SelectPreviousSchedulePageState createState() => _SelectPreviousSchedulePageState();
}

class _SelectPreviousSchedulePageState extends State<SelectPreviousSchedulePage> {
  DocumentSnapshot? _selectedSchedule;

  void _compareAndProceed() {
    if (_selectedSchedule == null) return;

    final newDuration = widget.newEndDate.difference(widget.newStartDate).inDays;

    final data = _selectedSchedule!.data() as Map<String, dynamic>;
    final oldStartDate = (data['startDate'] as Timestamp).toDate();
    final oldEndDate = (data['endDate'] as Timestamp).toDate();
    final oldDuration = oldEndDate.difference(oldStartDate).inDays;

    if (newDuration != oldDuration) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gün Sayıları Eşleşmiyor'),
            content: Text(
                'Yeni seçtiğiniz tarih aralığı (${newDuration + 1} gün), kopyalanacak olan eski programın süresiyle (${oldDuration + 1} gün) aynı değil. Lütfen aynı sürelere sahip bir tarih aralığı seçin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anladım'),
              )
            ],
          ));
    } else {
      // Süreler eşit, devam et.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ContinuePreviewSchedulePage(
          student: widget.student,
          previousScheduleDoc: _selectedSchedule!,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Program Kopyala'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Şablon olarak kullanılacak eski bir program seçin.',
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
                    final duration = endDate.difference(startDate).inDays + 1;

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
                        title: Text('$duration Günlük Program', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              : _compareAndProceed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Karşılaştır ve Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}