// lib/usage_terms_page.dart

import 'package:flutter/material.dart';

class UsageTermsPage extends StatelessWidget {
  const UsageTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Kullanım Koşulları", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ÜST BİLGİ ──
          Icon(Icons.gavel_outlined, size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            "Kariyer Asistanı uygulamasını kullanarak aşağıdaki şartları kabul etmiş sayılırsınız. Lütfen bu koşulları dikkatlice okuyunuz.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 30),

          // ── AKORDEON MADDELER ──
          _buildTermSection(
            theme,
            icon: Icons.account_circle_outlined,
            title: "1. Hesap Güvenliği",
            content: "Kullanıcılar, hesap bilgilerinin ve şifrelerinin gizliliğinden kendileri sorumludur. Hesabınız üzerinden yapılan tüm işlemler sizin sorumluluğunuzdadır. Şüpheli bir durumda derhal bizimle iletişime geçmelisiniz.",
          ),
          _buildTermSection(
            theme,
            icon: Icons.auto_awesome_outlined,
            title: "2. Yapay Zeka ve Tavsiyeler",
            content: "Kariyer Asistanı, yapay zeka algoritmaları kullanarak tavsiyeler üretir. Bu tavsiyeler 'olduğu gibi' sunulur ve yasal veya profesyonel bir garanti teşkil etmez. Kariyer kararlarınızda son sorumluluk size aittir.",
          ),
          _buildTermSection(
            theme,
            icon: Icons.block_outlined,
            title: "3. Yasaklı Kullanımlar",
            content: "Uygulamanın tersine mühendislik yoluyla kopyalanması, sistemlerimize saldırı düzenlenmesi veya yapay zeka modelinin kötüye kullanılması durumunda hesabınız kalıcı olarak kapatılabilir.",
          ),
          _buildTermSection(
            theme,
            icon: Icons.copyright_outlined,
            title: "4. Fikri Mülkiyet",
            content: "Uygulama tasarımı, logolar, yazılım kodları ve AI algoritmaları Kariyer Asistanı'nın mülkiyetindedir. İzinsiz kullanılması veya çoğaltılması yasaktır.",
          ),
          _buildTermSection(
            theme,
            icon: Icons.update_outlined,
            title: "5. Hizmet Değişiklikleri",
            content: "Kariyer Asistanı, uygulama özelliklerini önceden haber vermeksizin güncelleme, değiştirme veya geçici olarak askıya alma hakkını saklı tutar.",
          ),
          _buildTermSection(
            theme,
            icon: Icons.warning_amber_outlined,
            title: "6. Sorumluluk Sınırlandırması",
            content: "Uygulamanın kullanımından kaynaklanabilecek veri kaybı, iş kaybı veya benzeri dolaylı zararlardan Kariyer Asistanı sorumlu tutulamaz.",
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

  // ── YARDIMCI WIDGET: Açılır Kapanır Kutu ──
  Widget _buildTermSection(ThemeData theme, {required IconData icon, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Theme(
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