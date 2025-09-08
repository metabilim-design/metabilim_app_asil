import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';

class AssignLessonEtudsPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;

  const AssignLessonEtudsPage({
    Key? key,
    required this.student,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _AssignLessonEtudsPageState createState() => _AssignLessonEtudsPageState();
}

class _AssignLessonEtudsPageState extends State<AssignLessonEtudsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _totalEtuds = 0;
  int _digitalEtuds = 0;
  bool _isLoading = true;

  final Map<String, int> _tytLessonEtuds = {};
  final Map<String, int> _aytLessonEtuds = {};

  final List<String> tytLessons = ['Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü'];
  final List<String> aytLessons = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih-1', 'Coğrafya-1', 'Tarih-2', 'Coğrafya-2', 'Felsefe Grubu'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePage();
  }

  void _initializePage() {
    for (var lesson in tytLessons) { _tytLessonEtuds[lesson] = 0; }
    for (var lesson in aytLessons) { _aytLessonEtuds[lesson] = 0; }
    _calculateTotalEtuds();
  }

  int get _assignedEtuds {
    int total = 0;
    _tytLessonEtuds.forEach((key, value) => total += value);
    _aytLessonEtuds.forEach((key, value) => total += value);
    return total;
  }

  Future<void> _calculateTotalEtuds() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final scheduleDoc = await firestore.collection('settings').doc('schedule_times').get();
      final digitalDoc = await firestore.collection('settings').doc('digital_schedule').get();
      final scheduleData = scheduleDoc.exists ? scheduleDoc.data() as Map<String, dynamic> : <String, dynamic>{};
      final digitalData = digitalDoc.exists ? digitalDoc.data() as Map<String, dynamic> : <String, dynamic>{};
      int calculatedTotal = 0;
      int calculatedDigital = 0;
      for (var day = widget.startDate; day.isBefore(widget.endDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        String dayName = _getDayNameInTurkish(day.weekday);
        if (scheduleData.containsKey(dayName) && scheduleData[dayName] is List) {
          calculatedTotal += (scheduleData[dayName] as List).length;
        }
        if (digitalData.containsKey(dayName) && digitalData[dayName] is List) {
          calculatedDigital += (digitalData[dayName] as List).length;
        }
      }
      if(mounted) {
        setState(() {
          _totalEtuds = calculatedTotal;
          _digitalEtuds = calculatedDigital;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Etüt saatleri alınamadı. $e')),
        );
      }
    }
  }

  String _getDayNameInTurkish(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Pazartesi';
      case DateTime.tuesday: return 'Salı';
      case DateTime.wednesday: return 'Çarşamba';
      case DateTime.thursday: return 'Perşembe';
      case DateTime.friday: return 'Cuma';
      case DateTime.saturday: return 'Cumartesi';
      case DateTime.sunday: return 'Pazar';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingEtuds = _totalEtuds - _assignedEtuds;
    bool canProceed = _assignedEtuds > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Derslere Etüt Ata'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [ Tab(text: 'TYT'), Tab(text: 'AYT'), ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kalan / Toplam Etüt', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  Text(
                    '$remainingEtuds / $_totalEtuds  (+ $_digitalEtuds Dijital)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonList(tytLessons, _tytLessonEtuds, remainingEtuds),
                _buildLessonList(aytLessons, _aytLessonEtuds, remainingEtuds),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: !canProceed ? null : () {
            // DÜZELTME: Haritaların tipi (Map<String, int>) açıkça belirtildi.
            final Map<String, int> assignedTytLessons = Map.from(_tytLessonEtuds)..removeWhere((key, value) => value == 0);
            final Map<String, int> assignedAytLessons = Map.from(_aytLessonEtuds)..removeWhere((key, value) => value == 0);

            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PreviewSchedulePage(
                student: widget.student,
                startDate: widget.startDate,
                endDate: widget.endDate,
                tytLessons: assignedTytLessons,
                aytLessons: assignedAytLessons,
              ),
            ));
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Programı Oluştur ve Önizle', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildLessonList(List<String> lessons, Map<String, int> lessonEtuds, int remainingEtuds) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final count = lessonEtuds[lesson] ?? 0;
        return ListTile(
          title: Text(lesson),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Theme.of(context).colorScheme.error,
                onPressed: count > 0 ? () => setState(() => lessonEtuds[lesson] = count - 1) : null,
              ),
              Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.primary,
                onPressed: remainingEtuds > 0 ? () => setState(() => lessonEtuds[lesson] = count + 1) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}