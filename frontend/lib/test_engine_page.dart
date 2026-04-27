import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class TestEnginePage extends StatefulWidget {
  final String testId;
  final String testBaslik;

  const TestEnginePage({Key? key, required this.testId, required this.testBaslik}) : super(key: key);

  @override
  _TestEnginePageState createState() => _TestEnginePageState();
}

class _TestEnginePageState extends State<TestEnginePage> {
  bool _isLoading = true;
  List<dynamic> _sorular = [];
  int _mevcutSoruIndex = 0;
  
  // Hangi soruya hangi seçeneğin 'deger'i verildiğini tutar
  Map<String, String> _cevaplar = {}; 
  
  // O an ekrandaki soruda hangi şıkkın (index) seçili olduğunu tutar
  int? _secilenCevapIndex; 

  @override
  void initState() {
    super.initState();
    _sorulariGetir();
  }

  Future<void> _sorulariGetir() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/test/${widget.testId}/questions');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _sorular = data['sorular'] ?? [];
          _isLoading = false;
        });
      } else {
        _hataGoster("Sorular alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      _hataGoster("Bağlantı hatası: $e");
    }
  }

  void _hataGoster(String mesaj) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  void _sonrakiSoru() {
    if (_secilenCevapIndex == null) return; // Seçim yapılmadıysa ilerleme

    final gecerliSoru = _sorular[_mevcutSoruIndex];
    final secilenCevap = gecerliSoru['cevaplar'][_secilenCevapIndex];

    // 1. Cevabı hafızaya kaydet
    _cevaplar[gecerliSoru['id']] = secilenCevap['deger'];

    // 2. Sonraki soruya geç veya bitir
    if (_mevcutSoruIndex < _sorular.length - 1) {
      setState(() {
        _mevcutSoruIndex++;
        _secilenCevapIndex = null; // Yeni soruda seçimi sıfırla
      });
    } else {
      _testiBitir();
    }
  }

  Future<void> _testiBitir() async {
    // 1. Ekranı karart ve Yükleniyor animasyonu göster (Sanki yapay zeka düşünüyor hissi)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
    );

    try {
      // 2. Cevapları Sunucuya (DigitalOcean'a) Fırlat
      final url = Uri.parse('${ApiConfig.baseUrl}/api/test/${widget.testId}/submit');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cevaplar': _cevaplar}),
      );

      // 3. Yükleniyor animasyonunu kapat
      if (!mounted) return;
      Navigator.pop(context); 

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final baskinOzellik = data['baskin_ozellik'] ?? 'Belirsiz';

        // 4. Büyüleyici Sonuç Ekranını Göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            // ❌ backgroundColor satırını tamamen sildik! Artık temaya göre otomatik renk alacak.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), 
              side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.5))
            ),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent), // İkon mor kalabilir, iki modda da şık durur
                SizedBox(width: 10),
                // ❌ style içindeki "color: Colors.white," kısmını sildik! 
                Text(
                  "Analiz Tamamlandı!", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ❌ color: Colors.grey sildik, tema otomatik siyah/beyaz yapacak
                const Text("Kariyer DNA'na yeni bir yapı taşı eklendi.", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  // Arka planın %10 mor olması iki temada da efsane durur, buraya dokunmuyoruz
                  decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      // ❌ color: Colors.grey sildik
                      const Text("Baskın Özelliğin", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      // ✅ Mor renk iki temada da çok şık durduğu için bu kalıyor!
                      Text(baskinOzellik, style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Pop-up'ı kapat
                  Navigator.pop(context); // Test listesi sayfasına geri dön
                },
                // ❌ Buton yazısındaki beyaz rengi sildik, yerine mor verdik ki açık/koyu fark etmeksizin butona benzesin
                child: const Text("Harika, Devam Et", style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
              )
            ],
          )
        );
      } else {
        _hataGoster("Sonuçlar analiz edilemedi (Hata: ${response.statusCode})");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Hata olursa da yükleniyoru kapat
      _hataGoster("Bağlantı hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: AppBar(title: Text(widget.testBaslik), backgroundColor: const Color(0xFF1C1C1E)),
        body: const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    if (_sorular.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: AppBar(title: Text(widget.testBaslik), backgroundColor: const Color(0xFF1C1C1E)),
        body: const Center(child: Text("Bu teste henüz soru eklenmemiş.", style: TextStyle(color: Colors.grey))),
      );
    }

    final gecerliSoru = _sorular[_mevcutSoruIndex];
    List<dynamic> cevapSecenekleri = gecerliSoru['cevaplar'] ?? [];
    final ilerlemeOrani = (_mevcutSoruIndex + 1) / _sorular.length;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(widget.testBaslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ÜST KISIM: İlerleme Çubuğu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Soru ${_mevcutSoruIndex + 1} / ${_sorular.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("%${(ilerlemeOrani * 100).toInt()}", style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ilerlemeOrani,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            
            const SizedBox(height: 30),
            
            // ORTA KISIM: Soru Metni
            Text(
              gecerliSoru['soru'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.4, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // ALT KISIM: Seçenekler (Şıklar)
            Expanded(
              child: ListView.builder(
                itemCount: cevapSecenekleri.length,
                itemBuilder: (context, index) {
                  final cevap = cevapSecenekleri[index];
                  final bool seciliMi = _secilenCevapIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _secilenCevapIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: seciliMi ? Colors.deepPurpleAccent.withOpacity(0.2) : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: seciliMi ? Colors.deepPurpleAccent : Colors.grey.shade800.withOpacity(0.5),
                          width: seciliMi ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Şıkların başındaki Yuvarlak Seçim İkonu
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: seciliMi ? Colors.deepPurpleAccent : Colors.grey.shade600,
                                width: 2,
                              ),
                              color: seciliMi ? Colors.deepPurpleAccent : Colors.transparent,
                            ),
                            child: seciliMi 
                                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              cevap['metin'],
                              style: TextStyle(
                                color: seciliMi ? Colors.white : Colors.grey.shade300,
                                fontSize: 16,
                                fontWeight: seciliMi ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // BUTON: Sonraki Soru veya Testi Bitir (Sadece seçim yapılınca aktif olur)
            ElevatedButton(
              onPressed: _secilenCevapIndex == null ? null : _sonrakiSoru,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                disabledBackgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                _mevcutSoruIndex < _sorular.length - 1 ? "Sonraki Soru  →" : "Testi Bitir  ✅",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: _secilenCevapIndex == null ? Colors.grey.shade500 : Colors.white
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}