import 'package:flutter/material.dart';
import 'select_topic_page.dart'; // Yeni oluşturduğumuz sayfayı import ediyoruz

class SelectEffortPage extends StatefulWidget {
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> lessonEtuds;
  final List<String> selectedMaterials;

  const SelectEffortPage({
    Key? key,
    required this.studentId,
    required this.startDate,
    required this.endDate,
    required this.lessonEtuds,
    required this.selectedMaterials,
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
              // DEĞİŞİKLİK BURADA: Artık yeni Konu Seçim Sayfasına yönlendiriyoruz.
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectTopicPage(
                      studentId: widget.studentId,
                      startDate: widget.startDate,
                      endDate: widget.endDate,
                      lessonEtuds: widget.lessonEtuds,
                      selectedMaterials: widget.selectedMaterials,
                      effortRating: _effortRating, // Seçilen eforu da aktarıyoruz
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