import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class EditScheduleTemplatePage extends StatefulWidget {
  final String templateId;
  final String programName;
  const EditScheduleTemplatePage({super.key, required this.templateId, required this.programName});

  @override
  State<EditScheduleTemplatePage> createState() => _EditScheduleTemplatePageState();
}

class _EditScheduleTemplatePageState extends State<EditScheduleTemplatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> _dailySlots = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _daysOfWeek = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    final doc = await _firestore.collection('schedule_templates').doc(widget.templateId).get();
    if (doc.exists && doc.data() != null) {
      final scheduleMap = doc.data()!['schedule'] as Map<String, dynamic>;
      setState(() {
        _dailySlots = { for (var day in _daysOfWeek) day: List<String>.from(scheduleMap[day] ?? []) };
      });
    }
    setState(() => _isLoading = false);
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
                    _dailySlots[day]!.add(newSlot);
                    _dailySlots[day]!.sort();
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
      _dailySlots[day]!.remove(slot);
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('schedule_templates').doc(widget.templateId).update({'schedule': _dailySlots});
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
          // YENİ: Kaydetme uyarısı eklendi
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
    final slots = _dailySlots[day]!;
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
      case 'Pazar': return Icons.cake_outlined;
      default: return Icons.calendar_today;
    }
  }
}