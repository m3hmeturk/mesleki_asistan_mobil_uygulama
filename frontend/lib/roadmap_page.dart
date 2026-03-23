import 'package:flutter/material.dart';

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Kariyer Yol Haritam",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        _buildStepCard("1. Adım: Temel Eğitim", "Flutter ve Dart temellerini öğren.", true),
        _buildStepCard("2. Adım: İlk Proje", "Küçük bir not defteri uygulaması yap.", true),
        _buildStepCard("3. Adım: API Entegrasyonu", "Yapay zeka bağlantısını kur.", false),
        _buildStepCard("4. Adım: Staj & İş", "İlk profesyonel deneyimini kazan.", false),
      ],
    );
  }

  Widget _buildStepCard(String title, String desc, bool isDone) {
    return Row(
      children: [
        Column(
          children: [
            Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, 
                 color: isDone ? Colors.green : Colors.grey),
            Container(width: 2, height: 50, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}