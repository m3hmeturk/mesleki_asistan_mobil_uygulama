import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // 🚀 Timer için gerekli
import 'cv_history_page.dart';
import 'api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

File? _secilenFoto;


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

  // 💾 Hafızaya Kaydetme
Future<void> _taslakKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('ad', _adController.text);
  await prefs.setString('meslek', _meslekController.text);
  await prefs.setString('email', _emailController.text);
  await prefs.setString('telefon', _telefonController.text);
  await prefs.setString('linkedin', _linkedinController.text);
  await prefs.setString('egitim', _egitimController.text);
  await prefs.setString('deneyim', _deneyimController.text);
  await prefs.setString('yetenekler', _yeteneklerController.text);
  await prefs.setString('projeler', _projelerController.text);
  await prefs.setString('diller', _dillerController.text);
  await prefs.setString('secilen_sablon', _secilenSablon);
}

// 📂 Hafızadan Geri Yükleme
Future<void> _taslakYukle() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _adController.text = prefs.getString('ad') ?? '';
    _meslekController.text = prefs.getString('meslek') ?? '';
    _emailController.text = prefs.getString('email') ?? '';
    _telefonController.text = prefs.getString('telefon') ?? '';
    _linkedinController.text = prefs.getString('linkedin') ?? '';
    _egitimController.text = prefs.getString('egitim') ?? '';
    _deneyimController.text = prefs.getString('deneyim') ?? '';
    _yeteneklerController.text = prefs.getString('yetenekler') ?? '';
    _projelerController.text = prefs.getString('projeler') ?? '';
    _dillerController.text = prefs.getString('diller') ?? '';
    _secilenSablon = prefs.getString('secilen_sablon') ?? 'modern';
  });
}

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

  // 🚀 GÜNCELLENDİ: İkonlar yerine resim yolları eklendi
  final List<Map<String, dynamic>> _sablonListesi = [
    {
      "id": "modern", 
      "ad": "Modern CV", 
      "alt_baslik": "Ferah ve Çift Kolonlu",
      "renk": Colors.teal, 
      // 👇 İkon yerine resim yolunu yazıyoruz
      "resim_yolu": "assets/images/modern_onizleme.jpg"
    },
    {
      "id": "klasik", 
      "ad": "Klasik Kurumsal", 
      "alt_baslik": "Resmi ve ATS Uyumlu",
      "renk": Colors.blueGrey, 
      "resim_yolu": "assets/images/klasik_onizleme.jpg"
    },
    {
      "id": "teknik", 
      "ad": "Teknik IT", 
      "alt_baslik": "Yazılımcılara Özel",
      "renk": Colors.green.shade700, 
      "resim_yolu": "assets/images/teknik_onizleme.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _taslakYukle();
    _bakiyeSorgula(); // 🚀 Sayfa açılır açılmaz bakiyeyi Python'dan çek
  }
  Future<void> _fotoSec() async {
    final picker = ImagePicker();
    
    // 🚀 ÇÖZÜM BURADA: Fotoğrafın enini ve boyunu maksimum 400 piksel yapıyoruz.
    // Böylece 1.5 milyon karakter olan metin, 20-30 bin karaktere düşecek!
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70, // Kaliteyi biraz artırabiliriz boyut zaten küçülecek
      maxWidth: 400,    // Maksimum genişlik
      maxHeight: 400,   // Maksimum yükseklik
    ); 
    
    if (pickedFile != null) {
      setState(() {
        _secilenFoto = File(pickedFile.path);
      });
      
    }
  }
  // 🚀 YENİ: Veritabanından Güncel Bakiyeyi Çeken Fonksiyon
  Future<void> _bakiyeSorgula() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/get_user');
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
    // 🛡️ Boş Alan Kontrolü
    if (_adController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _meslekController.text.trim().isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen Ad, E-posta ve Meslek alanlarını doldurun!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // Hata varsa fonksiyonu burada bitir, Python'a gitme!
    }
    

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

    final url = Uri.parse('${ApiConfig.baseUrl}/api/generate_cv');

    // Benzersiz Dosya Adını Oluşturuyoruz
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final olusturulanDosyaAdi = "CV_$timestamp.pdf";

    try {
      // 🚀 0. YENİ: YAPAY ZEKA İÇİN KARİYER DNA'SINI ÇEKİYORUZ!
      String dnaContext = await AiService.getKariyerDNAContext();

      // 🚀 1. JSON yerine Multipart (Çok Parçalı Form) İstek oluşturuyoruz
      var request = http.MultipartRequest('POST', url);

      // 🚀 2. Normal Metin Verilerini Ekliyoruz (request.fields)
      request.fields['uid'] = FirebaseAuth.instance.currentUser?.uid ?? 'anonim_kullanici';
      request.fields['sablon_id'] = _secilenSablon;
      request.fields['cv_dili'] = _cvDili;
      request.fields['github_username'] = _githubController.text.trim();
      request.fields['dosya_adi'] = olusturulanDosyaAdi;
      
      // 🌟 YENİ: DNA bilgisini de sunucuya gönderiyoruz!
      request.fields['dna_context'] = dnaContext; 
      
      // Bilgiler kısmını artık iç içe değil, doğrudan ekliyoruz
      request.fields['ad'] = _adController.text;
      request.fields['meslek'] = _meslekController.text;
      request.fields['email'] = _emailController.text;
      request.fields['telefon'] = _telefonController.text;
      request.fields['linkedin'] = _linkedinController.text;
      request.fields['egitim'] = _egitimController.text;
      request.fields['deneyim'] = _deneyimController.text;
      request.fields['yetenekler'] = _yeteneklerController.text;
      request.fields['projeler'] = _projelerController.text;
      request.fields['diller'] = _dillerController.text;

      // 🚀 3. FOTOĞRAF DOSYASINI EKLİYORUZ (request.files)
      if (_secilenFoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profil_foto', // Python bu ismi bekliyor
          _secilenFoto!.path, // Doğrudan dosyanın telefondaki yolunu veriyoruz
        ));
        print("📸 AJAN 1 (FLUTTER): Gerçek fotoğraf dosyası eklendi -> ${_secilenFoto!.path}");
      } else {
        print("📸 AJAN 1 (FLUTTER): Fotoğraf seçilmedi, resimsiz devam ediliyor.");
      }

      // 🚀 4. İsteği gönder ve yanıtı bekle
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Bakiye yetersiz durumu (Senin yazdığın kod aynen duruyor)
      if (response.statusCode == 402) {
        final errorData = json.decode(response.body);
        _showBakiyeYetersizDialog(errorData['required'], errorData['current']);
        return; 
      }

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        
        // Güvenlik: Dosya adının sonuna zorla .pdf uzantısı ekliyoruz
        String guvenliDosyaAdi = olusturulanDosyaAdi;
        if (!guvenliDosyaAdi.toLowerCase().endsWith('.pdf')) {
          guvenliDosyaAdi = '$guvenliDosyaAdi.pdf';
        }
        
        final file = File('${dir.path}/$guvenliDosyaAdi');
        await file.writeAsBytes(bytes);
        
        // Bakiye güncelleniyor
        _bakiyeSorgula(); 
        
        // Başarı diyaloğu dosya yolu ile çağrılıyor
        _basariDialogGoster(file.path);
        
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

  // 🚀 GÜNCELLENDİ: Büyük Önizlemeli ve Şık Şablon Galerisi
  Widget _buildSablonGalerisi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CV Şablonunuzu Seçin",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320, // 👈 DİKKAT: A4 boyutunu yansıtması için yüksekliği 320 yaptık!
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _sablonListesi.length,
            itemBuilder: (context, index) {
              final sablon = _sablonListesi[index];
              final bool isSelected = _secilenSablon == sablon['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _secilenSablon = sablon['id'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 190, // 👈 DİKKAT: Kart genişliğini 190 yaptık!
                  margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? sablon['renk'] : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: sablon['renk'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 🚀 YENİ: Resim kısmı (Tüm üst alanı kenardan kenara kaplar)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                              child: Image.asset(
                                sablon['resim_yolu'],
                                fit: BoxFit.cover, // Resmi sündürmez
                                alignment: Alignment.topCenter, // CV'nin üst kısmına odaklanır
                              ),
                            ),
                          ),
                          // Yazı Kısmı (Altta)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? sablon['renk'].withOpacity(0.1) : Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sablon['ad'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? sablon['renk'] : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sablon['alt_baslik'],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Seçili Tik İşareti (Sağ üst köşe)
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(Icons.check_circle, color: sablon['renk'], size: 26),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  // 🚀 YENİ: Dosya yolunu (filePath) alan ve butona basınca açan diyalog
  void _basariDialogGoster(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Harika!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Profesyonel CV'niz başarıyla oluşturuldu.", textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { 
                Navigator.pop(context); // Önce diyaloğu kapat
                
                // Güvenlik: Telefona bunun kesinlikle bir PDF olduğunu söylüyoruz
                OpenFilex.open(filePath, type: "application/pdf");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text("CV'yi Görüntüle", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Daha Sonra Bak", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
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
                      // 📸 FOTOĞRAF SEÇME KUTUSU BURAYA GELDİ
                      GestureDetector(
                        onTap: _fotoSec,
                        child: Center(
                          child: CircleAvatar(
                            radius: 50, // Stepper içinde çok büyük durmaması için 50 yaptık
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _secilenFoto != null ? FileImage(_secilenFoto!) : null,
                            child: _secilenFoto == null 
                                ? const Icon(Icons.add_a_photo, size: 35, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15), // Fotoğraf ile form arasına boşluk

                      TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),onChanged: (value) => _taslakKaydet(),),
                      TextField(controller: _meslekController, decoration: const InputDecoration(labelText: 'Hedef Meslek', prefixIcon: Icon(Icons.work)),onChanged: (value) => _taslakKaydet(),),
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email)),onChanged: (value) => _taslakKaydet(),),
                      TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),onChanged: (value) => _taslakKaydet(),),
                      TextField(controller: _linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL', prefixIcon: Icon(Icons.link)),onChanged: (value) => _taslakKaydet(),),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 1,
                  title: const Text('Eğitim ve Deneyim', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      TextField(controller: _egitimController, maxLines: 3, decoration: const InputDecoration(labelText: 'Eğitim Bilgileri', border: OutlineInputBorder()),onChanged: (value) => _taslakKaydet(),),
                      const SizedBox(height: 10),
                      TextField(controller: _deneyimController, maxLines: 3, decoration: const InputDecoration(labelText: 'İş ve Staj Deneyimleri', border: OutlineInputBorder()),onChanged: (value) => _taslakKaydet(),),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 2,
                  title: const Text('Yetenekler ve Projeler', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    children: [
                      TextField(controller: _yeteneklerController, maxLines: 2, decoration: const InputDecoration(labelText: 'Yetenekler', border: OutlineInputBorder()),onChanged: (value) => _taslakKaydet(),),
                      const SizedBox(height: 10),
                      TextField(controller: _projelerController, maxLines: 3, decoration: const InputDecoration(labelText: 'Projeler ve Başarılar', border: OutlineInputBorder()),onChanged: (value) => _taslakKaydet(),),
                      const SizedBox(height: 10),
                      TextField(controller: _dillerController, decoration: const InputDecoration(labelText: 'Yabancı Diller', border: OutlineInputBorder()),onChanged: (value) => _taslakKaydet(),),
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
                      // Eski Dropdown kodunu sildiğin yere sadece bunu yaz:
                      _buildSablonGalerisi(),
                    ],
                  ),
                ),
              ],
            ),
      
    );
  }
}