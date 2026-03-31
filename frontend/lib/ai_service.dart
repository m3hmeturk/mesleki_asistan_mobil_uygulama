// lib/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // ── DİNAMİK SÖZLÜK İÇİN YAPAY ZEKA FONKSİYONU ──
  static Future<String> terimiAcikla(String term) async {
    // 1. Şifreyi kasadan alıyoruz
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      return "Hata: API Anahtarı bulunamadı. Lütfen .env dosyanı kontrol et.";
    }

    // 2. OpenAI'a gidecek kargo paketi (Headers)
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    // 3. Yapay Zekaya Verdiğimiz Kimlik ve Emir (Body)
    final body = jsonEncode({
      "model": "gpt-4o-mini", // Hızlı ve ucuz modelimiz
      "messages": [
        {
          "role": "system",
          // BURASI ÇOK ÖNEMLİ: Yapay zekaya nasıl davranması gerektiğini söylüyoruz.
          "content": "Sen bir kariyer ve meslek sözlüğüsün. Öğrencilere teknoloji, yazılım, sağlık, mühendislik gibi alanlardaki jargonları açıklıyorsun. Gelen terimi en fazla 2 kısa cümleyle, çok net ve bir lise/üniversite öğrencisinin anlayacağı basitlikte açıkla. Asla uzun cevap verme ve destan yazma."
        },
        {
          "role": "user",
          "content": "Lütfen şu terimi açıkla: $term"
        }
      ],
      "temperature": 0.7 // 0 robotik, 1 çok yaratıcı. 0.7 idealdir.
    });

    try {
      // 4. İsteği gönderiyoruz ve cevabı bekliyoruz
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      // 5. Cevap başarılıysa (200 OK)
      if (response.statusCode == 200) {
        // Türkçe karakterlerin (ş, ğ, ç) bozulmaması için utf8.decode kullanıyoruz
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        // Bakiye yetersizliği veya başka bir hata varsa
        print("OpenAI API Hatası: ${response.body}");
        return "Şu an sistemsel bir yoğunluk var, lütfen daha sonra tekrar dene.";
      }
    } catch (e) {
      // İnternet yoksa veya bağlantı koptuysa
      return "İnternet bağlantını kontrol edip tekrar dener misin?";
    }
  }
  // lib/ai_service.dart içine eklenecek yeni fonksiyon

  static Future<String> mulakatSohbet(List<Map<String, String>> mesajGecmisi, {String? pozisyon}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return "API Anahtarı eksik.";

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    // --- BURASI GÜNCELLENDİ: POZİSYON VE ANALİZ TALİMATI ---
    String sistemMesaji = "Sen profesyonel bir İK uzmanısın. Adın 'Kariyer Rehberi'. ";
    if (pozisyon != null) {
      sistemMesaji += "Şu an **$pozisyon** pozisyonu için bir mülakat yapıyorsun. Sorularını bu mesleğin teknik gereksinimlerine göre sor. ";
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