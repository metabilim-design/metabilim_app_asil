import 'package:flutter/material.dart';
import 'package:metabilim/models/user_model.dart'; // YENİ: AppUser modelini tanımak için
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart'; // YENİ: EtudSlot modelini tanımak için
import 'select_topic_page.dart';

class SelectEffortPage extends StatefulWidget {
  // --- DEĞİŞİKLİK BURADA ---
  // Artık studentId yerine tam AppUser nesnesini ve schedule'ı alıyoruz.
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;
  final Map<DateTime, List<EtudSlot>> schedule;

  const SelectEffortPage({
    Key? key,
    required this.student, // Değişti
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
    required this.schedule, // Eklendi
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
        title: Text('Program Eforu Belirle'),
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
            SizedBox(height: 20),
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
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectTopicPage(
                      // --- DEĞİŞİKLİK BURADA ---
                      // Artık bir sonraki sayfaya doğru ve tam bilgileri gönderiyoruz.
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
              },
              child: Text('Konu Seçimine Devam Et'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}