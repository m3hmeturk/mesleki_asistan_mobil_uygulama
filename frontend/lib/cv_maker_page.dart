import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // 🚀 Timer için gerekli
import 'cv_history_page.dart';

class CVMakerPage extends StatefulWidget {
  const CVMakerPage({super.key});

  @override
  State<CVMakerPage> createState() => _CVMakerPageState();
}

class _CVMakerPageState extends State<CVMakerPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // 🚀 YENİ: Canlı Cüzdan Değişkenleri
  int _jetonBakiye = 0;
  bool _isBakiyeLoading = true;

  // 🚀 YENİ: Dinamik Yükleme Ekranı Değişkenleri
  Timer? _loadingTimer;
  int _loadingTextIndex = 0;
  final List<String> _loadingTexts = [
    "Yapay zeka profilinizi inceliyor...",
    "Mükemmel kelimeler seçiliyor...",
    "Becerileriniz profesyonel dile çevriliyor...",
    "GitHub depolarınız taranıyor...",
    "Tasarım şablonu uygulanıyor...",
    "PDF dizgisi hazırlanıyor...",
    "Neredeyse hazır..."
  ];

  // 1. Adım: Kişisel Bilgiler
  final _adController = TextEditingController();
  final _meslekController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _linkedinController = TextEditingController();

  // 2. Adım: Eğitim ve Deneyim
  final _egitimController = TextEditingController();
  final _deneyimController = TextEditingController();

  // 3. Adım: Yetenekler ve Projeler
  final _yeteneklerController = TextEditingController();
  final _projelerController = TextEditingController();
  final _dillerController = TextEditingController();
  final _githubController = TextEditingController();

  // 4. Adım: Şablon ve Dil Seçimi
  String _secilenSablon = 'klasik';
  String _cvDili = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _bakiyeSorgula(); // 🚀 Sayfa açılır açılmaz bakiyeyi Python'dan çek
  }

  // 🚀 YENİ: Veritabanından Güncel Bakiyeyi Çeken Fonksiyon
  Future<void> _bakiyeSorgula() async {
    final url = Uri.parse('http://10.161.28.101:5000/api/get_user');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonim_kullanici'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _jetonBakiye = data['credits'] ?? 0;
          _isBakiyeLoading = false;
        });
      }
    } catch (e) {
      print("Bakiye çekilemedi: $e");
      setState(() => _isBakiyeLoading = false);
    }
  }

  Future<void> _generateAndDownloadCV() async {
    setState(() {
      _isLoading = true;
      _loadingTextIndex = 0;
    });

    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          if (_loadingTextIndex < _loadingTexts.length - 1) {
            _loadingTextIndex++;
          }
        });
      }
    });

    final url = Uri.parse('http://10.161.28.101:5000/api/generate_cv');

    // 🚀 1. YENİ: Benzersiz Dosya Adını Oluşturuyoruz (Timestamp ile)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final olusturulanDosyaAdi = "CV_$timestamp.pdf";

    final Map<String, dynamic> requestBody = {
      'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonim_kullanici',
      'sablon_id': _secilenSablon,
      'cv_dili': _cvDili,
      'github_username': _githubController.text.trim(),
      'dosya_adi': olusturulanDosyaAdi, // 🚀 2. YENİ: Python'a bu ismi gönderiyoruz!
      'bilgiler': {
        'ad': _adController.text,
        'meslek': _meslekController.text,
        'email': _emailController.text,
        'telefon': _telefonController.text,
        'linkedin': _linkedinController.text,
        'egitim': _egitimController.text,
        'deneyim': _deneyimController.text,
        'yetenekler': _yeteneklerController.text,
        'projeler': _projelerController.text,
        'diller': _dillerController.text,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 402) {
        final errorData = json.decode(response.body);
        _showBakiyeYetersizDialog(errorData['required'], errorData['current']);
        return; 
      }

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        
        // 🚀 3. YENİ: Telefona da Python'a gönderdiğimiz benzersiz isimle kaydediyoruz!
        final file = File('${dir.path}/$olusturulanDosyaAdi');

        await file.writeAsBytes(bytes);
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV Başarıyla Üretildi! Açılıyor...')),
        );

        OpenFilex.open(file.path);
        _bakiyeSorgula(); 

      } else {
        throw Exception('Sunucu Hatası: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      _loadingTimer?.cancel();
      setState(() {
        _isLoading = false;
      });
    }
  }
  // 🚀 YENİ: Bakiye Yetersiz Uyarı Penceresi
  void _showBakiyeYetersizDialog(int gereken, int mevcut) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Yetersiz Jeton!'),
          ],
        ),
        content: Text('Bu işlem $gereken Jeton gerektiriyor ancak cüzdanınızda $mevcut Jeton bulunuyor.\n\nLütfen jeton satın alın veya reklam izleyin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // İleride buraya mağaza sayfasına yönlendirme eklenecek
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mağaza yakında eklenecek!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
            child: const Text('Jeton Kazan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 YENİ: Modern, Koyu ve Sayfaya Uyumlu AppBar Tasarımı
      appBar: AppBar(
        // Sol Taraftaki Başlık ve İkon Alanı
        title: Row(
          children: [
            // 1. En Sola: Geçmiş İkonu
            IconButton(
              icon: const Icon(Icons.history_toggle_off_rounded, color: Colors.white70, size: 28), // Daha modern bir ikon seçtik
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CVHistoryPage()),
                );
              },
              tooltip: 'Geçmiş CV\'lerim',
            ),
            const SizedBox(width: 10), // İkon ve başlık arası boşluk

            // 2. Başlık: "CV Fabrikası"
            const Text(
              '<--CV ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
        // Sağ Taraftaki Jeton Alanı
        actions: [
          // Mevcut Jeton Göstergesi (Tasarımını biraz daha şıklaştırdık)
          Container(
            margin: const EdgeInsets.only(right: 15, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              // Jetonun arkasını hafif şeffaf bir gri yaparak koyu temaya uydurduk
              color: Colors.white.withOpacity(0.08), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12), // Çok ince bir çerçeve
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, size: 20, color: Colors.amber),
                const SizedBox(width: 6),
                _isBakiyeLoading 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2))
                  : Text('$_jetonBakiye', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.amber)),
              ],
            ),
          )
        ],
        
        // 🚀 EN ÖNEMLİ KISIM: Morluğu siliyoruz!
        // Arka planı koyu tema ile aynı yapıyoruz.
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        elevation: 0, // AppBar altındaki gölgeyi kaldırıp düz durmasını sağladık
        centerTitle: false, // Başlığı sola hizala (Row içinde kendimiz hizaladık)
        automaticallyImplyLeading: false, // Geri butonunu (varsa) gizle, biz yerleştirdik
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.deepPurple),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      _loadingTexts[_loadingTextIndex],
                      key: ValueKey<int>(_loadingTextIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            )
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep += 1);
                } else {
                  _generateAndDownloadCV();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                final isLastStep = _currentStep == 3;
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLastStep ? Colors.green : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          // 🚀 DİNAMİK FİYAT BUTONU
                          child: Text(isLastStep 
                            ? '🚀 ÜRET (${(_secilenSablon == 'klasik' ? 2 : 30) + (_githubController.text.isNotEmpty ? 20 : 0)} Jeton)' 
                            : 'Devam Et'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Geri'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  isActive: _currentStep >= 0,
                  title: const Text('Kişisel Bilgiler', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person))),
                      TextField(controller: _meslekController, decoration: const InputDecoration(labelText: 'Hedef Meslek', prefixIcon: Icon(Icons.work))),
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email))),
                      TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone))),
                      TextField(controller: _linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL', prefixIcon: Icon(Icons.link))),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 1,
                  title: const Text('Eğitim ve Deneyim', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      TextField(controller: _egitimController, maxLines: 3, decoration: const InputDecoration(labelText: 'Eğitim Bilgileri', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _deneyimController, maxLines: 3, decoration: const InputDecoration(labelText: 'İş ve Staj Deneyimleri', border: OutlineInputBorder())),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 2,
                  title: const Text('Yetenekler ve Projeler', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      TextField(controller: _yeteneklerController, maxLines: 2, decoration: const InputDecoration(labelText: 'Yetenekler', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _projelerController, maxLines: 3, decoration: const InputDecoration(labelText: 'Projeler ve Başarılar', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _dillerController, decoration: const InputDecoration(labelText: 'Yabancı Diller', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      // 🚀 YENİ EKLENEN GITHUB KUTUSU
                      TextField(
                        controller: _githubController, 
                        decoration: InputDecoration(
                          labelText: 'GitHub Kullanıcı Adı (+20 Jeton - Premium)', 
                          prefixIcon: const Icon(Icons.code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.amber.shade50
                        ),
                        onChanged: (value) => setState(() {}), // Kutuyu doldurunca fiyatın anında güncellenmesi için
                      ),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 3,
                  title: const Text('Şablon ve Ayarlar', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CV Dili:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Türkçe', label: Text('Türkçe')),
                          ButtonSegment(value: 'İngilizce', label: Text('İngilizce (AI)')),
                        ],
                        selected: {_cvDili},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _cvDili = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Tasarım Şablonu:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: _secilenSablon,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'klasik', child: Text('Kurumsal Klasik (2 Jeton)')),
                          DropdownMenuItem(value: 'modern', child: Text('Modern Minimalist (30 Jeton)')),
                          DropdownMenuItem(value: 'teknik', child: Text('Teknofest/TÜBİTAK Özel (30 Jeton)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _secilenSablon = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      
    );
  }
}