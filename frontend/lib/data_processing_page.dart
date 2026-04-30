// lib/data_processing_page.dart

import 'package:flutter/material.dart';

class DataProcessingPage extends StatelessWidget {
  const DataProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Verilerim Nasıl İşleniyor?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── ÜST KISIM (VİTRİN) ──
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics_outlined, size: 60, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Kariyer Asistanı'nda Şeffaflık İlkesi",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Verileriniz bir kara deliğe gitmez. Aşağıda, verilerinizin cihazınızdan çıkıp size kariyer tavsiyesi olarak dönene kadar geçirdiği yolculuğu adım adım görebilirsiniz.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 40),

          // ── VERİ YOLCULUĞU ADIMLARI (TIMELINE TASARIMI) ──
          _buildJourneyStep(
            theme,
            stepNumber: "1",
            icon: Icons.data_object,
            title: "Veri Toplama",
            description: "Uygulamada çözdüğünüz testler, yetenekleriniz ve profil bilgileriniz anlık olarak toplanır.",
          ),
          _buildJourneyConnector(theme),
          
          _buildJourneyStep(
            theme,
            stepNumber: "2",
            icon: Icons.enhanced_encryption_outlined,
            title: "Uçtan Uca Şifreleme",
            description: "Verileriniz telefonunuzdan çıkarken 256-bit banka düzeyinde şifreleme ile paketlenir ve sunucularımıza güvenle iletilir.",
          ),
          _buildJourneyConnector(theme),

          _buildJourneyStep(
            theme,
            stepNumber: "3",
            icon: Icons.psychology_outlined,
            title: "Yapay Zeka (AI) Analizi",
            description: "Şifresi çözülen verileriniz, sadece size özel kariyer analizi yapmak için AI motoruna gönderilir. Verileriniz AI modelini eğitmek için KULLANILMAZ ve anonim tutulur.",
          ),
          _buildJourneyConnector(theme),

          _buildJourneyStep(
            theme,
            stepNumber: "4",
            icon: Icons.cloud_done_outlined,
            title: "Güvenli Depolama",
            description: "Analiz sonuçlarınız ve Kariyer DNA'nız, yüksek güvenlikli Google Cloud (Firebase) sunucularında, sizin kimliğinize kilitli bir şekilde saklanır.",
          ),
          _buildJourneyConnector(theme),

          _buildJourneyStep(
            theme,
            stepNumber: "5",
            icon: Icons.delete_sweep_outlined,
            title: "Tam Kontrol Sizde",
            description: "Tüm bu süreci istediğiniz an durdurabilir, 'Hesabımı Sil' veya 'Kariyer DNA'mı Sıfırla' butonları ile geride hiçbir iz bırakmadan verilerinizi yok edebilirsiniz.",
            isFinal: true,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── YARDIMCI WIDGETLAR (Zaman Çizelgesi Görünümü İçin) ──

  Widget _buildJourneyStep(ThemeData theme, {required String stepNumber, required IconData icon, required String title, required String description, bool isFinal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol Taraf: İkon ve Numara
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isFinal ? Colors.redAccent.withOpacity(0.1) : theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: isFinal ? Colors.redAccent : theme.colorScheme.primary, width: 2),
              ),
              child: Center(child: Icon(icon, color: isFinal ? Colors.redAccent : theme.colorScheme.primary, size: 24)),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Sağ Taraf: Metinler
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ADIM $stepNumber: $title",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isFinal ? Colors.redAccent : theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyConnector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 30,
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
    );
  }
}