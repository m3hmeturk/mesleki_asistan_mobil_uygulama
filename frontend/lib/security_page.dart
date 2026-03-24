import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik ve Güvenlik', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Güvenlik Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("Güvenlik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          _buildListTile(context, Icons.security, "İki Adımlı Doğrulama", "Hesabını ekstra korumaya al"),
          _buildListTile(context, Icons.devices, "Giriş Yapılan Cihazlar", "Hesabına bağlı cihazları yönet"),
          
          const Divider(height: 30), // Araya şık bir çizgi
          
          // Gizlilik Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("Gizlilik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          _buildListTile(context, Icons.visibility_off, "Veri Kullanım İzinleri", "Hangi verilerinin işleneceğini seç"),
          _buildListTile(context, Icons.description, "Gizlilik Politikası", "Sözleşmeleri ve şartları oku"),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title yakında eklenecek!")),
          );
        },
      ),
    );
  }
}