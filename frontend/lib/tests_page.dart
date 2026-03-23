import 'package:flutter/material.dart';

class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Kariyer Testleri",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Yeteneklerini keşfetmek için aşağıdaki testleri çözebilirsin.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),
        
        _buildTestCard(context, "Yazılım Alan Seçimi", "Hangi dil sana uygun?", Icons.code, Colors.blue),
        _buildTestCard(context, "Kişilik Envanteri", "Karakterine göre meslekler", Icons.psychology, Colors.orange),
        _buildTestCard(context, "İngilizce Seviyesi", "A1'den C1'e seviyeni ölç", Icons.translate, Colors.green),
        _buildTestCard(context, "Liderlik Potansiyeli", "Yönetici olabilir misin?", Icons.groups, Colors.red),
      ],
    );
  }

  Widget _buildTestCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // İleride buraya testin içeriği gelecek
        },
      ),
    );
  }
}