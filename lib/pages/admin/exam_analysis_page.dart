// lib/pages/admin/exam_analysis_page.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:metabilim/models/exam_result.dart';
import 'package:metabilim/pages/admin/exam_results_preview_page.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExamAnalysisPage extends StatefulWidget {
  const ExamAnalysisPage({super.key});

  @override
  State<ExamAnalysisPage> createState() => _ExamAnalysisPageState();
}

class _ExamAnalysisPageState extends State<ExamAnalysisPage> {
  bool _isProcessing = false;
  String _processingStatus = "";
  PlatformFile? _pickedFile;
  String _selectedExamType = 'TYT';
  late final GenerativeModel _generativeModel;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY .env dosyasında bulunamadı.');
    }

    _generativeModel = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      generationConfig: GenerationConfig(
        responseMimeType: "application/json",
      ),
    );
  }

  void _showErrorDialog(String message) {
    final displayMessage = message.startsWith("Exception: ") ? message.substring(11) : message;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bir Sorun Oluştu", style: GoogleFonts.poppins()),
        content: Text(displayMessage, style: GoogleFonts.poppins()),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tamam'))],
      ),
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) setState(() => _pickedFile = result.files.single);
  }

  Future<void> startAnalysis() async {
    if (_pickedFile?.bytes == null) {
      _showErrorDialog("Lütfen önce bir PDF dosyası seçin.");
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      updateStatus("PDF sayfaları analiz ediliyor...");
      final examName = _pickedFile!.name.replaceAll(RegExp(r'\.pdf$'), '');

      final List<StudentExamResult> allResults = await _processPdfPageByPage(_pickedFile!.bytes!, examName);

      if(allResults.isEmpty) {
        throw Exception("PDF'ten hiçbir öğrenci verisi çıkarılamadı.");
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultsPreviewPage(results: allResults, examName: examName),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<List<StudentExamResult>> _processPdfPageByPage(Uint8List pdfBytes, String examName) async {
    final List<StudentExamResult> allResults = [];
    final document = PdfDocument(inputBytes: pdfBytes);
    final textExtractor = PdfTextExtractor(document);

    for (int i = 0; i < document.pages.count; i++) {
      updateStatus("Sayfa ${i + 1}/${document.pages.count} işleniyor...");

      final String pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);

      if (pageText.trim().length < 50) {
        debugPrint("Sayfa ${i+1} boş veya geçersiz, atlanıyor.");
        continue;
      }

      try {
        final prompt = _createSinglePagePrompt(pageText, examName, _selectedExamType);
        final response = await _generativeModel.generateContent([Content.text(prompt)]);

        if (response.text != null && response.text!.isNotEmpty) {
          String responseText = response.text!.replaceAll("```json", "").replaceAll("```", "").trim();
          final List<dynamic> jsonList = jsonDecode(responseText);
          if (jsonList.isNotEmpty) {
            allResults.add(StudentExamResult.fromJson(jsonList.first));
          }
        }
      } catch (e) {
        debugPrint("Sayfa ${i+1} işlenirken hata (atlandı): ${e.toString()}");
        continue;
      }
    }

    document.dispose();
    updateStatus("Analiz tamamlandı!");
    return allResults;
  }

  void updateStatus(String status) => setState(() => _processingStatus = status);

  // --- DAHA AKILLI VE ESNEK HALE GETİRİLEN NİHAİ PROMPT ---
  String _createSinglePagePrompt(String pageText, String examName, String examType) {
    return """
    # GÖREV:
    Sen, farklı formatlardaki sınav karnesi metinlerini analiz etme konusunda uzman bir veri çıkarma yapay zekasısın.
    Sana verilen metin, bir PDF sayfasından alınmış TEK BİR ÖĞRENCİYE ait sınav karnesidir.
    Görevin, bu öğrencinin tüm bilgilerini eksiksizce çıkarıp tek bir JSON nesnesi içeren bir JSON dizisi olarak çıktı vermektir.

    # İSTENEN JSON YAPISI:
    `[{"examName": "$examName", "examType": "$examType", "studentNumber": "String", "fullName": "String", "className": "String", "totalCorrect": "double", "totalWrong": "double", "totalNet": "double", "score": "double", "overallRank": "int", "classRank": "int", "lessonResults": [{"lessonName": "String", "correct": "double", "wrong": "double", "net": "double"}]}]`
    
    # KESİN KURALLAR VE ESNEKLİKLER:
    1.  **Çıktı Formatı:** Çıktın, SADECE ve SADECE tek bir öğrenci nesnesi içeren, tam ve geçerli bir JSON dizisi olmalıdır. `[ { ... } ]`
    2.  **Anahtar Kelime Esnekliği:** Metindeki anahtar kelimeler farklılık gösterebilir. "ÖĞRENCİ NO" yerine "Öğr.No", "SN" veya sadece "Numara" yazabilir. "ADI SOYADI" yerine "İSİM" yazabilir. Bu varyasyonları anla ve veriyi doğru alanlara yerleştir.
    3.  **Dinamik Ders Algılama:** SANA BİR DERS LİSTESİ VERMİYORUM. Metnin içinde hangi dersler varsa (Türkçe, Matematik, Edebiyat, Coğrafya-1, Fizik vb.), o dersleri `lessonResults` dizisine ekle. Eğer sadece bir ders varsa (BRANŞ denemesi gibi), dizi tek elemanlı olsun. Metinde olmayan bir dersi ASLA ekleme.
    4.  **`examType` Alanı:** `examType` alanını sana verdiğim "$examType" değeriyle doldurman ZORUNLUDUR.
    5.  **Boş Veri Yönetimi:** Eksik veya okunamayan sayısal alanlar için 0, metin alanları için "Bilinmiyor" kullan.
    6.  **Sayı Formatı:** Ondalık sayılarda kesinlikle virgül (,) yerine nokta (.) kullan.

    # İŞLENECEK KARNE METNİ:
    $pageText
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deneme Sonuç Analizi', style: GoogleFonts.poppins())),
      body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'TYT', label: Text('TYT'), icon: Icon(Icons.school)),
            ButtonSegment<String>(value: 'AYT', label: Text('AYT'), icon: Icon(Icons.book)),
            ButtonSegment<String>(value: 'BRANŞ', label: Text('BRANŞ'), icon: Icon(Icons.pie_chart)),
          ],
          selected: {_selectedExamType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedExamType = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 30),

        if (_pickedFile != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(_pickedFile!.name, overflow: TextOverflow.ellipsis),
              subtitle: Text('${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB'),
            ),
          ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _pickPdf,
          icon: const Icon(Icons.upload_file),
          label: const Text('PDF Seç'),
        ),
        const SizedBox(height: 20),

        if (_pickedFile != null)
          _isProcessing
              ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_processingStatus, style: GoogleFonts.poppins(fontSize: 16))
              ]))
              : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white),
              onPressed: startAnalysis,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analizi Başlat'))
      ]))),
    );
  }
}