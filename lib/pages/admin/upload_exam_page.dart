import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; // YENİ: HTTP PAKETİ

// Modelimiz aynı, hiçbir değişiklik yok
class OgrenciDetayliSonuc {
  final int sira;
  final String ogrNo;
  final String adSoyad;
  final String sinif;
  final double genelNet;
  final double tytPuani;
  final Map<String, Map<String, double>> dersDetaylari;

  OgrenciDetayliSonuc({
    required this.sira,
    required this.ogrNo,
    required this.adSoyad,
    required this.sinif,
    required this.genelNet,
    required this.tytPuani,
    required this.dersDetaylari,
  });

  // Gelen JSON verisini bu modele çeviren yardımcı fonksiyon
  factory OgrenciDetayliSonuc.fromJson(Map<String, dynamic> json) {
    double parseToDouble(dynamic val) => double.tryParse(val.toString().replaceAll(',', '.')) ?? 0.0;
    int parseInt(dynamic val) => int.tryParse(val.toString()) ?? 0;

    return OgrenciDetayliSonuc(
      sira: parseInt(json['S.N.']),
      ogrNo: json['ÖĞR.NO'].toString(),
      adSoyad: json['ADI SOYADI'].toString(),
      sinif: json['SINIF'].toString(),
      genelNet: parseToDouble(json['N']),
      tytPuani: parseToDouble(json['TYT PUANI']),
      dersDetaylari: {
        'Türkçe': {'D': parseToDouble(json['TÜRKÇE_D']), 'Y': parseToDouble(json['TÜRKÇE_Y']), 'N': parseToDouble(json['TÜRKÇE_N'])},
        'Tarih': {'D': parseToDouble(json['TARİH_D']), 'Y': parseToDouble(json['TARİH_Y']), 'N': parseToDouble(json['TARİH_N'])},
        'Coğrafya': {'D': parseToDouble(json['COĞRAFYA_D']), 'Y': parseToDouble(json['COĞRAFYA_Y']), 'N': parseToDouble(json['COĞRAFYA_N'])},
        'Felsefe': {'D': parseToDouble(json['FELSEFE_D']), 'Y': parseToDouble(json['FELSEFE_Y']), 'N': parseToDouble(json['FELSEFE_N'])},
        'Din Kültürü': {'D': parseToDouble(json['DİN KÜLTÜR_D']), 'Y': parseToDouble(json['DİN KÜLTÜR_Y']), 'N': parseToDouble(json['DİN KÜLTÜR_N'])},
        'Matematik': {'D': parseToDouble(json['MATEMATİK_D']), 'Y': parseToDouble(json['MATEMATİK_Y']), 'N': parseToDouble(json['MATEMATİK_N'])},
        'Fizik': {'D': parseToDouble(json['FİZİK_D']), 'Y': parseToDouble(json['FİZİK_Y']), 'N': parseToDouble(json['FİZİK_N'])},
        'Kimya': {'D': parseToDouble(json['KİMYA_D']), 'Y': parseToDouble(json['KİMYA_Y']), 'N': parseToDouble(json['KİMYA_N'])},
        'Biyoloji': {'D': parseToDouble(json['BİYOLOJİ_D']), 'Y': parseToDouble(json['BİYOLOJİ_Y']), 'N': parseToDouble(json['BİYOLOJİ_N'])},
      },
    );
  }
}

class UploadExamPage extends StatefulWidget {
  const UploadExamPage({Key? key}) : super(key: key);

  @override
  State<UploadExamPage> createState() => _UploadExamPageState();
}

class _UploadExamPageState extends State<UploadExamPage> {
  List<OgrenciDetayliSonuc> _ogrenciler = [];
  bool _isLoading = false;
  String? _dosyaAdi;

  // --- YENİ: PDF SEÇEN VE BULUTA GÖNDEREN FONKSİYON ---
  Future<void> _dosyaSecVeAnalizEt() async {
    setState(() {
      _isLoading = true;
      _ogrenciler = [];
      _dosyaAdi = null;
    });

    try {
      // 1. Adım: Kullanıcıdan PDF dosyası seçtiriyoruz
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        setState(() { _dosyaAdi = fileName; });

        // 2. Adım: Sihirli kutunun URL'ini hazırlıyoruz
        // !! DİKKAT: BURAYA KENDİ URL'İNİ YAPIŞTIR !!
        // Terminalde deploy sonrası çıkan URL'i buraya yapıştır.
        const String cloudFunctionUrl = 'https://process-exam-pdf-ixd5x4vd3a-ew.a.run.app';

        // 3. Adım: PDF dosyasını buluta göndermek için HTTP isteği oluşturuyoruz
        var request = http.MultipartRequest('POST', Uri.parse(cloudFunctionUrl));
        request.files.add(http.MultipartFile.fromBytes(
          'file', // Bu 'file' ismi, Python kodundaki request.files['file'] ile aynı olmalı
          fileBytes,
          filename: fileName,
        ));

        // 4. Adım: İsteği gönder ve cevabı bekle
        var response = await request.send();

        if (response.statusCode == 200) {
          // Başarılı: Gelen temiz JSON verisini işle
          final responseBody = await response.stream.bytesToString();
          final List<dynamic> jsonData = json.decode(responseBody);

          setState(() {
            _ogrenciler = jsonData.map((item) => OgrenciDetayliSonuc.fromJson(item)).toList();
            _isLoading = false;
          });
        } else {
          // Başarısız: Sunucudan gelen hatayı göster
          final errorBody = await response.stream.bytesToString();
          throw Exception('Sunucu Hatası: ${response.statusCode} - $errorBody');
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // Arayüz kodunun geri kalanı tamamen aynı

  void _showDetayPenceresi(OgrenciDetayliSonuc ogrenci) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(ogrenci.adSoyad, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${ogrenci.sinif} - ${ogrenci.ogrNo}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: ogrenci.dersDetaylari.entries.map((ders) {
                      return _buildDersDetayKarti(
                        dersAdi: ders.key,
                        detaylar: ders.value,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dosyaAdi ?? 'Sınav Sonucu Yükle'),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("PDF işleniyor, bu işlem\nbiraz zaman alabilir...", textAlign: TextAlign.center),
          ],
        ),
      )
          : _ogrenciler.isEmpty
          ? _buildDosyaSecimEkrani()
          : _buildOgrenciListesi(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _dosyaSecVeAnalizEt,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF Seç'),
      ),
    );
  }

  Widget _buildDosyaSecimEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Öğrenci sonuçlarını işlemek için\nbir PDF dosyası seçin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _dosyaSecVeAnalizEt,
            child: const Text('PDF Dosyası Seç'),
          ),
        ],
      ),
    );
  }

  Widget _buildOgrenciListesi() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _ogrenciler.length,
      itemBuilder: (context, index) {
        final ogrenci = _ogrenciler[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetayPenceresi(ogrenci),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(ogrenci.sira.toString()),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ogrenci.adSoyad, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${ogrenci.sinif} - No: ${ogrenci.ogrNo}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip('Genel Puan', ogrenci.tytPuani.toStringAsFixed(2), Colors.blue),
                      _buildInfoChip('Genel Net', ogrenci.genelNet.toStringAsFixed(2), Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Chip(
          label: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  Widget _buildDersDetayKarti({required String dersAdi, required Map<String, double> detaylar}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dersAdi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetayItem('Doğru', detaylar['D']!.toInt().toString(), Colors.green),
                _buildDetayItem('Yanlış', detaylar['Y']!.toInt().toString(), Colors.red),
                _buildDetayItem('Net', detaylar['N']!.toStringAsFixed(2), Colors.blue),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetayItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}