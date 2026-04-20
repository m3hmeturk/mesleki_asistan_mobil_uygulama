// lib/chat_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart'; // Yapay zeka servisimizi bağladık
import 'api_config.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _kullaniciAdi = "Kullanıcı";
  
  // MÜLAKAT MODU DEĞİŞKENLERİ
  bool _isInterviewMode = false;
  String _secilenPozisyon = "Yazılım Geliştirici"; // Pozisyonu tutacak değişken
  @override
  void initState() {
    super.initState();
    _kullaniciBilgisiniAl();
  }

  void _kullaniciBilgisiniAl() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      String emailIsim = user.email!.split('@')[0];
      setState(() {
        _kullaniciAdi = emailIsim[0].toUpperCase() + emailIsim.substring(1);
      });
    }
  }

  // Mülakat başlamadan önce seçim yaptıran pencere
  void _pozisyonSecVeBaslat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mülakat Pozisyonu Seçin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                ActionChip(label: const Text("Yazılımcı"), onPressed: () => _baslat("Yazılımcı")),
                ActionChip(label: const Text("Tasarımcı"), onPressed: () => _baslat("Tasarımcı")),
                ActionChip(label: const Text("Pazarlamacı"), onPressed: () => _baslat("Pazarlamacı")),
                ActionChip(label: const Text("İK Uzmanı"), onPressed: () => _baslat("İK Uzmanı")),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Seçilen pozisyonla mülakatı gerçekten başlatan yer
  void _baslat(String pozisyon) {
    Navigator.pop(context); // Seçim penceresini kapat
    setState(() {
      _secilenPozisyon = pozisyon;
      _isInterviewMode = true;
      _messages.clear();
      _messages.add({
        "role": "ai",
        "text": "Harika! **$_secilenPozisyon** mülakatına hoş geldin. Hazırsan başlayalım: Bu alandaki deneyimlerinden bahseder misin?",
        "time": DateFormat('HH:mm').format(DateTime.now())
      });
    });
  }

  // Mesaj Gönderme (Hibrit: Normal Chat veya Mülakat)
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

    if (_isInterviewMode) {
      // --- SENARYO 1: MÜLAKAT MODU (OpenAI API Kullanır) ---
      try {
        List<Map<String, String>> history = _messages.map((m) => {
          "role": m["role"] == "user" ? "user" : "assistant",
          "content": m["text"] as String
        }).toList();

        // 1. Yapay Zekadan mülakat sorusunu veya bitiş karnesini al
        String response = await AiService.mulakatSohbet(history, pozisyon: _secilenPozisyon);

        setState(() {
          _messages.add({
            "role": "ai",
            "text": response,
            "time": DateFormat('HH:mm').format(DateTime.now())
          });
        });

        // 2. OYUNLAŞTIRMA: Eğer kullanıcı mülakatı bitirdiyse, bu karneyi backend'e gönder ve XP al!
        if (userMsg.toLowerCase().contains("mülakatı bitir")) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final dbResponse = await http.post(
                Uri.parse('${ApiConfig.baseUrl}/api/save_interview'), // DİKKAT: IP adresin güncel olmalı!
                headers: {"Content-Type": "application/json; charset=utf-8"},
                body: jsonEncode({
                  "uid": user.uid,
                  "position": _secilenPozisyon,
                  "report": response // Yapay zekanın az önce verdiği karne metni
                }),
              );
              
              if (dbResponse.statusCode == 201) {
                final data = jsonDecode(dbResponse.body);
                // Kullanıcıya şık bir bildirim (SnackBar) ile XP kazandığını müjdele
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("🏆 +${data['gained_xp']} XP Kazandın! Karnen profiline kaydedildi."),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            } catch (e) {
              print("Veritabanı kayıt hatası: $e");
            }
          }
        }

      } catch (e) {
        _showError("OpenAI bağlantı hatası!");
      } finally {
        setState(() => _isTyping = false);
      }
    } else {
      // --- SENARYO 2: NORMAL CHAT (Flask Backend ve Süper Hafıza) ---
      try {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? ""; 

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/chat'), 
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode({
            "message": userMsg,
            "uid": uid 
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes)); 
          setState(() {
            _messages.add({
              "role": "ai",
              "text": data['ai_response'],
              "time": DateFormat('HH:mm').format(DateTime.now())
            });
          });
        } else {
          _showError("Sunucu hatası: ${response.statusCode}");
        }
      } catch (e) {
        _showError("Sunucuya bağlanılamadı. IP adresini kontrol et!");
      } finally {
        setState(() => _isTyping = false);
      }
    }
  }

  void _showError(String errorText) {
    setState(() {
      _messages.add({"role": "ai", "text": errorText, "time": ""});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isInterviewMode ? "Mülakat Simülatörü" : "Kariyer Asistanı"),
        actions: [
          if (_isInterviewMode)
            TextButton(
              onPressed: () => setState(() => _isInterviewMode = false),
              child: const Text("Çık", style: TextStyle(color: Colors.redAccent)),
            )
        ],
      ),
      body: Column(
        children: [
          // Mülakat Modu Uyarı Bandı
          if (_isInterviewMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.2),
              child: const Text("⚠️ Mülakat Simülasyonu Aktif", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
            
          Expanded(
            child: _messages.isEmpty 
              ? _buildWelcomeScreen() 
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          if (_isInterviewMode && _messages.length > 2)
    TextButton.icon(
      onPressed: () {
        _controller.text = "Mülakatı bitir ve analiz ver.";
        _sendMessage();
      },
      icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
      label: const Text("Mülakatı Bitir ve Karne Al", style: TextStyle(color: Colors.redAccent)),
    ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isInterviewMode ? Icons.psychology : Icons.rocket_launch, 
            size: 80, 
            color: Colors.deepPurple.withAlpha(40),
          ),
          const SizedBox(height: 20),
          Text("Merhaba $_kullaniciAdi! 👋", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text("Bugün kariyer yolculuğun için ne yapabiliriz?", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),
          // MÜLAKAT BAŞLATMA BUTONU
          ElevatedButton.icon(
            onPressed: _pozisyonSecVeBaslat,
            icon: const Icon(Icons.assignment_ind, color: Colors.white),
            label: const Text("Mülakat Simülasyonunu Başlat", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg["role"] == "user";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) const CircleAvatar(backgroundColor: Colors.deepPurple, radius: 14, child: Icon(Icons.smart_toy, size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
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
                  Text(msg["text"], style: TextStyle(color: isUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), fontSize: 15)),
                  const SizedBox(height: 5),
                  Text(msg["time"], style: TextStyle(color: isUser ? Colors.white60 : Colors.black38, fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) const CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(Icons.person, size: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
        padding: const EdgeInsets.all(8.0),
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: _isInterviewMode ? "Mülakat cevabını yaz..." : "Asistana bir şey sor...",
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
        child: Text("Düşünüyor...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }
}