// ... (dosyanın üst kısmı ve kodun çoğu aynı, sadece en alttaki butonu güncelliyoruz)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/select_materials_page.dart'; // YENİ: Bu satırı ekle

// EtudSlot class tanımı aynı kalıyor...
class EtudSlot {
  final DateTime dateTime;
  String? lessonName;
  String? lessonType;
  final bool isDigital;
  EtudSlot({ required this.dateTime, this.lessonName, this.lessonType, this.isDigital = false, });
  String get fullLessonName => lessonType != null ? '$lessonType $lessonName' : lessonName ?? 'Boş Etüt';
}

class PreviewSchedulePage extends StatefulWidget {
  // ... (widget'ın değişkenleri aynı kalıyor)
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, int> tytLessons;
  final Map<String, int> aytLessons;

  const PreviewSchedulePage({ Key? key, required this.student, required this.startDate, required this.endDate, required this.tytLessons, required this.aytLessons, }) : super(key: key);

  @override
  _PreviewSchedulePageState createState() => _PreviewSchedulePageState();
}

class _PreviewSchedulePageState extends State<PreviewSchedulePage> {
  // ... (state değişkenleri ve fonksiyonların hepsi aynı kalıyor)
  bool _isLoading = true;
  String? _infoMessage;
  Map<DateTime, List<EtudSlot>> _schedule = {};
  final PageController _pageController = PageController();
  int _currentPage = 0;
  EtudSlot? _selectedForSwap;

  @override
  void initState() { super.initState(); _generateSchedule(); }
  Future<void> _generateSchedule() async { /* ... (fonksiyonun içi tamamen aynı) */
    setState(() { _isLoading = true; _infoMessage = null; });
    try {
      List<EtudSlot> allSlots = [];
      final firestore = FirebaseFirestore.instance;
      final scheduleDoc = await firestore.collection('settings').doc('schedule_times').get();
      final digitalDoc = await firestore.collection('settings').doc('digital_schedule').get();
      final scheduleData = scheduleDoc.exists ? scheduleDoc.data() as Map<String, dynamic> : <String, dynamic>{};
      final digitalData = digitalDoc.exists ? digitalDoc.data() as Map<String, dynamic> : <String, dynamic>{};
      for (var day = widget.startDate; day.isBefore(widget.endDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        String dayName = _getDayNameInTurkish(day.weekday);
        _addSlots(allSlots, scheduleData, day, dayName, isDigital: false);
        _addSlots(allSlots, digitalData, day, dayName, isDigital: true);
      }
      if (allSlots.isEmpty) {
        if(mounted) setState(() { _infoMessage = 'Seçilen tarih aralığı için ayarlanmış herhangi bir etüt saati bulunamadı.'; _isLoading = false; });
        return;
      }
      allSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      List<List<String>> lessonsToPlace = [];
      widget.tytLessons.forEach((lesson, count) { for (int i = 0; i < count; i++) lessonsToPlace.add(['TYT', lesson]); });
      widget.aytLessons.forEach((lesson, count) { for (int i = 0; i < count; i++) lessonsToPlace.add(['AYT', lesson]); });
      lessonsToPlace.shuffle(Random());
      int lessonIndex = 0;
      for (var slot in allSlots) {
        if (!slot.isDigital && lessonIndex < lessonsToPlace.length) {
          slot.lessonType = lessonsToPlace[lessonIndex][0];
          slot.lessonName = lessonsToPlace[lessonIndex][1];
          lessonIndex++;
        }
      }
      Map<DateTime, List<EtudSlot>> groupedSchedule = {};
      for (var slot in allSlots) {
        final dateOnly = DateTime(slot.dateTime.year, slot.dateTime.month, slot.dateTime.day);
        groupedSchedule.putIfAbsent(dateOnly, () => []).add(slot);
      }
      if(mounted) setState(() { _schedule = groupedSchedule; });
    } catch (e) {
      print('Program oluşturulurken kritik hata: $e');
      if(mounted) _infoMessage = 'Program oluşturulamadı. Lütfen etüt saat ayarlarını kontrol edin.';
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  void _addSlots(List<EtudSlot> allSlots, Map<String, dynamic> data, DateTime day, String dayName, {required bool isDigital}) { /* ... (fonksiyonun içi tamamen aynı) */
    if (data.containsKey(dayName) && data[dayName] is List) {
      for (var timeEntry in (data[dayName] as List)) {
        try {
          String startTime = timeEntry.toString().split('-')[0].trim();
          final parts = startTime.split(':');
          if (parts.length == 2) {
            allSlots.add(EtudSlot(
                dateTime: DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1])),
                isDigital: isDigital,
                lessonName: isDigital ? 'Dijital Etüt' : null
            ));
          }
        } catch (e) { print('Hatalı zaman formatı atlanıyor: "$timeEntry" - Hata: $e'); }
      }
    }
  }
  void _handleSwap(EtudSlot clickedSlot) { /* ... (fonksiyonun içi tamamen aynı) */
    if (clickedSlot.isDigital || clickedSlot.lessonName == null) return;
    if (_selectedForSwap == null) {
      setState(() => _selectedForSwap = clickedSlot);
    } else {
      if (_selectedForSwap != clickedSlot) {
        final tempLessonName = _selectedForSwap!.lessonName;
        final tempLessonType = _selectedForSwap!.lessonType;
        setState(() {
          _selectedForSwap!.lessonName = clickedSlot.lessonName;
          _selectedForSwap!.lessonType = clickedSlot.lessonType;
          clickedSlot.lessonName = tempLessonName;
          clickedSlot.lessonType = tempLessonType;
        });
      }
      setState(() => _selectedForSwap = null);
    }
  }
  String _getDayNameInTurkish(int weekday) { /* ... (fonksiyonun içi tamamen aynı) */
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheduleDays = _schedule.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Program Önizleme')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _infoMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(_infoMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant))))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null),
                Text(scheduleDays.isNotEmpty ? DateFormat.yMMMEd('tr_TR').format(scheduleDays[_currentPage]) : 'Program Boş', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _currentPage < scheduleDays.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: scheduleDays.length,
              itemBuilder: (context, index) {
                final day = scheduleDays[index];
                final slots = _schedule[day]!;
                return ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, slotIndex) {
                    final slot = slots[slotIndex];
                    final isSelectedForSwap = _selectedForSwap == slot;
                    final Color? lessonColor = slot.lessonType == 'TYT' ? Colors.blue.shade100 : slot.lessonType == 'AYT' ? Colors.orange.shade100 : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: isSelectedForSwap ? Colors.amber.withOpacity(0.3) : (slot.isDigital ? Colors.grey.shade300 : lessonColor),
                      child: ListTile(
                        leading: Text(DateFormat.Hm().format(slot.dateTime), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        title: Text(slot.fullLessonName),
                        trailing: slot.isDigital || slot.lessonName == null ? null : IconButton(
                          icon: Icon(Icons.swap_horiz, color: isSelectedForSwap ? Colors.amber.shade900 : null),
                          onPressed: () => _handleSwap(slot),
                        ),
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
          // GÜNCELLEME: Butonun onPressed fonksiyonu güncellendi
          onPressed: (_isLoading || _infoMessage != null) ? null : () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SelectMaterialsPage(
                student: widget.student,
                startDate: widget.startDate,
                endDate: widget.endDate,
                schedule: _schedule, // Oluşturulan ve düzenlenen programı bir sonraki sayfaya gönder
              ),
            ));
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Materyal Seçimine Geç', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}