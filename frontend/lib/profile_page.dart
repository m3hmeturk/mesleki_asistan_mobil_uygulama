// lib/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'api_config.dart'; 
import 'package:flutter/foundation.dart'; // YENİ: debugPrint için eklendi

// Diğer sayfalar
import 'settings_page.dart';
import 'notifications_page.dart';
import 'security_page.dart';
import 'edit_profile_page.dart'; 
import 'package:url_launcher/url_launcher.dart'; // YENİ: LinkedIn için eklendi

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Veritabanından gelecek değişkenler
  String _adSoyad = "";
  String _unvan = "Kariyer Unvanı Belirtilmemiş";
  String _base64Foto = "";
  String _konum = "";
  String _hakkimda = "";
  String _linkedin = "";
  String _kariyerDurumu = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profilBilgileriniGetir(); // Sayfa açıldığında verileri Python'dan çek
  }

  // 🌟 SENİN ORİJİNAL FONKSİYONUN (Sadece yeni veriler eklendi)
  Future<void> _profilBilgileriniGetir() async {
    try {
      if (user == null) return; 

      final url = Uri.parse('${ApiConfig.baseUrl}/api/get_profile');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uid': user!.uid}), 
      );

      if (response.statusCode == 200) {
        final parsedResponse = json.decode(utf8.decode(response.bodyBytes));
        
        if (parsedResponse['status'] == 'success') {
          final data = parsedResponse['data']; 

          setState(() {
            String displayEmail = user?.email ?? "";
            String defaultName = displayEmail.isNotEmpty ? displayEmail.split('@')[0].toUpperCase() : "Kullanıcı";
            
            _adSoyad = (data['ad_soyad'] != null && data['ad_soyad'] != "") ? data['ad_soyad'] : defaultName;
            _unvan = (data['unvan'] != null && data['unvan'] != "") ? data['unvan'] : "Kariyer Unvanı Belirtilmemiş";
            _base64Foto = data['profil_foto'] ?? "";
            
            // Yeni Eklenen Veriler
            _konum = data['konum'] ?? "";
            _hakkimda = data['hakkimda'] ?? "";
            _linkedin = data['linkedin'] ?? "";
            _kariyerDurumu = data['kariyer_durumu'] ?? "";
            
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Profil bilgileri çekilemedi: $e"); // YENİ: print yerine debugPrint
      setState(() => _isLoading = false);
    }
  }

  // LinkedIn URL'sini Tarayıcıda Açma Fonksiyonu
  Future<void> _linkeGit(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link açılamadı")));
      }
    }
  }

  // 🌟 SENİN ORİJİNAL ÇIKIŞ FONKSİYONUN
  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // 🌟 SENİN ORİJİNAL DNA SIFIRLAMA FONKSİYONUN (HİÇ DOKUNULMADI)
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
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                // ── 1. MERKEZİ PROFİL BAŞLIĞI (Ortalanmış) ──
                Center(
                  child: Column(
                    children: [
                      // Fotoğraf ve Kalem İkonu
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                            backgroundImage: _base64Foto.startsWith('http') 
                                ? NetworkImage(_base64Foto) 
                                : null,
                            child: !_base64Foto.startsWith('http') 
                                ? Text(
                                    gosterilecekAd.isNotEmpty ? gosterilecekAd[0] : "K",
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  )
                                : null,
                          ),
                          // Hata veren kod düzeltildi, sadece Positioned var
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                bool? guncellendi = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      currentName: gosterilecekAd,
                                      currentTitle: _unvan == "Kariyer Unvanı Belirtilmemiş" ? "" : _unvan,
                                    ),
                                  ),
                                );
                                if (guncellendi == true) {
                                  setState(() { _isLoading = true; });
                                  _profilBilgileriniGetir();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary, 
                                  shape: BoxShape.circle, 
                                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)
                                ),
                                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(gosterilecekAd, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(_unvan, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: 12),
                      
                      // Rozetler (Konum ve Durum)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_konum.isNotEmpty) _buildChip(Icons.location_on_outlined, _konum, theme),
                          if (_kariyerDurumu.isNotEmpty) _buildChip(Icons.school_outlined, _kariyerDurumu, theme),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 16),

                // ── 2. BİYOGRAFİ VE LINKEDIN BÖLÜMÜ ──
                if (_hakkimda.isNotEmpty) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hakkımda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(_hakkimda, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.5, fontSize: 14)),
                      ],
                    ),
                  ),
                
                if (_linkedin.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () => _linkeGit(_linkedin),
                      icon: const Icon(Icons.link, size: 20),
                      label: const Text("LinkedIn Profilimi Gör", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B5), // LinkedIn Mavisi
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                // ── 3. STANDART AYARLAR MENÜSÜ ──
                _buildMenuTitle("Yönetim", theme),
                _buildProfileOption(context, Icons.settings_outlined, "Uygulama Ayarları", const SettingsPage(), theme),
                _buildProfileOption(context, Icons.notifications_none, "Bildirimler", const NotificationsPage(), theme),
                _buildProfileOption(context, Icons.security_outlined, "Gizlilik ve Güvenlik", const SecurityPage(), theme),
                
                const SizedBox(height: 16),
                Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 16),

                // ── 4. KRİTİK İŞLEMLER (Senin orijinal fonksiyonlarına bağlı) ──
                _buildMenuTitle("Hesap İşlemleri", theme),
                _buildDestructiveOption(context, Icons.delete_outline, "Kariyer DNA'mı Sıfırla", () => _kariyerDnasiniSifirla(context), theme),
                _buildDestructiveOption(context, Icons.logout, "Hesaptan Çıkış Yap", _cikisYap, theme),

                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // ── YARDIMCI WIDGETLAR (Arayüz Temizliği İçin) ──

  // Küçük Rozetler (Konum ve Unvan için)
  Widget _buildChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  // Menü Başlıkları
  Widget _buildMenuTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
      ),
    );
  }

  // Standart Menü Şablonu
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget destinationPage, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destinationPage));
      },
    );
  }

  // Kritik/Tehlikeli İşlemler İçin Menü Şablonu (Kırmızı Renkli)
  Widget _buildDestructiveOption(BuildContext context, IconData icon, String title, VoidCallback onTap, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.redAccent, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.redAccent)),
      onTap: onTap,
    );
  }
}