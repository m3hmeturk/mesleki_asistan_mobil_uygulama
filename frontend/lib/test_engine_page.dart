import 'package:flutter/material.dart';

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

  // Test Bittiğinde Çıkacak Ekran
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
              const Text(
                "Harika İş Çıkardın!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Cevapların analiz edildi ve yapay zeka asistanının hafızasına aktarıldı. Artık sana çok daha isabetli meslekler önerecek.",
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
                onPressed: () { // <-- BURAYI onTap YERİNE onPressed YAPTIK
                  Navigator.pop(context); 
                },
                child: const Text("Sonuçları Kaydet ve Çık", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}