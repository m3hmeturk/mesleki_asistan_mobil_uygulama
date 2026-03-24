import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Şalterlerin açık/kapalı durumlarını tutan değişkenler
  bool _appGuncellemeleri = true;
  bool _mesajBildirimleri = true;
  bool _kampanyaBildirimleri = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSwitchTile(
            "Uygulama Güncellemeleri", 
            "Yeni sürüm ve özellikler çıktığında haber ver", 
            _appGuncellemeleri, 
            (val) => setState(() => _appGuncellemeleri = val)
          ),
          _buildSwitchTile(
            "Asistan Mesajları", 
            "Yapay zeka yanıt verdiğinde bildirim gönder", 
            _mesajBildirimleri, 
            (val) => setState(() => _mesajBildirimleri = val)
          ),
          _buildSwitchTile(
            "Kampanya ve Fırsatlar", 
            "Özel etkinlikler ve Teknofest duyuruları", 
            _kampanyaBildirimleri, 
            (val) => setState(() => _kampanyaBildirimleri = val)
          ),
        ],
      ),
    );
  }

  // Bildirimler için özel şalterli kart tasarımı (Gece moduna %100 uyumlu)
  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        activeColor: Colors.deepPurple,
        onChanged: onChanged,
      ),
    );
  }
}