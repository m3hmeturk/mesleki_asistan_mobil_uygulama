import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// SAYFALARIMIZ
import 'login_page.dart';
import 'register_page.dart';
import 'chat_page.dart';
import 'profile_page.dart'; 
import 'splash_screen.dart';
import 'tests_page.dart';
import 'onboarding_page.dart';
import 'cv_maker_page.dart'; // YENİ: Harita yerine CV sayfamızı ekledik!

// Tüm uygulamanın dinleyeceği tema şalteri
final ValueNotifier<ThemeMode> temaSalteri = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ESKİ: RoadmapProvider silindiği için MultiProvider'ı kaldırdık, 
  // uygulamayı doğrudan temiz bir şekilde başlatıyoruz.
  runApp(const KariyerUygulamasi());
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
          theme: ThemeData(
             useMaterial3: true, 
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
             useMaterial3: true,
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
             scaffoldBackgroundColor: const Color(0xFF121212), 
          ),
          themeMode: guncelTema, 
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

  // ALT MENÜDEKİ SAYFALARIN SIRALAMASI
  static final List<Widget> _sayfalar = [
    const TestsPage(),     
    const ChatPage(), 
    const CVMakerPage(),   // YENİ: RoadmapPage gitti, CVMakerPage geldi!
    const ProfilePage(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Kariyer Asistanı', 
          style: TextStyle(fontWeight: FontWeight.bold) 
        ),
        centerTitle: true,
      ),
      body: _sayfalar.elementAt(_secilenIndex),
      
      // Şık Alt Menümüz (GNav)
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor, 
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
              // YENİ: 3. Butonun ikonu ve yazısı CV üretime göre değişti
              GButton(icon: Icons.picture_as_pdf, text: 'CV Üret'), 
              GButton(icon: Icons.person, text: 'Profilim'), 
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