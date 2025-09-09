import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'give_books_page.dart';

class ConfirmUploadPage extends StatefulWidget {
  final List<File> imageFiles;
  final String materialType;

  const ConfirmUploadPage({
    super.key,
    required this.imageFiles,
    required this.materialType,
  });

  @override
  State<ConfirmUploadPage> createState() => _ConfirmUploadPageState();
}

class _ConfirmUploadPageState extends State<ConfirmUploadPage> {
  bool _isProcessing = false;
  List<dynamic> _rawParsedTopics = []; // Ham, işlenmemiş konuları burada saklayacağız

  Future<void> _processImagesWithAI() async {
    if (widget.imageFiles.isEmpty || !mounted) return;
    setState(() => _isProcessing = true);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String fullText = "";
    for (final imageFile in widget.imageFiles) {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      fullText += "${recognizedText.text}\n";
    }
    textRecognizer.close();

    if (fullText.trim().isEmpty) {
      if (mounted) {
        _showErrorDialog("Fotoğraflardan metin okunamadı.");
        setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API Anahtarı bulunamadı.');

      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final prompt = """Aşağıdaki metin, bir kitabın içindekiler kısmından alınmış ham bir OCR çıktısıdır. Bu metni analiz ederek yalnızca ana konuların başlıklarını ve bunlara karşılık gelen sayfa numaralarını çıkar ve JSON formatında listele.

Kurallar ve Detaylar:
1.  **Ana Konu Tespiti:** Bir satırı ana konu olarak belirlemek için şu kriterleri kullan:
    * Satır, "ÜNİTE", "BÖLÜM" gibi bir ana başlık kelimesi içeriyorsa.
    * Satır, genelde noktalı çizgiler (...) ile sayfa numarasından ayrılmış bir başlık içeriyorsa.
    * Satır, diğer satırlara göre daha büyük ve belirgin bir başlık içeriyorsa.
    * **Alt Başlıkları Filtrele:** Ana konunun altında yer alan ve genellikle daha kısa, daha az belirgin olan alt başlıkları veya 'Sayfa [X-Y]' gibi detayları tamamen göz ardı et.
2.  **İstenmeyen Kelimeleri Filtrele:** Aşağıdaki kelimeleri içeren satırları ve ilgili sayfa numaralarını kesinlikle çıktıya dahil etme:
    * Test, Kazanım Testi, Uygulama Testi, Konu Tarama Testi
    * Özel Test, Karma Test
    * Sorular, Soru Bankası
    * Cevap Anahtarları,You
    * Nefes Açar, Zihin Açar
    * Örnek, Çözümlü Örnek
    * Hatırlatma
4.  **Sayfa Aralığı:** Eğer bir başlığa ait metin içinde `[6-13]` gibi bir sayfa aralığı varsa, sadece başlangıç sayısını (bu örnekte 6) kullan.
5.  **Temizleme İşlemi:** Konu başlıklarını alırken, parantez içindeki `(Test 1-2-3)` gibi gereksiz metinleri veya satır sonundaki noktalama işaretlerini (`...`) temizle.
6.  **Sıralama:** Tüm ana konuları, sayfa numaralarına göre **küçükten büyüğe** doğru sırala. Sayfa numaraları string yerine sayısal değer olarak sıralanmalıdır.
7.  **Çıktı Formatı:** Çıktıyı aşağıdaki gibi, sıralanmış bir JSON listesi olarak ver. `sayfa` anahtarının değerini string olarak tut.

**Girdi Metni:**
$fullText

**Çıktı Formatı (yalnızca JSON):**
[
  {"konu": "Konu Adı", "sayfa": "Sayfa Numarası"},
  {"konu": "Konu Adı", "sayfa": "Sayfa Numarası"}
]
""";
      final response = await model.generateContent([Content.text(prompt)]);
      final cleanResponse = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsedData = jsonDecode(cleanResponse);

      parsedData.sort((a, b) {
        final pageA = int.tryParse(a['sayfa']?.toString() ?? '0') ?? 9999;
        final pageB = int.tryParse(b['sayfa']?.toString() ?? '0') ?? 9999;
        return pageA.compareTo(pageB);
      });

      if (mounted) {
        _rawParsedTopics = parsedData; // Ham veriyi sakla
        setState(() => _isProcessing = false);
        _showResultDialog(parsedData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog("Metin işlenirken bir hata oluştu: ${e.toString()}");
      }
    }
  }

  void _showResultDialog(List<dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İşlenen Konular (${results.length} adet)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index] as Map<String, dynamic>;
              final konu = item['konu'] ?? 'Konu bulunamadı';
              final sayfa = item['sayfa'] ?? '0';

              // Bitiş sayfasını hesapla ve önizlemede göster
              String endPageText;
              if (index < results.length - 1) {
                final nextItem = results[index + 1] as Map<String, dynamic>;
                final nextStartPage = int.tryParse(nextItem['sayfa']?.toString() ?? '0') ?? 0;
                endPageText = (nextStartPage - 1).toString();
              } else {
                endPageText = '...';
              }

              return ListTile(
                title: Text(konu.toString()),
                trailing: Text("$sayfa - $endPageText"), // İSTEDİĞİN GİBİ
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => GiveBooksPage(
                  topics: _rawParsedTopics, // GiveBooksPage'e ham veriyi gönderiyoruz
                  materialType: widget.materialType,
                ),
              ));
            },
            child: const Text('Onayla ve Devam Et'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.imageFiles.length} Sayfa Seçildi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemCount: widget.imageFiles.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(widget.imageFiles[index], fit: BoxFit.cover),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Yapay zeka analiz ediyor...', style: GoogleFonts.poppins(fontSize: 16)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : _processImagesWithAI,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text('Yapay Zeka ile Ayrıştır', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}