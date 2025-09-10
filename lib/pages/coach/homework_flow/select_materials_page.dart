import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metabilim/models/user_model.dart';
import 'package:metabilim/pages/coach/homework_flow/preview_schedule_page.dart';
import 'package:metabilim/pages/coach/homework_flow/select_effort_page.dart';

class MaterialItem {
  final String id;
  final String name;
  final String publisher;
  final String collectionName;
  bool isSelected;

  MaterialItem({
    required this.id,
    required this.name,
    required this.publisher,
    required this.collectionName,
    this.isSelected = false,
  });
}

class SelectMaterialsPage extends StatefulWidget {
  final AppUser student;
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, List<EtudSlot>> schedule;

  const SelectMaterialsPage({
    Key? key,
    required this.student,
    required this.startDate,
    required this.endDate,
    required this.schedule,
  }) : super(key: key);

  @override
  _SelectMaterialsPageState createState() => _SelectMaterialsPageState();
}

class _SelectMaterialsPageState extends State<SelectMaterialsPage> {
  bool _isLoading = true;
  final Map<String, List<MaterialItem>> _materialsByLesson = {};

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);
    try {
      final Set<String> uniqueLessons = {};
      widget.schedule.values.forEach((slots) {
        for (var slot in slots) {
          if (slot.lessonName != null && !slot.isDigital) {
            uniqueLessons.add(slot.fullLessonName);
          }
        }
      });

      if (uniqueLessons.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      for (String fullLessonName in uniqueLessons) {
        final parts = fullLessonName.split(' ');
        if (parts.length < 2) continue;
        final String lessonType = parts[0];
        final String lessonName = parts.sublist(1).join(' ');
        List<MaterialItem> items = [];
        final booksSnapshot = await FirebaseFirestore.instance.collection('books').where('level', isEqualTo: lessonType).where('subject', isEqualTo: lessonName).get();
        for (var doc in booksSnapshot.docs) {
          final data = doc.data();
          items.add(MaterialItem(id: doc.id, name: data['bookType'] ?? 'İsimsiz Kitap', publisher: data['publisher'], collectionName: 'books'));
        }
        final practicesSnapshot = await FirebaseFirestore.instance.collection('practices').where('level', isEqualTo: lessonType).where('subject', isEqualTo: lessonName).get();
        for (var doc in practicesSnapshot.docs) {
          final data = doc.data();
          items.add(MaterialItem(id: doc.id, name: data['practiceName'] ?? 'İsimsiz Deneme', publisher: data['publisher'], collectionName: 'practices'));
        }
        if (items.isNotEmpty) {
          _materialsByLesson[fullLessonName] = items;
        }
      }
    } catch (e) {
      print('Materyal çekerken kritik bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueToEffortPage() {
    final List<String> selectedMaterialIds = [];
    _materialsByLesson.values.forEach((materialList) {
      for (var material in materialList) {
        if (material.isSelected) {
          selectedMaterialIds.add(material.id);
        }
      }
    });

    if (selectedMaterialIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen devam etmeden önce en az bir materyal seçin.'), backgroundColor: Colors.red));
      return;
    }

    final Map<String, int> lessonEtuds = {};
    widget.schedule.values.forEach((slots) {
      for (var slot in slots) {
        if (slot.lessonName != null && !slot.isDigital) {
          lessonEtuds.update(slot.fullLessonName, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    });

    // --- DÜZELTME BURADA YAPILDI ---
    // Artık bir sonraki sayfaya 'student' nesnesini ve 'schedule' haritasını da gönderiyoruz.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectEffortPage(
          student: widget.student,
          startDate: widget.startDate,
          endDate: widget.endDate,
          lessonEtuds: lessonEtuds,
          selectedMaterials: selectedMaterialIds,
          schedule: widget.schedule,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonKeys = _materialsByLesson.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materyal Seçimi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : lessonKeys.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Programa eklenen dersler için sisteme kayıtlı herhangi bir kitap veya deneme bulunamadı.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16))))
          : ListView.builder(
        itemCount: lessonKeys.length,
        itemBuilder: (context, index) {
          final lessonName = lessonKeys[index];
          final materials = _materialsByLesson[lessonName]!;
          return ExpansionTile(
            title: Text(lessonName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            initiallyExpanded: true,
            children: materials.map((material) {
              return CheckboxListTile(
                title: Text(material.name),
                subtitle: Text(material.publisher),
                value: material.isSelected,
                onChanged: (bool? value) {
                  setState(() => material.isSelected = value ?? false);
                },
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _continueToEffortPage,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Efor Belirlemeye Devam Et', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}