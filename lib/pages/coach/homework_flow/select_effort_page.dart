import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DocumentSnapshot için eklendi
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/continue_homework_check_review_page.dart'; // YENİ: Bir sonraki adımı import ettik
import 'select_topic_page.dart';

class SelectEffortPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;
  final Map<DateTime, List<EtudSlot>> schedule;
  // YENİ: Bu parametre sadece "devam etme" akışında dolu olacak.
  final DocumentSnapshot? previousScheduleDoc;

  const SelectEffortPage({
    Key? key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
    required this.schedule,
    this.previousScheduleDoc, // Constructor'a eklendi
  }) : super(key: key);

  @override
  _SelectEffortPageState createState() => _SelectEffortPageState();
}

class _SelectEffortPageState extends State<SelectEffortPage> {
  int _effortRating = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Eforu Belirle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Öğrencinin bu programdaki hedeflenen eforu:',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _effortRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _effortRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // --- DEĞİŞİKLİK BURADA ---
                // Eğer previousScheduleDoc varsa (yani "devam etme" akışındaysak),
                // yeni kontrol sayfasına git. Yoksa (sıfırdan oluşturma), eski hedef olan konu seçimine git.
                if (widget.previousScheduleDoc != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContinueHomeworkCheckReviewPage(
                        student: widget.student,
                        startDate: widget.startDate,
                        endDate: widget.endDate,
                        lessonEtuds: widget.lessonEtuds,
                        selectedMaterials: widget.selectedMaterials,
                        schedule: widget.schedule,
                        effortRating: _effortRating,
                        previousScheduleDoc: widget.previousScheduleDoc!,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectTopicPage(
                        student: widget.student,
                        startDate: widget.startDate,
                        endDate: widget.endDate,
                        lessonEtuds: widget.lessonEtuds,
                        selectedMaterials: widget.selectedMaterials,
                        effortRating: _effortRating,
                        schedule: widget.schedule,
                      ),
                    ),
                  );
                }
                // --- BİTTİ ---
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Konu Seçimine Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}