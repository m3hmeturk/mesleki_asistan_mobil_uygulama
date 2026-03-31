// lib/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // temaSalteri buradan geliyor
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

  // Çıkış Yapma Fonksiyonu (Eski Kodundan)
  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Çıkış yaptıktan sonra giriş sayfasına gönderir ve tüm geçmişi siler
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // E-postadan kullanıcı adını türetelim (Eski Kodundan)
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
          // ── 1. Profil Kullanıcı Başlığı (Yeni Tasarım, Eski Veri) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    displayName[0], // İsmin ilk harfi
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(displayEmail, 
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // ── 2. Fırsat Radarı Başlığı (Yeni Tasarım) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'SANA ÖZEL FIRSATLAR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // ── 3. Fırsat Radarı (Yatay Kaydırmalı Kartlar) ──
          const _FirsatRadariListesi(),

          const SizedBox(height: 30),
          const Divider(indent: 30, endIndent: 30), // Araya ince bir çizgi
          const SizedBox(height: 10),

          // ── 4. Ayarlar ve Menüler (Eski Kodundan) ──
          _buildDarkModeToggle(theme), 
          _buildProfileOption(context, Icons.settings, "Uygulama Ayarları", const SettingsPage(), theme),
          _buildProfileOption(context, Icons.notifications, "Bildirimler", const NotificationsPage(), theme),
          _buildProfileOption(context, Icons.security, "Gizlilik ve Güvenlik", const SecurityPage(), theme),
          
          const SizedBox(height: 30),

          // ── 5. ÇIKIŞ YAP BUTONU (Eski Kodundan) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _cikisYap,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Çıkış Yap", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Güncellenmiş Profil Menü Şablonu (Tıklanabilir)
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget? destinationPage, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
      onTap: () {
        if (destinationPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title sayfası yapım aşamasında!")),
          );
        }
      },
    );
  }

  // Karanlık Mod Şalteri
  Widget _buildDarkModeToggle(ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.dark_mode, color: theme.colorScheme.primary),
      title: Text("Karanlık Mod", style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
      trailing: ValueListenableBuilder<ThemeMode>(
        valueListenable: temaSalteri,
        builder: (context, guncelTema, child) {
          bool isDark = guncelTema == ThemeMode.dark || 
                        (guncelTema == ThemeMode.system && theme.brightness == Brightness.dark);
                       
          return Switch(
            value: isDark,
            activeColor: theme.colorScheme.primary,
            onChanged: (bool value) {
              temaSalteri.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          );
        }
      ),
    );
  }
}

// ── Fırsat Radarı Liste Widget'ı ──────────────────────────────────────────
class _FirsatRadariListesi extends StatelessWidget {
  const _FirsatRadariListesi();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Şablon Veriler
    final List<Map<String, dynamic>> firsatlar = [
      {
        "title": "Teknofest Hava Savunma",
        "subtitle": "Kritik Tasarım Raporu Teslimi",
        "daysLeft": 3,
        "icon": Icons.airplanemode_active,
        "color": Colors.redAccent
      },
      {
        "title": "Milli Teknoloji Akademisi",
        "subtitle": "İleri Seviye Eğitim Kayıtları",
        "daysLeft": 8,
        "icon": Icons.school,
        "color": Colors.teal
      },
      {
        "title": "T3 Vakfı Staj Programı",
        "subtitle": "Yaz Dönemi Staj Başvuruları",
        "daysLeft": 12,
        "icon": Icons.work_outline,
        "color": Colors.blueAccent
      },
    ];

    return SizedBox(
      height: 140, 
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: firsatlar.length,
        itemBuilder: (context, index) {
          final item = firsatlar[index];
          final bool isUrgent = item["daysLeft"] <= 5; 

          return Container(
            width: 250, 
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item["color"].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item["color"].withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item["icon"], color: item["color"], size: 24),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.redAccent.withOpacity(0.2) : theme.colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Son ${item["daysLeft"]} Gün',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? Colors.redAccent : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item["title"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item["subtitle"],
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
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