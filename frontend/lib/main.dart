import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Bunu ekledik
import 'firebase_options.dart'; // Bunu ekledik
import 'package:google_nav_bar/google_nav_bar.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'main_screen.dart';
import 'chat_page.dart';

void main() async {
  // Flutter motorunun Firebase ile senkronize çalışması için bu şart:
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlatıyoruz:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MyApp yerine kendi sınıfının adını yazdık:
  runApp(const KariyerUygulamasi()); 
}
class KariyerUygulamasi extends StatelessWidget {
  const KariyerUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Sağ üstteki çirkin "Debug" yazısını kaldırır
      title: 'Mesleki Asistan',
      theme: ThemeData(
  useMaterial3: true, // Modern Android tasarımını aktif eder
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  scaffoldBackgroundColor: Colors.white, // TÜM sayfaların arka planını beyaz yapar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0, // AppBar altındaki gölgeyi kaldırır (Daha modern durur)
  ),
),
      home: const RegisterPage(), // Uygulama açıldığında kayıt sayfası gelsin
      // 2. ROTALARI (ADRESLERİ) BURADA TANIMLIYORUZ
      initialRoute: '/register', // Uygulama kayıt sayfasıyla başlasın
      routes: {
  '/register': (context) => const RegisterPage(),
  '/login': (context) => const LoginPage(),
  '/main': (context) => const MainScreen(), // Artık ana durak burası
},
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  // Uygulama açıldığında 1. indeks (yani Asistan sekmesi) seçili gelsin
  int _secilenIndex = 1; 

  // Odalarımız (Şimdilik içleri boş, sadece isimleri var)
  // 1. Başına 'final' ekle (Çünkü bu liste uygulama boyunca başka bir listeyle değişmeyecek)
  static final List<Widget> _sayfalar = [
    // 2. İçerideki her bir elemanın başına 'const' ekle (Böylece Flutter bunları her saniye baştan çizmez, hızlanır)
    const Center(child: Text('📝 Testler ve Keşif Sayfası', style: TextStyle(fontSize: 20))),
    const ChatPage(), // Eğer ChatPage class'ında 'const' varsa başına ekle
    const Center(child: Text('🗺️ Yol Haritam Sayfası', style: TextStyle(fontSize: 20))),
    const Center(child: Text('👔 CV Oluşturucu', style: TextStyle(fontSize: 20))),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kariyer Asistanı', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      // Ekranda gösterilecek mevcut oda
      body: _sayfalar.elementAt(_secilenIndex),
      
      // Şık Alt Menümüz (GNav)
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            gap: 8,
            activeColor: Colors.white,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: Colors.deepPurple,
            color: Colors.grey.shade600,
            tabs: const [
              GButton(icon: Icons.assignment, text: 'Testler'),
              GButton(icon: Icons.smart_toy, text: 'Asistan'),
              GButton(icon: Icons.map, text: 'Haritam'),
              GButton(icon: Icons.description, text: 'CV\'m'),
            ],
            selectedIndex: _secilenIndex,
            onTabChange: (index) {
              // Tıklanan sekmeye geçiş yap
              setState(() {
                _secilenIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}