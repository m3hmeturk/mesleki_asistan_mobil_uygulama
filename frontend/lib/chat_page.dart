import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Yeni kurduğumuz paket
import 'package:firebase_auth/firebase_auth.dart'; // Bunu ekliyoruz

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false; // Yapay zeka düşünürken gözükecek

  // --- YENİ EKLENEN KISIM BAŞLANGICI ---
  String _kullaniciAdi = "Kullanıcı"; // Varsayılan isim

  @override
  void initState() {
    super.initState();
    _kullaniciBilgisiniAl();
  }

  void _kullaniciBilgisiniAl() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      // E-postanın '@' işaretinden önceki kısmını alıyor
      String emailIsim = user.email!.split('@')[0];
      // İlk harfini büyük yapıyor (Örn: mehmet -> Mehmet, cansu -> Cansu)
      setState(() {
        _kullaniciAdi = emailIsim[0].toUpperCase() + emailIsim.substring(1);
      });
    }
  }
  // Mesaj Gönderme Fonksiyonu
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String userMsg = _controller.text;
    
    setState(() {
      _messages.add({
        "role": "user",
        "text": userMsg,
        "time": DateFormat('HH:mm').format(DateTime.now())
      });
      _isTyping = true;
    });
    _controller.clear();

    try {
      // DİKKAT: Buradaki IP adresinin bilgisayarının IP'si ile aynı olduğundan emin ol!
      final response = await http.post(
        Uri.parse('http://10.77.85.101:5000/api/chat'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMsg}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            "role": "ai",
            "text": data['ai_response'],
            "time": DateFormat('HH:mm').format(DateTime.now())
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "Sunucuya bağlanılamadı. IP adresini kontrol et!", "time": ""});
      });
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planı bembeyaz yaparak tasarım bütünlüğünü sağlıyoruz
      
      body: Column(
        children: [
          // Mesajların Listelendiği Alan
          Expanded(
            child: _messages.isEmpty 
              ? _buildWelcomeScreen() // Eğer mesaj yoksa karşılama ekranı
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
          ),
          
          // Yazıyor... Göstergesi
          if (_isTyping) _buildTypingIndicator(),

          // Mesaj Yazma Alanı
          _buildInputArea(),
        ],
      ),
    );
  }

  // BOŞ EKRAN TASARIMI
  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch, 
            size: 80, 
            // Rengi temaya göre dinamik yaptık:
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.deepPurple.shade200.withAlpha(40) 
                : Colors.deepPurple.withAlpha(25),
          ),
          const SizedBox(height: 20),
          // const KELİMESİNİ SİLDİK VE DEĞİŞKENİ EKLEDİK:
          Text("Merhaba $_kullaniciAdi! 👋", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text("Bugün kariyer yolculuğun için ne yapabiliriz? Bana istediğini sorabilirsin.", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
  // MESAJ BALONU TASARIMI
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg["role"] == "user";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) // AI ise soluna robot ikonu koy
            const CircleAvatar(backgroundColor: Colors.deepPurple, radius: 14, child: Icon(Icons.smart_toy, size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(msg["text"], style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
                  const SizedBox(height: 5),
                  Text(msg["time"], style: TextStyle(color: isUser ? Colors.white60 : Colors.black38, fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) // Kullanıcı ise sağına insan ikonu koy
            const CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(Icons.person, size: 16, color: Colors.white)),
        ],
      ),
    );
  }

  // ALTTAKİ YAZMA ALANI
  Widget _buildInputArea() {
    return Container(
        padding: const EdgeInsets.all(8.0),
        // Arka planı temaya göre belirle:
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) // Koyu modda şık bir antrasit
            : Colors.white, // Gündüz modunda beyaz
        child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Asistana bir şey sor...",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            radius: 25,
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(left: 55, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Asistan düşünüyor...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }
}