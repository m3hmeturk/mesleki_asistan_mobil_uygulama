import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _adController = TextEditingController();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  
  // Firebase Auth motorunu çağırıyoruz
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kayıt olma fonksiyonu
  Future<void> _kayitOl() async {
    try {
      // 1. Firebase'e kayıt isteği atıyoruz
      UserCredential kullanici = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _sifreController.text.trim(),
      );

      // 2. Firebase başarılı oldu, şimdi verileri MongoDB'ye (Python'a) gönderelim!
      // DİKKAT: Senin bilgisayarının yerel IP adresi terminalindeki fotoğraftan gördüğüm kadarıyla 10.24.2.85
      final url = Uri.parse('http://10.161.28.101:5000/api/kayit'); 
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": kullanici.user!.uid,
          "ad": _adController.text.trim(),
          "email": _emailController.text.trim(),
        }),
      );

      // 3. Başarılı olursa ekranda yönlendirme penceresi (Dialog) göster
      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          // 1. Şık bir başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kayıt Başarılı! Giriş sayfasına yönlendiriliyorsunuz..."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // 2. 2 saniye bekleyip otomatik giriş sayfasına at
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kayıt oldu ama veritabanına yazılamadı!"), backgroundColor: Colors.orange),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Kayıt Ol"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              
              TextField(
                controller: _adController,
                decoration: InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.person)),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "E-posta", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email)),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _sifreController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Şifre (En az 6 hane)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),

             SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _kayitOl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Kayıt Ol", 
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              
              // --- YENİ EKLENEN GİRİŞ YAP YAZISI ---
              const SizedBox(height: 25), 
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(text: "Zaten bir hesabınız var mı? "),
                      TextSpan(
                        text: "Giriş Yap",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ------------------------------------
            ],
        ),
      ),
      ),
    );
  }
}