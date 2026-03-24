import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengi belirtmiyoruz, Karanlık/Aydınlık moda göre kendi karar veriyor
      appBar: AppBar(
        title: const Text('Uygulama Ayarları', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsItem(context, Icons.person, "Hesap Bilgileri", "Ad, soyad ve e-posta güncelle"),
          _buildSettingsItem(context, Icons.lock_reset, "Şifre Değiştir", "Hesap şifreni yenile"),
          _buildSettingsItem(context, Icons.language, "Dil Seçenekleri", "Türkçe"),
          const Divider(height: 30), // Araya ince bir çizgi çektik
          _buildSettingsItem(context, Icons.delete_forever, "Hesabımı Sil", "Tüm verilerini kalıcı olarak sil", isDestructive: true),
        ],
      ),
    );
  }

  // Ayar Seçenekleri İçin Kart Şablonu
  Widget _buildSettingsItem(BuildContext context, IconData icon, String title, String subtitle, {bool isDestructive = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Renge dokunmuyoruz, Card widget'ı gece/gündüz moduna otomatik uyum sağlar
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.deepPurple),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : null)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // İleride bu butonların içi de doldurulabilir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title yakında eklenecek!")),
          );
        },
      ),
    );
  }
}