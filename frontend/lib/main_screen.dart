import 'package:flutter/material.dart';
import 'chat_page.dart'; // Yapay Zeka sayfamız

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _seciliSayfa = 0; // Şu an hangi butondayız?

  // Alttaki butonlara basınca açılacak 4 ana sayfa
  final List<Widget> _sayfalar = [
    const Center(child: Text("🏠 Ana Sayfa / Haberler", style: TextStyle(fontSize: 20))),
    const ChatPage(), // 2. Buton: Bizim zeki asistan
    const Center(child: Text("📚 Kaynaklar / Dersler", style: TextStyle(fontSize: 20))),
    const Center(child: Text("👤 Profilim", style: TextStyle(fontSize: 20))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_seciliSayfa], // Seçilen sayfayı ekrana getir
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliSayfa,
        onTap: (index) {
          setState(() {
            _seciliSayfa = index; // Butona basınca sayfayı değiştir
          });
        },
        type: BottomNavigationBarType.fixed, // 4 buton için en ideali
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Asistan"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Eğitim"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}