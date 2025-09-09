import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditScheduleTemplatePage extends StatefulWidget {
  final String templateId;
  final String programName;
  const EditScheduleTemplatePage({super.key, required this.templateId, required this.programName});

  @override
  State<EditScheduleTemplatePage> createState() => _EditScheduleTemplatePageState();
}

class _EditScheduleTemplatePageState extends State<EditScheduleTemplatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Değişken adını daha anlaşılır yaptım: _timetable
  Map<String, List<String>> _timetable = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _daysOfWeek = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // Fonksiyonu daha güvenli hale getirdim.
  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('schedule_templates').doc(widget.templateId).get();

      // Dökümanın varlığını ve verinin null olmadığını kontrol ediyoruz.
      if (doc.exists && doc.data() != null) {
        // HATA BURADAYDI: Alan adı 'schedule' değil, 'timetable' olmalıydı.
        // Ayrıca ?? {} ekleyerek bu alan hiç yoksa bile programın çökmesini engelledim.
        final timetableFromDB = doc.data()?['timetable'] as Map<String, dynamic>? ?? {};

        setState(() {
          // Gelen veriyi Map<String, List<String>> formatına güvenli bir şekilde çeviriyoruz.
          _timetable = {
            for (var day in _daysOfWeek)
              day: List<String>.from(timetableFromDB[day] ?? [])
          };
        });
      } else {
        // Eğer döküman yoksa veya boşsa, tüm günleri boş listelerle başlat.
        setState(() {
          _timetable = { for (var day in _daysOfWeek) day: [] };
        });
      }
    } catch (e) {
      print("Program yüklenirken hata oluştu: $e");
      // Hata durumunda da boş bir tablo göster.
      setState(() {
        _timetable = { for (var day in _daysOfWeek) day: [] };
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSlot(String day) async {
    final formKey = GlobalKey<FormState>();
    final startController = TextEditingController();
    final endController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Etüt Saati Ekle", style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: 'Başlangıç (HH:mm)', hintText: '09:00'),
                  validator: _validateTime,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: 'Bitiş (HH:mm)', hintText: '09:40'),
                  validator: _validateTime,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newSlot = '${startController.text.trim()} - ${endController.text.trim()}';
                  setState(() {
                    _timetable[day]!.add(newSlot);
                    _timetable[day]!.sort(); // Saatleri ekledikten sonra sırala
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Lütfen saat girin.';
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value.trim())) return 'Geçersiz format. (HH:mm)';
    return null;
  }

  void _removeSlot(String day, String slot) {
    setState(() {
      _timetable[day]!.remove(slot);
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      // DÜZELTME: Veriyi tutarlılık için yine 'timetable' alanına kaydediyoruz.
      await _firestore.collection('schedule_templates').doc(widget.templateId).update({'timetable': _timetable});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydederken bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.programName, style: GoogleFonts.poppins())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade300)
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                      'Yaptığınız değişikliklerin geçerli olması için sayfanın altındaki "Programı Kaydet" butonuna basmayı unutmayın.',
                      style: GoogleFonts.poppins(color: Colors.amber.shade900)
                  ),
                ),
              ],
            ),
          ),
          ..._daysOfWeek.map((day) => _buildDayCard(day)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSchedule,
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save),
        label: const Text('Programı Kaydet'),
      ),
    );
  }

  Widget _buildDayCard(String day) {
    // _timetable'ın null olma ihtimaline karşı koruma ekledim.
    final slots = _timetable[day] ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        initiallyExpanded: DateTime.now().weekday == (_daysOfWeek.indexOf(day) + 1),
        leading: Icon(_getIconForDay(day)),
        title: Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        children: [
          ...slots.map((slot) => ListTile(
            title: Text(slot),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeSlot(day, slot),
            ),
          )),
          TextButton.icon(
            onPressed: () => _addSlot(day),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Yeni Etüt Ekle'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForDay(String day) {
    switch (day) {
      case 'Pazartesi': return Icons.looks_one_outlined;
      case 'Salı': return Icons.looks_two_outlined;
      case 'Çarşamba': return Icons.looks_3_outlined;
      case 'Perşembe': return Icons.looks_4_outlined;
      case 'Cuma': return Icons.looks_5_outlined;
      case 'Cumartesi': return Icons.looks_6_outlined;
      case 'Pazar': return Icons.cake_outlined; // Pazar günü tatil :)
      default: return Icons.calendar_today;
    }
  }
}