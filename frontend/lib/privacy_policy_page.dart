// lib/privacy_policy_page.dart

import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Gizlilik Politikası", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ÜST BİLGİ ──
          Icon(Icons.privacy_tip, size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            "Kariyer Asistanı olarak verilerinizin güvenliği bizim için en yüksek önceliktir. Hangi verileri, neden topladığımızı ve nasıl koruduğumuzu aşağıda şeffafça açıklıyoruz.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 30),

          // ── AKORDEON MADDELER ──
          _buildPolicySection(
            theme,
            icon: Icons.data_usage,
            title: "1. Hangi Verileri Topluyoruz?",
            content: "• Kimlik Verileri: Ad, soyad, e-posta adresi, profil fotoğrafı.\n"
                     "• Kariyer Verileri: Unvan, konum, LinkedIn URL'si, özgeçmiş detayları.\n"
                     "• Analiz Verileri: Çözdüğünüz testlerin sonuçları (Kariyer DNA'sı) ve yapay zeka ile yaptığınız yazışmalar.",
          ),
          _buildPolicySection(
            theme,
            icon: Icons.psychology,
            title: "2. Verileri Nasıl Kullanıyoruz?",
            content: "Topladığımız veriler, size özel kariyer fırsatları sunmak, yapay zeka destekli gelişim tavsiyeleri üretmek ve uygulama içi deneyiminizi kişiselleştirmek amacıyla kullanılmaktadır. Verileriniz asla reklam veya pazarlama amacıyla satılmaz.",
          ),
          _buildPolicySection(
            theme,
            icon: Icons.cloud_done_outlined,
            title: "3. Veri Saklama ve Güvenlik",
            content: "Verileriniz, Google Cloud (Firebase) ve MongoDB altyapılarında yüksek güvenlik standartlarıyla (SSL/TLS ve AES-256 şifreleme) saklanmaktadır. Sisteme erişimler şifrelenmiş kimlik doğrulama protokolleri ile korunur.",
          ),
          _buildPolicySection(
            theme,
            icon: Icons.shield_outlined,
            title: "4. Üçüncü Taraflarla Paylaşım",
            content: "Kariyer Asistanı, temel işlevlerini yerine getirmek (AI analizi vb.) dışında verilerinizi 3. şahıs veya kurumlarla paylaşmaz. Yapay zeka modüllerine gönderilen veriler anonimleştirilerek işlenir.",
          ),
          _buildPolicySection(
            theme,
            icon: Icons.delete_sweep_outlined,
            title: "5. Kullanıcı Hakları (Veri İmhası)",
            content: "Kullanıcılarımız diledikleri zaman uygulamanın 'Gizlilik ve Güvenlik' sekmesinden 'Hesabımı Kalıcı Olarak Sil' özelliğini kullanarak tüm kimlik, test ve kariyer verilerini sunucularımızdan tamamen silebilirler.",
          ),
          _buildPolicySection(
            theme,
            icon: Icons.mail_outline,
            title: "6. İletişim",
            content: "Gizlilik politikamızla ilgili her türlü soru, görüş ve veri talebiniz için destek@kariyerbot.com adresi üzerinden bizimle iletişime geçebilirsiniz.",
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "Son Güncelleme: Nisan 2026",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── YARDIMCI WIDGET: Açılır Kapanır Kutu (ExpansionTile) ──
  Widget _buildPolicySection(ThemeData theme, {required IconData icon, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Theme(
        // Açıldığında oluşan o çirkin çizgileri yok etmek için
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: Colors.grey,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                content,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.6, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}