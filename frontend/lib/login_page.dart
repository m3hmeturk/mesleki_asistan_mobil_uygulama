import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart'; // Tıklanabilir yazı için gerekli


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  
  bool _beniHatirla = false;
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _kayitliBilgileriYukle();
  }

  void _kayitliBilgileriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('kayitli_email') ?? '';
      _sifreController.text = prefs.getString('kayitli_sifre') ?? '';
      _beniHatirla = prefs.getBool('beni_hatirla') ?? false;
    });
  }

  Future<void> _girisYap() async {
    setState(() => _yukleniyor = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _sifreController.text.trim(),
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_beniHatirla) {
        await prefs.setString('kayitli_email', _emailController.text.trim());
        await prefs.setString('kayitli_sifre', _sifreController.text.trim());
        await prefs.setBool('beni_hatirla', true);
      } else {
        await prefs.remove('kayitli_email');
        await prefs.remove('kayitli_sifre');
        await prefs.setBool('beni_hatirla', false);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
}
     catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş Başarısız. Bilgilerinizi kontrol edin."), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengini kayıt ol sayfasıyla aynı yapıyoruz
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 30),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "E-posta", 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _sifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre", 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                ),
              ),
              
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _beniHatirla,
                        activeColor: Colors.deepPurple,
                        onChanged: (deger) => setState(() => _beniHatirla = deger!),
                      ),
                      const Text("Beni Hatırla"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {}, // Şifre sıfırlama buraya gelecek
                    child: const Text("Şifremi Unuttum", style: TextStyle(color: Colors.deepPurple)),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _yukleniyor 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Giriş Yap", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Tıklanabilir Kayıt Ol Yazısı
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                  children: [
                    const TextSpan(text: "Hesabınız yok mu? "),
                    TextSpan(
                      text: "Hemen Kayıt Olun",
                      style: const TextStyle(
                        color: Colors.deepPurple, 
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Kayıt sayfasına geri döner
                          Navigator.pop(context); 
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}