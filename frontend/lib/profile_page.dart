import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Çıkış Yapma Fonksiyonu
  Future<void> _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Çıkış yaptıktan sonra giriş sayfasına gönderir ve tüm geçmişi siler
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // E-postadan kullanıcı adını türetelim (Chat sayfasındaki gibi)
    String displayEmail = user?.email ?? "E-posta bulunamadı";
    String displayName = displayEmail.split('@')[0];
    displayName = displayName[0].toUpperCase() + displayName.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // Profil Resmi (Avatar)
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: const Icon(Icons.person, size: 70, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 20),
          Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(displayEmail, style: const TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 40),
          const Divider(indent: 30, endIndent: 30), // Araya ince bir çizgi
          
          _buildDarkModeToggle(), 
          const SizedBox(height: 10),
          // Uygulama Ayarlarına yeni sayfamızı bağladık!
          _buildProfileOption(context, Icons.settings, "Uygulama Ayarları", const SettingsPage()),
          
          // Bildirimler ve Güvenlik sayfalarını bağladık!
          _buildProfileOption(context, Icons.notifications, "Bildirimler", const NotificationsPage()),
          _buildProfileOption(context, Icons.security, "Gizlilik ve Güvenlik", const SecurityPage()),
          const Spacer(), // Butonu en aşağıya iter
          
          // ÇIKIŞ YAP BUTONU
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _cikisYap,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Çıkış Yap", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, Widget? destinationPage) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        if (destinationPage != null) {
          // Eğer gidecek bir sayfa verildiyse oraya yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        } else {
          // Sayfa henüz yapılmadıysa uyarı ver
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title sayfası yapım aşamasında!")),
          );
        }
      },
    );
  }
  }
  Widget _buildDarkModeToggle() {
    return ListTile(
      leading: const Icon(Icons.dark_mode, color: Colors.deepPurple),
      title: const Text("Karanlık Mod", style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: ValueListenableBuilder<ThemeMode>(
        valueListenable: temaSalteri,
        builder: (context, guncelTema, child) {
          // Eğer şalter karanlıktaysa veya sistem karanlıktaysa switch'i açık göster
          bool isDark = guncelTema == ThemeMode.dark || 
                       (guncelTema == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
                       
          return Switch(
            value: isDark,
            activeColor: Colors.deepPurple,
            onChanged: (bool value) {
              // Butona basıldığında şalteri çevir!
              temaSalteri.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          );
        }
      ),
    );
  }
