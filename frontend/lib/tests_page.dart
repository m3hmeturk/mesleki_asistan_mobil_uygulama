import 'package:flutter/material.dart';
import 'test_engine_page.dart';

class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kariyer Testleri", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Yapay zekanın seni tanıması ve kusursuz mesleği önermesi için aşağıdaki testleri tamamla.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),

          // 1. Kişilik Envanteri
          _buildTestCard(context, "Kişilik Envanteri", "Karakterin hangi mesleklere uygun?", Icons.psychology, Colors.orange, () {
            List<Map<String, dynamic>> kisilikSorulari = [
              {
                'questionText': 'Boş zamanlarında hangisini yapmayı tercih edersin?',
                'answers': [
                  {'text': 'Arkadaşlarımla kalabalık bir ortama girmeyi', 'trait': 'Sosyal'},
                  {'text': 'Sessiz bir odada kitap okumayı veya kod yazmayı', 'trait': 'Analitik'},
                  {'text': 'Doğada yürüyüş yapmayı', 'trait': 'Fiziksel'},
                ]
              },
              {
                'questionText': 'Bir problemle karşılaştığında ilk tepkin ne olur?',
                'answers': [
                  {'text': 'Hemen detaylıca araştırır, mantıklı bir plan çizerim', 'trait': 'Analitik'},
                  {'text': 'Başkalarına danışır, ortak bir fikir ararım', 'trait': 'Sosyal'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "Kişilik Envanteri", questions: kisilikSorulari)));
          }),
          
          // 2. Meslek Seçimi Testi
          _buildTestCard(context, "Meslek Seçimi", "Hangi alanlar sana hitap ediyor?", Icons.work, Colors.blue, () {
            List<Map<String, dynamic>> meslekSorulari = [
              {
                'questionText': 'Hangi konularda bir şeyler izlemek/okumak daha çok ilgini çeker?',
                'answers': [
                  {'text': 'Yeni teknolojiler, yapay zeka ve yazılım', 'trait': 'Teknoloji'},
                  {'text': 'İnsan anatomisi, sağlık ve psikoloji', 'trait': 'Sağlık'},
                  {'text': 'Tasarım, çizim ve sanatsal içerikler', 'trait': 'Sanat'},
                ]
              },
              {
                'questionText': 'Lisedeyken en sevdiğin ders hangisiydi?',
                'answers': [
                  {'text': 'Matematik / Fizik', 'trait': 'Mühendislik'},
                  {'text': 'Edebiyat / Tarih', 'trait': 'Sosyal Bilimler'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "Meslek Seçimi", questions: meslekSorulari)));
          }),
          
          // 3. İngilizce Seviyesi
          _buildTestCard(context, "İngilizce Seviyesi", "A1'den C1'e gramer ve kelime ölçümü", Icons.translate, Colors.green, () {
            List<Map<String, dynamic>> ingilizceSorulari = [
              {
                'questionText': 'Boşluğu doldur: "I ___ to the cinema yesterday."',
                'answers': [
                  {'text': 'go', 'trait': 'A1'},
                  {'text': 'went', 'trait': 'A2'},
                  {'text': 'gone', 'trait': 'Hatalı'},
                ]
              },
              {
                'questionText': '"Accomplish" kelimesinin eş anlamlısı nedir?',
                'answers': [
                  {'text': 'Achieve', 'trait': 'B2'},
                  {'text': 'Fail', 'trait': 'A1'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "İngilizce Seviyesi", questions: ingilizceSorulari)));
          }),
          
          // 4. Liderlik Potansiyeli
          _buildTestCard(context, "Liderlik Potansiyeli", "Yönetici ruhuna sahip misin?", Icons.groups, Colors.red, () {
            List<Map<String, dynamic>> liderlikSorulari = [
              {
                'questionText': 'Ekip arkadaşın projede büyük bir hata yaparsa ne yaparsın?',
                'answers': [
                  {'text': 'Kızarım ve hatayı tek başına düzeltmesini söylerim', 'trait': 'Düşük Liderlik'},
                  {'text': 'Hatayı birlikte inceler, nasıl çözeceğimizi planlarız', 'trait': 'Yüksek Liderlik'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "Liderlik Potansiyeli", questions: liderlikSorulari)));
          }),

          // 5. Çalışma Ortamı
          _buildTestCard(context, "Çalışma Ortamı ve Stili", "Masa başı mı, saha mı, uzaktan mı?", Icons.laptop_mac, Colors.teal, () {
            List<Map<String, dynamic>> ortamSorulari = [
              {
                'questionText': 'Hayalindeki çalışma ortamı neresi?',
                'answers': [
                  {'text': 'Evimin rahatlığında, bilgisayar başında', 'trait': 'Uzaktan (Remote)'},
                  {'text': 'Modern bir ofiste, takımımla yüz yüze', 'trait': 'Ofis'},
                  {'text': 'Sürekli seyahat ederek veya sahada', 'trait': 'Saha'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "Çalışma Ortamı", questions: ortamSorulari)));
          }),

          // 6. Değerler ve Motivasyon
          _buildTestCard(context, "Değerler ve Motivasyon", "Seni ne motive eder? Para, statü, fayda?", Icons.star, Colors.amber, () {
            List<Map<String, dynamic>> motivasyonSorulari = [
              {
                'questionText': 'Bir işi kabul etmendeki EN ÖNEMLİ faktör nedir?',
                'answers': [
                  {'text': 'Çok yüksek bir maaş ve primler', 'trait': 'Maddi Odaklı'},
                  {'text': 'Topluma ve insanlığa faydalı bir iş yapmak', 'trait': 'Fayda Odaklı'},
                  {'text': 'Prestijli bir unvan ve saygınlık', 'trait': 'Statü Odaklı'},
                ]
              }
            ];
            Navigator.push(context, MaterialPageRoute(builder: (context) => TestEnginePage(testTitle: "Motivasyon", questions: motivasyonSorulari)));
          }),
        ],
      ),
    );
  }

  // Gece Moduna Duyarlı Test Kartı Şablonu (GÜNCELLENDİ)
  Widget _buildTestCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30), 
            shape: BoxShape.circle
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap, // İŞTE SİHİR BURADA: Artık kendi özel fonksiyonumuzu çalıştıracak!
      ),
    );
  }
}