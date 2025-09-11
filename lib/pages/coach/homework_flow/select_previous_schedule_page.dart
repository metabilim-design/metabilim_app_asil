import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/continue_preview_schedule_page.dart';

class SelectPreviousSchedulePage extends StatefulWidget {
  final AppUser student;

  const SelectPreviousSchedulePage({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  _SelectPreviousSchedulePageState createState() => _SelectPreviousSchedulePageState();
}

class _SelectPreviousSchedulePageState extends State<SelectPreviousSchedulePage> {
  DocumentSnapshot? _selectedSchedule;

  void _proceed() {
    if (_selectedSchedule == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ContinuePreviewSchedulePage(
        student: widget.student,
        previousScheduleDoc: _selectedSchedule!,
      ),
    ));
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

                // ### YENİ KONTROL MANTIĞI BURADA ###
                // Öğrencinin tüm programları arasındaki en son bitiş tarihini bul.
                DateTime? latestEndDate;
                for (var doc in schedules) {
                  final data = doc.data() as Map<String, dynamic>;
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  if (latestEndDate == null || endDate.isAfter(latestEndDate)) {
                    latestEndDate = endDate;
                  }
                }

                schedules.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final Timestamp tsA = aData['startDate'] ?? Timestamp(0, 0);
                  final Timestamp tsB = bData['startDate'] ?? Timestamp(0, 0);
                  return tsB.compareTo(tsA); // En yeniden eskiye sırala
                });

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final scheduleDoc = schedules[index];
                    final data = scheduleDoc.data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();
                    final duration = endDate.difference(startDate).inDays + 1;

                    // Bu programın bitiş tarihi, en son bitiş tarihinden önce mi diye kontrol et.
                    // Eğer öyleyse, bu programdan zaten devam edilmiştir.
                    final bool isOutdated = latestEndDate != null && endDate.isBefore(latestEndDate);

                    final formattedStartDate = DateFormat.yMMMMd('tr_TR').format(startDate);
                    final formattedEndDate = DateFormat.yMMMMd('tr_TR').format(endDate);
                    final isSelected = _selectedSchedule?.id == scheduleDoc.id;

                    return Card(
                      color: isOutdated ? Colors.grey.shade200 : null, // Pasifse rengini değiştir
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        enabled: !isOutdated, // Pasifse tıklanmasını engelle
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text('$duration Günlük Program', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text('$formattedStartDate - $formattedEndDate', style: GoogleFonts.poppins()),
                        trailing: isOutdated
                            ? Text("Devam Edilmiş", style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic))
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Sadece pasif olmayanlar seçilebilir
                          if (!isOutdated) {
                            setState(() {
                              _selectedSchedule = scheduleDoc;
                            });
                          }
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
          onPressed: _selectedSchedule == null ? null : _proceed,
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