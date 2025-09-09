import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditClassSchedulePage extends StatefulWidget {
  final String classId;
  final String className;

  const EditClassSchedulePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<EditClassSchedulePage> createState() => _EditClassSchedulePageState();
}

class _EditClassSchedulePageState extends State<EditClassSchedulePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _scheduleTemplateId;

  final Map<String, int> _etudeCounts = {
    'Pazartesi': 0, 'Salı': 0, 'Çarşamba': 0,
    'Perşembe': 0, 'Cuma': 0, 'Cumartesi': 0, 'Pazar': 0,
  };
  final List<String> _days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _loadClassSchedule();
  }

  Future<void> _loadClassSchedule() async {
    setState(() => _isLoading = true);
    try {
      // 1. Sınıfın bilgisini çekerek özel bir programı var mı diye bak
      final classDoc = await _firestore.collection('classes').doc(widget.classId).get();
      if (classDoc.exists && classDoc.data()!.containsKey('scheduleTemplateId')) {
        _scheduleTemplateId = classDoc.data()!['scheduleTemplateId'];

        // 2. Eğer özel program ID'si varsa, o programın detaylarını çek
        if (_scheduleTemplateId != null) {
          final templateDoc = await _firestore.collection('schedule_templates').doc(_scheduleTemplateId).get();
          if (templateDoc.exists) {
            final data = templateDoc.data()!['etudeCounts'] as Map<String, dynamic>;
            _etudeCounts.forEach((day, count) {
              _etudeCounts[day] = data[day] ?? 0;
            });
          }
        }
      }
      // Eğer sınıfa özel program yoksa, _etudeCounts zaten 0 olarak kalacak.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Program yüklenirken hata: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      final templatesRef = _firestore.collection('schedule_templates');

      // Oluşturulan bu program için bir isim (Örn: "12-A Sınıf Programı")
      final templateName = '${widget.className} Programı';

      if (_scheduleTemplateId == null) {
        // Bu sınıf için daha önce bir program oluşturulmamış, YENİ OLUŞTUR
        final newTemplate = await templatesRef.add({
          'name': templateName,
          'etudeCounts': _etudeCounts,
          'isDefault': false, // Bu genel bir şablon değil
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Sınıf belgesini, yeni oluşturulan programın ID'si ile güncelle
        await _firestore.collection('classes').doc(widget.classId).update({
          'scheduleTemplateId': newTemplate.id,
        });
      } else {
        // Mevcut programı GÜNCELLE
        await templatesRef.doc(_scheduleTemplateId).update({
          'name': templateName,
          'etudeCounts': _etudeCounts,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sınıf programı başarıyla kaydedildi!'), backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydederken hata oluştu: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Programı', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSchedule,
            tooltip: 'Kaydet',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          return _buildDayTile(day);
        },
      ),
    );
  }

  Widget _buildDayTile(String day) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if ((_etudeCounts[day] ?? 0) > 0) {
                      setState(() => _etudeCounts[day] = _etudeCounts[day]! - 1);
                    }
                  },
                ),
                Text(_etudeCounts[day].toString(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() => _etudeCounts[day] = _etudeCounts[day]! + 1);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}