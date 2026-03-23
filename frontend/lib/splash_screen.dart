import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _uygulamayiBaslat();
  }

  Future<void> _uygulamayiBaslat() async {
    // 2.5 saniye ekranda tutuyoruz
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Firebase'e soruyoruz: "İçeride biri var mı?"
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Oturum açıksa, direkt Ana Ekrana uçur
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Oturum kapalıysa, daha önce tanıtımı izlemiş mi diye bak:
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingTamamlandi = prefs.getBool('onboarding_tamamlandi') ?? false;

      if (onboardingTamamlandi) {
        Navigator.pushReplacementNamed(context, '/login'); 
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding'); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Eski, temiz ve sağlam roket ikonumuz
            const Icon(
              Icons.rocket_launch,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            
            const Text(
              "KARİYER ASİSTANI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3, 
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              "Geleceğine Yön Ver...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8), 
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 50),
            
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}