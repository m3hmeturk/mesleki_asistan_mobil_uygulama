import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart'; 
import 'test_engine_page.dart'; 

// 🗑️ DÜZELTME: Buradaki gereksiz global değişkenler (kirlilik) tamamen silindi!

class TestsPage extends StatefulWidget {
  const TestsPage({Key? key}) : super(key: key);

  @override
  _TestsPageState createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  // Değişkenler sadece ait oldukları yerde, yani State içinde!
  bool _isLoading = true;
  List<dynamic> _testList = [];
  List<String> _tamamlananTestler = []; 

  @override
  void initState() {
    super.initState();
    _testleriGetir();
  }

  // 1. API'DEN TESTLERİ ÇEKEN FONKSİYON
  Future<void> _testleriGetir() async {
    try {
      // 1. Önce test listesini çek
      final url = Uri.parse('${ApiConfig.baseUrl}/api/tests');
      final response = await http.get(url);

      // 2. Sonra kullanıcının tamamladığı testleri çek
      final progressUrl = Uri.parse('${ApiConfig.baseUrl}/api/user/progress');
      final progressResponse = await http.get(progressUrl);

      if (response.statusCode == 200 && progressResponse.statusCode == 200) {
        final progressData = json.decode(utf8.decode(progressResponse.bodyBytes));
        
        setState(() {
          _testList = json.decode(utf8.decode(response.bodyBytes));
          // Tamamlanan testlerin ID'lerini String listesine çeviriyoruz
          _tamamlananTestler = List<String>.from(progressData['tamamlanan_testler'] ?? []);
          _isLoading = false;
        });
      } else {
        _hataGoster("Sunucu hatası oluştu.");
      }
    } catch (e) {
      _hataGoster("Bağlantı hatası: $e");
    }
  }

  void _hataGoster(String mesaj) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  IconData _ikonSec(String iconName) {
    switch (iconName) {
      case 'Brain': return Icons.psychology;
      case 'Briefcase': return Icons.work_outline;
      case 'Languages': return Icons.language;
      case 'Lock': return Icons.lock_outline;
      case 'Desktop': return Icons.desktop_windows; // Yeni eklenen testler için garanti
      case 'Heart': return Icons.favorite_outline; // Yeni eklenen testler için garanti
      default: return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> grupluTestler = {};
    for (var test in _testList) {
      String kategori = test['kategori'] ?? 'Diğer';
      if (!grupluTestler.containsKey(kategori)) {
        grupluTestler[kategori] = [];
      }
      grupluTestler[kategori]!.add(test);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), 
      appBar: AppBar(
        title: const Text('Kariyer Testleri', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DİNAMİK İLERLEME KARTI (Toplam test sayısını gönderiyoruz)
                  _buildGenelIlerlemeKarti(_testList.length, _tamamlananTestler.length),
                  const SizedBox(height: 24),

                  // Mevcut Test Katmanları (Akordiyonlar)
                  ...grupluTestler.entries.map((grup) {
                    final kategoriAdi = grup.key;
                    final testler = grup.value;
                    final altBaslik = testler.first['kategori_alt_baslik'] ?? '';
                    final iconStr = testler.first['kategori_ikon'] ?? '';
                    final premiumMu = testler.first['premium_mu'] ?? false;

                    return _buildGenisleyenKart(kategoriAdi, altBaslik, iconStr, premiumMu, testler);
                  }).toList(),

                  const SizedBox(height: 16),
                  
                  // 2. En Alttaki Bilgi/Motivasyon Afişi
                  _buildBilgiAfisi(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- DİNAMİKLEŞTİRİLMİŞ İLERLEME KARTI ---
  Widget _buildGenelIlerlemeKarti(int toplamTest, int tamamlananTest) {
    // Matematiksel hesaplamalar (Sıfıra bölünme hatasını önlemek için kontrol)
    double ilerlemeYuzdesi = toplamTest > 0 ? (tamamlananTest / toplamTest) : 0.0;
    int yuzdeGosterim = (ilerlemeYuzdesi * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurpleAccent.shade400, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📊 Kariyer DNA'n", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text("Gelişim: %$yuzdeGosterim", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ilerlemeYuzdesi,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$tamamlananTest/$toplamTest test tamamlandı. Mükemmel eşleşme için devam et!", 
            style: const TextStyle(color: Colors.white70, fontSize: 13)
          ),
        ],
      ),
    );
  }

  Widget _buildBilgiAfisi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Neden Test Çözmeliyim?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text("Test sonuçların Kariyer DNA'nı oluşturur. Yapay zeka asistanın bu verilerle sana özel CV yazar ve iş önerir.", 
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenisleyenKart(String baslik, String altBaslik, String iconStr, bool premiumMu, List<dynamic> testler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade800.withOpacity(0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          initiallyExpanded: baslik.contains("Kişilik") || baslik.contains("KATMAN 1"), 
          iconColor: Colors.white,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: premiumMu ? Colors.orange.withOpacity(0.2) : Colors.deepPurpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_ikonSec(iconStr), color: premiumMu ? Colors.orange : Colors.deepPurpleAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                        if (premiumMu) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: const Text("5 JETON", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(altBaslik, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          
          children: testler.map((test) {
            // 🌟 YENİ ZEKA: Bu test daha önce tamamlanmış mı?
            bool testTamamlandi = _tamamlananTestler.contains(test['_id']);

            return Container(
              padding: const EdgeInsets.only(left: 32, right: 16, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol taraftaki ağaç çizgisi
                  Container(width: 2, height: 40, color: Colors.grey.shade800, margin: const EdgeInsets.only(right: 16, top: 10)),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242426),
                        borderRadius: BorderRadius.circular(12),
                        // 🌟 DİNAMİK TASARIM: Tamamlanmışsa hafif yeşilimsi çerçeve
                        border: Border.all(
                          color: testTamamlandi 
                              ? Colors.green.withOpacity(0.4) 
                              : Colors.grey.shade800.withOpacity(0.3),
                          width: testTamamlandi ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(test['baslik'] ?? 'Test', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                              // 🌟 DİNAMİK ROZET: Çözüldüyse "Tamamlandı" yazısı
                              if (testTamamlandi)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("✅ Tamamlandı", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text("${test['soru_sayisi']} Soru", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text("~${test['sure_dk']} dk", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TestEnginePage(
                                      testId: test['_id'],
                                      testBaslik: test['baslik'],
                                    ),
                                  ),
                                ).then((_) {
                                  // Kullanıcı testten geri döndüğü an progress'i güncelliyoruz!
                                  _testleriGetir();
                                });
                              },
                              // 🌟 DİNAMİK BUTON: Çözüldüyse Refresh ikonu, çözülmediyse Play ikonu
                              icon: Icon(
                                testTamamlandi ? Icons.refresh : Icons.play_arrow, 
                                size: 16, 
                                color: Colors.white
                              ),
                              // 🌟 DİNAMİK YAZI VE RENK
                              label: Text(testTamamlandi ? "Tekrar Çöz" : "Başla", style: const TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: testTamamlandi ? Colors.grey.shade700 : Colors.deepPurpleAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}