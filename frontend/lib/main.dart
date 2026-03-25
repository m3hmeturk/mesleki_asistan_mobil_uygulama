import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'chat_page.dart';
import 'profile_page.dart'; // Profil sayfamızı buraya ekledik
import 'splash_screen.dart';
import 'tests_page.dart';
import 'roadmap_page.dart';
import 'onboarding_page.dart';
import 'package:provider/provider.dart';
import 'roadmap_provider.dart';

// Tüm uygulamanın dinleyeceği tema şalteri
final ValueNotifier<ThemeMode> temaSalteri = ValueNotifier(ThemeMode.system);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoadmapProvider()),
      ],
      child: const KariyerUygulamasi(), // Senin mevcut sınıfın
    ),
  );
}

class KariyerUygulamasi extends StatelessWidget {
  const KariyerUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    // Şalteri dinleyen mekanizma
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaSalteri,
      builder: (context, guncelTema, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, 
          title: 'Mesleki Asistan',
          // -- ESKİ TEMA KODLARIN BURADA DURMAYA DEVAM EDECEK --
          theme: ThemeData(
             useMaterial3: true, 
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
             useMaterial3: true,
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
             scaffoldBackgroundColor: const Color(0xFF121212), 
          ),
          
          themeMode: guncelTema, // ARTIK SİSTEM DEĞİL, BİZİM ŞALTERİ DİNLİYOR
          
          initialRoute: '/splash', 
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingPage(), 
            '/register': (context) => const RegisterPage(),
            '/login': (context) => const LoginPage(),
            '/main': (context) => const AnaEkran(),
          },
        );
      }
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _secilenIndex = 1; 

  static final List<Widget> _sayfalar = [
    const TestsPage(),     // ESKİ: const Center(...) yazısını sildik
    const ChatPage(), 
    const RoadmapPage(),   // ESKİ: const Center(...) yazısını sildik
    const ProfilePage(), 
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        elevation: 0,
        // backgroundColor: Colors.white, ---> BUNU SİL (Tema kendi ayarlasın)
        title: const Text(
          'Kariyer Asistanı', 
          // DİKKAT: Aşağıdaki 'color: Colors.black' yazısını sildik!
          style: TextStyle(fontWeight: FontWeight.bold) 
        ),
        centerTitle: true,
      ),
      body: _sayfalar.elementAt(_secilenIndex),
      
      // Şık Alt Menümüz (GNav) artık devrede!
      bottomNavigationBar: Container(
        // color: Colors.white, ---> BUNU SİL, YERİNE ŞUNU YAZ:
        color: Theme.of(context).scaffoldBackgroundColor, // Arka plana göre renk alır
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
              GButton(icon: Icons.person, text: 'Profilim'), // 4. Buton ikonu ve yazısı güncellendi
            ],
            selectedIndex: _secilenIndex,
            onTabChange: (index) {
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