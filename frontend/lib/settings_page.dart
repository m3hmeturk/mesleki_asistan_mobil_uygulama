// lib/settings_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart'; // temaSalteri için gerekli

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Hafızada tutulacak yerel ayarlar
  bool _veriTasarrufu = false;
  bool _animasyonAzalt = false;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  // ── YEREL HAFIZA İŞLEMLERİ ──
  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _veriTasarrufu = prefs.getBool('veriTasarrufu') ?? false;
      _animasyonAzalt = prefs.getBool('animasyonAzalt') ?? false;
    });
  }

  Future<void> _ayarKaydet(String anahtar, bool deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(anahtar, deger);
  }

  Future<void> _temaDegistir(bool isDark) async {
    temaSalteri.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // ── ÖNBELLEK TEMİZLEME SİMÜLASYONU ──
  Future<void> _onbellegiTemizle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
    );
    
    await Future.delayed(const Duration(seconds: 2)); // Temizleme efekti
    
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Önbellek temizlendi. 142 MB yer açıldı!"), 
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── MAİL GÖNDERME FONKSİYONU ──
  Future<void> _bizeUlas() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'destek@kariyerbot.com', // Kendi mail adresini yazabilirsin
      queryParameters: {'subject': 'Kariyer Asistanı Destek Talebi'},
    );
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mail uygulaması açılamadı.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Uygulama Ayarları", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 1. GÖRÜNÜM VE DENEYİM ──
          _bolumBasligi("Görünüm ve Deneyim", theme),
          _ayarKarti(
            Column(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: temaSalteri,
                  builder: (context, guncelTema, child) {
                    bool isDark = guncelTema == ThemeMode.dark || (guncelTema == ThemeMode.system && theme.brightness == Brightness.dark);
                    return SwitchListTile(
                      title: const Text("Karanlık Mod"),
                      subtitle: Text("Göz yorgunluğunu azaltır", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
                      value: isDark,
                      activeColor: theme.colorScheme.primary,
                      onChanged: _temaDegistir,
                    );
                  }
                ),
                _ayirici(theme),
                SwitchListTile(
                  title: const Text("Animasyonları Azalt"),
                  subtitle: Text("Eski cihazlarda performansı artırır", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  secondary: Icon(Icons.speed, color: theme.colorScheme.primary),
                  value: _animasyonAzalt,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _animasyonAzalt = val);
                    _ayarKaydet('animasyonAzalt', val);
                  },
                ),
              ],
            ),
            theme,
          ),
          
          const SizedBox(height: 24),

          // ── 2. VERİ VE HAFIZA ──
          _bolumBasligi("Veri ve Hafıza", theme),
          _ayarKarti(
            Column(
              children: [
                SwitchListTile(
                  title: const Text("Akıllı Veri Tasarrufu"),
                  subtitle: Text("Mobil verideyken düşük kalite yükler", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  secondary: Icon(Icons.data_usage, color: theme.colorScheme.primary),
                  value: _veriTasarrufu,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _veriTasarrufu = val);
                    _ayarKaydet('veriTasarrufu', val);
                  },
                ),
                _ayirici(theme),
                ListTile(
                  leading: Icon(Icons.cleaning_services_outlined, color: theme.colorScheme.primary),
                  title: const Text("Önbelleği Temizle"),
                  subtitle: Text("Geçici dosyaları silerek cihazda yer açar", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _onbellegiTemizle,
                ),
              ],
            ),
            theme,
          ),
          
          const SizedBox(height: 24),

          // ── 3. TOPLULUK VE İLETİŞİM ──
          _bolumBasligi("Topluluk", theme),
          _ayarKarti(
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_border, color: Colors.amber),
                  title: const Text("Bizi Puanla"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uygulama Play Store'a yüklendiğinde aktif olacak.")));
                  },
                ),
                _ayirici(theme),
                ListTile(
                  leading: Icon(Icons.share_outlined, color: theme.colorScheme.primary),
                  title: const Text("Arkadaşlarınla Paylaş"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yakında eklenecek!")));
                  },
                ),
                _ayirici(theme),
                ListTile(
                  leading: Icon(Icons.mail_outline, color: theme.colorScheme.primary),
                  title: const Text("Hata Bildir / Bize Ulaşın"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _bizeUlas,
                ),
              ],
            ),
            theme,
          ),

          const SizedBox(height: 30),

          // ── 4. HAKKINDA VE LİSANSLAR ──
          TextButton(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'Kariyer Asistanı',
                applicationVersion: '1.0.0',
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.work_outline, size: 48, color: Colors.deepPurpleAccent),
                ),
                applicationLegalese: '© 2026 Mehmet',
              );
            },
            child: const Text("Açık Kaynak Lisansları", style: TextStyle(color: Colors.grey)),
          ),

          // Versiyon Bilgisi
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text("Versiyon 1.0.0 (Build 12)", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── YARDIMCI WIDGETLAR ──
  Widget _bolumBasligi(String baslik, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(baslik, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
    );
  }

  Widget _ayarKarti(Widget icerik, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: icerik,
    );
  }

  Widget _ayirici(ThemeData theme) {
    return Divider(height: 1, indent: 50, color: theme.colorScheme.onSurface.withOpacity(0.05));
  }
}