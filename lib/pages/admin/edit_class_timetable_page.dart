import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:metabilim/services/firestore_service.dart';

class EditClassTimetablePage extends StatefulWidget {
  final String classId;
  final String className;

  const EditClassTimetablePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<EditClassTimetablePage> createState() => _EditClassTimetablePageState();
}

class _EditClassTimetablePageState extends State<EditClassTimetablePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _days = ['pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi', 'pazar'];
  final Map<String, List<String>> _timetable = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    final doc = await _firestoreService.getClassTimetable(widget.classId);
    if (doc != null && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      for (var day in _days) {
        // Firestore'dan gelen veriyi List<String> formatına çeviriyoruz.
        _timetable[day] = List<String>.from(data[day] ?? []);
      }
    } else {
      // Eğer hiç program yoksa, tüm günler için boş listeler oluştur
      for (var day in _days) {
        _timetable[day] = [];
      }
    }
    setState(() => _isLoading = false);
  }

  void _addSlot(String day) {
    final timeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${day.substring(0, 1).toUpperCase()}${day.substring(1)} için Saat Ekle'),
        content: TextField(
          controller: timeController,
          decoration: const InputDecoration(hintText: 'Örn: 14:00-14:45'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (timeController.text.trim().isNotEmpty) {
                setState(() {
                  _timetable[day]!.add(timeController.text.trim());
                  _timetable[day]!.sort(); // Saatleri sıralı tut
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTimetable() async {
    setState(() => _isSaving = true);
    try {
      // Firestore'a gönderirken gün isimlerini küçük harfle gönderdiğimizden emin olalım
      final Map<String, dynamic> dataToSave = {};
      _timetable.forEach((key, value) {
        dataToSave[key.toLowerCase()] = value;
      });

      await _firestoreService.saveClassTimetable(widget.classId, dataToSave);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program başarıyla kaydedildi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Programı', style: GoogleFonts.poppins()),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
              : IconButton(icon: const Icon(Icons.save), onPressed: _saveTimetable, tooltip: 'Programı Kaydet'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final slots = _timetable[day] ?? [];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              initiallyExpanded: true, // Başlangıçta açık olsun
              title: Text('${day.substring(0, 1).toUpperCase()}${day.substring(1)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              children: [
                ...slots.map((slot) => ListTile(
                  title: Text(slot, style: GoogleFonts.poppins(fontSize: 16)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _timetable[day]!.remove(slot);
                      });
                    },
                  ),
                )),
                ListTile(
                  title: const Text('Yeni Saat Ekle'),
                  leading: Icon(Icons.add_alarm, color: Theme.of(context).primaryColor),
                  onTap: () => _addSlot(day),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}