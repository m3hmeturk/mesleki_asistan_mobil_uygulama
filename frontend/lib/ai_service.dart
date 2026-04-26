// lib/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart'; // 🌟 YENİ: DigitalOcean sunucumuza bağlanmak için

class AiService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // ── 🌟 YENİ: KARİYER DNA'SINI ÇEKEN MERKEZİ FONKSİYON ──
  static Future<String> getKariyerDNAContext() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/user/career_dna_summary');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        // Türkçe karakterlerin bozulmaması için utf8.decode kullanıyoruz
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['prompt_eklentisi'] ?? "";
      }
    } catch (e) {
      print("DNA Çekilemedi: $e");
    }
    return ""; // Test çözülmemişse veya hata varsa sistemi bozmamak için boş döner
  }

  // ── DİNAMİK SÖZLÜK İÇİN YAPAY ZEKA FONKSİYONU (Aynen Korundu) ──
  static Future<String> terimiAcikla(String term) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return "Hata: API Anahtarı bulunamadı. Lütfen .env dosyanı kontrol et.";
    }

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "Sen bir kariyer ve meslek sözlüğüsün. Öğrencilere teknoloji, yazılım, sağlık, mühendislik gibi alanlardaki jargonları açıklıyorsun. Gelen terimi en fazla 2 kısa cümleyle, çok net ve bir lise/üniversite öğrencisinin anlayacağı basitlikte açıkla. Asla uzun cevap verme ve destan yazma."
        },
        {
          "role": "user",
          "content": "Lütfen şu terimi açıkla: $term"
        }
      ],
      "temperature": 0.7 
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        print("OpenAI API Hatası: ${response.body}");
        return "Şu an sistemsel bir yoğunluk var, lütfen daha sonra tekrar dene.";
      }
    } catch (e) {
      return "İnternet bağlantını kontrol edip tekrar dener misin?";
    }
  }

  // ── MÜLAKAT ASİSTANI (DNA İLE GÜÇLENDİRİLDİ) ──
  static Future<String> mulakatSohbet(List<Map<String, String>> mesajGecmisi, {String? pozisyon}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return "API Anahtarı eksik.";

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    // 1. YAPAY ZEKANIN GÖZÜNÜ AÇIYORUZ: KARİYER DNA'SINI ÇEK!
    String dnaContext = await getKariyerDNAContext();

    // 2. SİSTEM MESAJINI (PROMPT) DİNAMİK OLARAK KUR
    String sistemMesaji = "Sen profesyonel bir İK uzmanısın. Adın 'Kariyer Rehberi'. ";
    
    if (pozisyon != null) {
      sistemMesaji += "Şu an **$pozisyon** pozisyonu için bir mülakat yapıyorsun. Sorularını bu mesleğin teknik gereksinimlerine göre sor. ";
    }
    
    // 🌟 EĞER KULLANICI TEST ÇÖZDÜYSE DNA'YI BURAYA YAPIŞTIRIYORUZ
    if (dnaContext.isNotEmpty) {
      sistemMesaji += "\n$dnaContext\nLütfen sorularını bu adayın karakter özelliklerini, potansiyelini ve zayıf/güçlü yönlerini test edecek şekilde akıllıca ve stratejik sor.\n";
    }

    sistemMesaji += "Her seferinde sadece 1 soru sor. Kısa bir değerlendirme yap ve sonraki soruya geç. "
        "Eğer kullanıcı 'bitir' veya 'analiz ver' derse, mülakatı sonlandır ve şu formatta bir karne ver: "
        "\n1. Teknik Bilgi: X/10 \n2. İletişim: X/10 \n3. Güçlü Yönler \n4. Gelişim Alanları.";

    List<Map<String, String>> gonderilecekMesajlar = [
      {"role": "system", "content": sistemMesaji},
      ...mesajGecmisi,
    ];

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": gonderilecekMesajlar,
      "temperature": 0.8,
    });

    try {
      final response = await http.post(Uri.parse(_baseUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "Hata: Bakiye veya bağlantı sorunu (Kod: ${response.statusCode})";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }
}