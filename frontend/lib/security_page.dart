// lib/security_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'change_password_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final User? user = FirebaseAuth.instance.currentUser;



 // ── HESABI TAMAMEN SİLME (GÜNCELLENDİ) ──
  Future<void> _hesabiTamamenSil() async {
    bool? onay = await _silmeOnayiAl();
    if (onay != true || user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
    );

    try {
      final String uid = user!.uid;

      // 1. ADIM: MongoDB Verilerini Sil (Python'a istek atıyoruz)
      final url = Uri.parse('${ApiConfig.baseUrl}/api/user/delete_account');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uid': uid}),
      );

      if (response.statusCode != 200) {
        throw Exception("Veritabanı silme işlemi başarısız oldu.");
      }

      // 2. ADIM: Firebase Storage'daki Fotoğrafı Sil
      try {
        await FirebaseStorage.instance.ref().child('profil_fotograflari/$uid.jpg').delete();
      } catch (e) {
        // Eğer kullanıcının fotoğrafı yoksa hata verebilir, sorun değil devam et.
        debugPrint("Storage silme atlandı (Dosya yok olabilir): $e");
      }

      // 3. ADIM: Firebase Auth Kaydını Sil (Kritik Nokta!)
      await user!.delete();

      // İŞLEM BAŞARILI
      if (!mounted) return;
      Navigator.pop(context); // Yükleniyor'u kapat
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hesabınız ve tüm verileriniz kalıcı olarak silinmiştir.")),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      // EĞER KULLANICI UZUN SÜREDİR GİRİŞ YAPMADIYSA BU HATA DÖNER
      if (e.code == 'requires-recent-login') {
        _bilgiMesajiGoster(
          "Güvenlik nedeniyle bu işlemi yapabilmek için yeniden giriş yapmanız gerekiyor. Lütfen çıkış yapıp tekrar girin.", 
          Colors.orange
        );
      } else {
        _bilgiMesajiGoster("Firebase Hatası: ${e.message}", Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _bilgiMesajiGoster("Beklenmedik bir hata oluştu: $e", Colors.redAccent);
    }
  }

  // ── 3. YASAL LİNKLERİ AÇMA ──
  Future<void> _linkeGit(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      _bilgiMesajiGoster("Sayfa açılamadı.", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Gizlilik ve Güvenlik", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── GÜVENLİK BÖLÜMÜ ──
          _bolumBasligi("Giriş Güvenliği", theme),
          _ayarKarti(
            ListTile(
              leading: Icon(Icons.lock_reset, color: theme.colorScheme.primary),
              title: const Text("Şifremi Değiştir"),
              subtitle: const Text("Hesap giriş şifreni güvenle yenile"), // Alt yazıyı da güncelledik
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // YENİ: Direkt sayfaya yönlendiriyoruz
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
              },
            ),
            theme,
          ),

          const SizedBox(height: 24),

          // ── GİZLİLİK VE YASAL BÖLÜMÜ ──
          _bolumBasligi("Yasal ve Gizlilik", theme),
          _ayarKarti(
            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                  title: const Text("Gizlilik Politikası"),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _linkeGit("https://kariyerbot.com/gizlilik"), // Örnek link
                ),
                _ayirici(theme),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  title: const Text("Kullanım Koşulları"),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _linkeGit("https://kariyerbot.com/kosullar"), // Örnek link
                ),
              ],
            ),
            theme,
          ),

          const SizedBox(height: 24),

          // ── VERİ YÖNETİMİ ──
          _bolumBasligi("Veri Yönetimi", theme),
          _ayarKarti(
            ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              title: const Text("Verilerim Nasıl İşleniyor?"),
              subtitle: const Text("KVKK ve Veri güvenliği hakkında bilgi al"),
              onTap: () => _bilgiMesajiGoster("Verileriniz Kariyer Asistanı AI analizi dışında 3. taraflarla asla paylaşılmaz.", Colors.blueGrey),
            ),
            theme,
          ),

          const SizedBox(height: 40),

          // ── TEHLİKELİ BÖLGE (DANGER ZONE) ──
          _bolumBasligi("Tehlikeli Bölge", theme),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: const Text("Hesabımı Kalıcı Olarak Sil", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              subtitle: const Text("Tüm test sonuçların ve profilin yok edilir", style: TextStyle(fontSize: 12)),
              onTap: _hesabiTamamenSil,
            ),
          ),
          
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Bu işlem geri alınamaz. Silinen verilere bir daha ulaşılamaz.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ── YARDIMCI METODLAR ──

  Widget _bolumBasligi(String baslik, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(baslik, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
    );
  }

  Widget _ayarKarti(Widget icerik, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: icerik,
    );
  }

  Widget _ayirici(ThemeData theme) {
    return Divider(height: 1, indent: 55, color: theme.colorScheme.onSurface.withOpacity(0.05));
  }

  void _bilgiMesajiGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk, behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool?> _silmeOnayiAl() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misin?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Hesabını silmek üzeresin. Bu işlem sonucunda tüm Kariyer DNA'n, çözdüğün testler ve profil fotoğrafın kalıcı olarak silinecektir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Kalıcı Olarak Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}