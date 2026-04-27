// lib/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'api_config.dart'; 

import 'main.dart'; 
import 'settings_page.dart';
import 'notifications_page.dart';
import 'security_page.dart';
import 'edit_profile_page.dart'; // 🌟 YENİ: Düzenleme sayfasını import ettik

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // 🌟 YENİ: Veritabanından gelecek değişkenler
  String _adSoyad = "";
  String _unvan = "Kariyer Unvanı Belirtilmemiş";
  String _base64Foto = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profilBilgileriniGetir(); // Sayfa açıldığında verileri Python'dan çek
  }

  // 🌟 YENİ: Python'dan profil bilgilerini çeken fonksiyon
  Future<void> _profilBilgileriniGetir() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/user/profile');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          String displayEmail = user?.email ?? "";
          String defaultName = displayEmail.isNotEmpty ? displayEmail.split('@')[0].toUpperCase() : "Kullanıcı";
          
          _adSoyad = (data['ad_soyad'] != null && data['ad_soyad'] != "") ? data['ad_soyad'] : defaultName;
          _unvan = (data['unvan'] != null && data['unvan'] != "") ? data['unvan'] : "Kariyer Unvanı Belirtilmemiş";
          _base64Foto = data['profil_foto'] ?? "";
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Profil bilgileri çekilemedi: $e");
      setState(() => _isLoading = false);
    }
  }

  // Hesaptan Çıkış Yapma
  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Kariyer DNA'sını Sıfırlama Fonksiyonu (Senin kodun, yapısı aynen korundu)
  Future<void> _kariyerDnasiniSifirla(BuildContext context) async {
    bool onay = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5))
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Emin misin?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bugüne kadar çözdüğün tüm test sonuçları ve Kariyer DNA'n kalıcı olarak silinecek. Bu işlem geri alınamaz!",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Evet, Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (onay) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );

      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/api/user/reset_dna');
        final response = await http.post(url);

        if (!mounted) return;
        Navigator.pop(context); 

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Kariyer DNA'n sıfırlandı. Yeni bir başlangıca hazırsın!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // İsim veya e-posta yedeklemesi
    String displayEmail = user?.email ?? "E-posta bulunamadı";
    String fallbackName = displayEmail.split('@')[0];
    fallbackName = fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() + fallbackName.substring(1) : "Kullanıcı";
    
    String gosterilecekAd = _adSoyad.isNotEmpty ? _adSoyad : fallbackName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profilim',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // ── 1. Profil Başlığı (Tıklanabilir ve Düzenlenebilir) ──
              GestureDetector(
                onTap: () async {
                  // Profil Düzenleme sayfasına gidiyoruz
                  bool? guncellendi = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        currentName: gosterilecekAd,
                        currentTitle: _unvan == "Kariyer Unvanı Belirtilmemiş" ? "" : _unvan,
                      ),
                    ),
                  );
                  
                  // Eğer düzenleme yapılıp geri dönüldüyse, verileri tekrar çek
                  if (guncellendi == true) {
                    setState(() { _isLoading = true; });
                    _profilBilgileriniGetir();
                  }
                },
                child: Container(
                  color: Colors.transparent, // Tüm satırın tıklanabilir olması için
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // 🌟 FOTOĞRAF KISMI (Eğer Base64 varsa göster, yoksa baş harf göster)
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        backgroundImage: _base64Foto.isNotEmpty ? MemoryImage(base64Decode(_base64Foto)) : null,
                        child: _base64Foto.isEmpty 
                            ? Text(
                                gosterilecekAd.isNotEmpty ? gosterilecekAd[0] : "K",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gosterilecekAd, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(_unvan, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      // Kalem İkonu (Düzenlenebilir Hissiyatı)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
              ),
              const SizedBox(height: 10),

              // ── 2. Standart Ayarlar Menüsü ──
              _buildDarkModeToggle(theme), 
              _buildProfileOption(context, Icons.settings_outlined, "Uygulama Ayarları", const SettingsPage(), theme),
              _buildProfileOption(context, Icons.notifications_none, "Bildirimler", const NotificationsPage(), theme),
              _buildProfileOption(context, Icons.security_outlined, "Gizlilik ve Güvenlik", const SecurityPage(), theme),
              
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
              ),
              const SizedBox(height: 10),

              // ── 3. Kritik İşlemler (Dengeli ve Uyumlu Tasarım) ──
              _buildDestructiveOption(context, Icons.delete_outline, "Kariyer DNA'mı Sıfırla", () => _kariyerDnasiniSifirla(context), theme),
              _buildDestructiveOption(context, Icons.logout, "Hesaptan Çıkış Yap", _cikisYap, theme),

              const SizedBox(height: 40),
            ],
          ),
    );
  }

  // Standart Menü Şablonu
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget? destinationPage, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: () {
        if (destinationPage != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destinationPage));
        }
      },
    );
  }

  // Kritik/Tehlikeli İşlemler İçin Menü Şablonu (Kırmızı Renkli)
  Widget _buildDestructiveOption(BuildContext context, IconData icon, String title, VoidCallback onTap, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.redAccent, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.redAccent)),
      onTap: onTap,
    );
  }

  // Karanlık Mod Şalteri
  Widget _buildDarkModeToggle(ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.dark_mode_outlined, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text("Karanlık Mod", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: theme.colorScheme.onSurface)),
      trailing: ValueListenableBuilder<ThemeMode>(
        valueListenable: temaSalteri,
        builder: (context, guncelTema, child) {
          bool isDark = guncelTema == ThemeMode.dark || (guncelTema == ThemeMode.system && theme.brightness == Brightness.dark);
          return Switch(
            value: isDark,
            activeColor: theme.colorScheme.primary,
            activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
            onChanged: (bool value) {
              temaSalteri.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          );
        }
      ),
    );
  }
}