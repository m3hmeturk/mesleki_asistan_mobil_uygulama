import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class TestEnginePage extends StatefulWidget {
  final String testTitle;
  final List<Map<String, dynamic>> questions; // Soruları dışarıdan alacak

  const TestEnginePage({
    super.key, 
    required this.testTitle, 
    required this.questions,
  });

  @override
  State<TestEnginePage> createState() => _TestEnginePageState();
}

class _TestEnginePageState extends State<TestEnginePage> {
  int _currentIndex = 0;
  List<String> _userAnswers = []; // Kullanıcının seçtiği cevapların "özelliklerini" tutacağız

  void _answerQuestion(String selectedTrait) {
    setState(() {
      _userAnswers.add(selectedTrait);
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Test bittiyse sonuç ekranını göster
    if (_currentIndex >= widget.questions.length) {
      return _buildResultScreen();
    }

    // Test devam ediyorsa soruyu göster
    var currentQuestion = widget.questions[_currentIndex];
    double progress = (_currentIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İlerleme Çubuğu (Progress Bar)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Soru ${_currentIndex + 1} / ${widget.questions.length}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Soru Metni
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  currentQuestion['questionText'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Şıklar (Cevap Butonları)
            Expanded(
              flex: 3,
              child: ListView(
                children: (currentQuestion['answers'] as List<Map<String, String>>).map((answer) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => _answerQuestion(answer['trait']!), // Arka planda özelliği kaydet
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          answer['text']!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSaving = false; // Yüklenme animasyonu için

  Future<void> _sonuclariKaydet() async {
    setState(() => _isSaving = true);
    try {
      // 1. Kullanıcının verdiği cevaplar arasından en çok tekrar eden (baskın) özelliği bul
      var countMap = {};
      for (var trait in _userAnswers) {
        countMap[trait] = (countMap[trait] ?? 0) + 1;
      }
      String dominantTrait = _userAnswers.isNotEmpty 
          ? countMap.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : "Bilinmiyor";

      // 2. Testin başlığına göre veritabanındaki anahtar kelimeyi (test_type) belirle
      String testType = "kisilik"; 
      if (widget.testTitle.contains("Meslek")) testType = "meslek";
      if (widget.testTitle.contains("İngilizce")) testType = "ingilizce";
      if (widget.testTitle.contains("Liderlik")) testType = "liderlik";
      if (widget.testTitle.contains("Ortam")) testType = "calisma_ortami";
      if (widget.testTitle.contains("Motivasyon")) testType = "motivasyon";

      // 3. Firebase'den kullanıcı UID'sini al ve Flask'a gönder
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final response = await http.post(
          Uri.parse('http://10.24.2.85:5000/api/save_test'), // DİKKAT: Kendi yerel IP adresini kontrol et!
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode({
            "uid": user.uid,
            "test_type": testType,
            "result": dominantTrait
          }),
        );

        if (response.statusCode == 200) {
          print("Test başarıyla veritabanına işlendi!");
        }
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
    } finally {
      setState(() => _isSaving = false);
      if (mounted) {
        Navigator.pop(context); // Sayfayı kapat ve test menüsüne dön
      }
    }
  }

  // Test Bittiğinde Çıkacak Ekran (Güncellendi)
  Widget _buildResultScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Tamamlandı")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text("Harika İş Çıkardın!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                "Cevapların analiz edildi ve yapay zeka asistanının hafızasına aktarıldı.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _isSaving ? null : _sonuclariKaydet, // Tıklanınca yeni fonksiyon çalışır
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Sonuçları Kaydet ve Çık", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}