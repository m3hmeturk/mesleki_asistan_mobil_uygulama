// lib/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // 🌟 YENİ: DNA Sıfırlama için API çağrısı
import 'dart:convert'; // 🌟 YENİ: API yanıtlarını işlemek için
import 'api_config.dart'; // 🌟 YENİ: Kendi API adresin

import 'main.dart'; 
import 'settings_page.dart';
import 'notifications_page.dart';
import 'security_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Çıkış Yapma Fonksiyonu (Yapısı Korundu)
  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // 🌟 YENİ: KARİYER DNA'SINI SIFIRLAMA FONKSİYONU
  Future<void> _kariyerDnasiniSifirla(BuildContext context) async {
    bool onay = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Emin misin?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bugüne kadar çözdüğün tüm test sonuçları ve Kariyer DNA'n kalıcı olarak silinecek. Yapay zeka asistanın seni unutacak ve her şeye sıfırdan başlayacaksın. Bu işlem geri alınamaz!",
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
            child: const Text("Evet, Her Şeyi Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Navigator.pop(context); // Yükleniyor'u kapat

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Kariyer DNA'n başarıyla sıfırlandı! Yeni bir başlangıca hazırsın."),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sıfırlama başarısız oldu.")));
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

    // E-postadan kullanıcı adını türetme (Yapısı Korundu)
    String displayEmail = user?.email ?? "E-posta bulunamadı";
    String displayName = displayEmail.split('@')[0];
    displayName = displayName.isNotEmpty 
        ? displayName[0].toUpperCase() + displayName.substring(1) 
        : "Kullanıcı";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profilim',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // ── 1. Profil Kullanıcı Başlığı ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                    ]
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      displayName[0],
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(displayEmail, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // ── 2. Fırsat Radarı Başlığı ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SANA ÖZEL FIRSATLAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // ── 3. Fırsat Radarı (Premium Tasarım) ──
          const _FirsatRadariListesi(),

          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.1), thickness: 1),
          ),
          const SizedBox(height: 10),

          // ── 4. Ayarlar ve Menüler ──
          _buildDarkModeToggle(theme), 
          _buildProfileOption(context, Icons.settings_outlined, "Uygulama Ayarları", const SettingsPage(), theme),
          _buildProfileOption(context, Icons.notifications_none, "Bildirimler", const NotificationsPage(), theme),
          _buildProfileOption(context, Icons.security_outlined, "Gizlilik ve Güvenlik", const SecurityPage(), theme),
          
          const SizedBox(height: 20),

          // ── 5. TEHLİKELİ BÖLGE (YENİ) ──
          _buildTehlikeliBolge(context, theme),

          const SizedBox(height: 30),

          // ── 6. MİNİMALİST ÇIKIŞ YAP BUTONU (YENİ TASARIM) ──
          Center(
            child: TextButton.icon(
              onPressed: _cikisYap,
              icon: Icon(Icons.logout, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
              label: Text("Hesaptan Çıkış Yap", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Profil Menü Şablonu
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget? destinationPage, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title sayfası yapım aşamasında!")));
        }
      },
    );
  }

  // Karanlık Mod Şalteri
  Widget _buildDarkModeToggle(ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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

  // 🌟 TEHLİKELİ BÖLGE WIDGET'I
  Widget _buildTehlikeliBolge(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text("Tehlikeli Bölge", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Tüm Kariyer DNA'nı ve analiz geçmişini kalıcı olarak siler. Bu işlem geri alınamaz.", 
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _kariyerDnasiniSifirla(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Kariyer DNA'mı Sıfırla", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }
}

// ── Fırsat Radarı Liste Widget'ı (Premium Tasarım) ─────────────────────────
class _FirsatRadariListesi extends StatelessWidget {
  const _FirsatRadariListesi();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> firsatlar = [
      {
        "title": "Teknofest Hava Savunma",
        "subtitle": "Kritik Tasarım Raporu Teslimi",
        "daysLeft": 3,
        "icon": Icons.airplanemode_active,
        "color1": const Color(0xFFFF416C),
        "color2": const Color(0xFFFF4B2B),
      },
      {
        "title": "Milli Teknoloji Akademisi",
        "subtitle": "İleri Seviye Eğitim Kayıtları",
        "daysLeft": 8,
        "icon": Icons.school,
        "color1": const Color(0xFF11998E),
        "color2": const Color(0xFF38EF7D),
      },
      {
        "title": "T3 Vakfı Staj Programı",
        "subtitle": "Yaz Dönemi Staj Başvuruları",
        "daysLeft": 12,
        "icon": Icons.work_outline,
        "color1": const Color(0xFF4A00E0),
        "color2": const Color(0xFF8E2DE2),
      },
    ];

    return SizedBox(
      height: 150, 
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: firsatlar.length,
        itemBuilder: (context, index) {
          final item = firsatlar[index];
          final bool isUrgent = item["daysLeft"] <= 5; 

          return Container(
            width: 260, 
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item["color1"].withOpacity(0.15),
                  item["color2"].withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: item["color1"].withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: item["color1"].withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item["icon"], color: item["color1"], size: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.redAccent.withOpacity(0.15) : theme.colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isUrgent ? Colors.redAccent.withOpacity(0.3) : Colors.transparent)
                      ),
                      child: Text(
                        'Son ${item["daysLeft"]} Gün',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? Colors.redAccent : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item["title"],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item["subtitle"],
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}