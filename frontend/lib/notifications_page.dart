// lib/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ── DURUM DEĞİŞKENLERİ ──
  bool _tumunuSustur = false;
  
  // Kariyer ve Fırsatlar
  bool _gunlukMotivasyon = true;
  bool _isFirsatlari = true;
  
  // Etkileşim
  bool _profilGoruntuleme = true;
  bool _yeniMesajlar = true;

  // İletişim Kanalları
  bool _emailBulteni = false;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  // ── HAFIZA İŞLEMLERİ ──
  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tumunuSustur = prefs.getBool('notif_tumunuSustur') ?? false;
      _gunlukMotivasyon = prefs.getBool('notif_gunlukMotivasyon') ?? true;
      _isFirsatlari = prefs.getBool('notif_isFirsatlari') ?? true;
      _profilGoruntuleme = prefs.getBool('notif_profilGoruntuleme') ?? true;
      _yeniMesajlar = prefs.getBool('notif_yeniMesajlar') ?? true;
      _emailBulteni = prefs.getBool('notif_emailBulteni') ?? false;
    });
  }

  Future<void> _ayarKaydet(String anahtar, bool deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(anahtar, deger);
  }

  // Ana şalter değiştiğinde alt şalterleri yönetme
  void _tumunuSusturDegisti(bool deger) {
    setState(() {
      _tumunuSustur = deger;
      _ayarKaydet('notif_tumunuSustur', deger);
      
      // Eğer tümü susturulduysa, alt bildirimlerin durumunu değiştirmene gerek yok
      // Arayüzde onları pasif (disabled) göstereceğiz.
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Bildirim Tercihleri", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 1. ANA ŞALTER (RAHATSIZ ETME) ──
          Container(
            decoration: BoxDecoration(
              color: _tumunuSustur ? Colors.redAccent.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _tumunuSustur ? Colors.redAccent.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: SwitchListTile(
              title: const Text("Tüm Bildirimleri Duraklat", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Geçici olarak rahatsız edilmek istemiyorum", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              secondary: Icon(_tumunuSustur ? Icons.notifications_off : Icons.notifications_active, color: _tumunuSustur ? Colors.redAccent : theme.colorScheme.primary),
              value: _tumunuSustur,
              activeColor: Colors.redAccent,
              onChanged: _tumunuSusturDegisti,
            ),
          ),
          
          const SizedBox(height: 30),

          // Eğer tümü susturulduysa UI'ı soluklaştırıyoruz (Opacity)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _tumunuSustur ? 0.4 : 1.0,
            child: AbsorbPointer(
              absorbing: _tumunuSustur, // Tıklamaları engeller
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 2. KARİYER VE FIRSATLAR ──
                  _bolumBasligi("Kariyer ve Fırsatlar", theme),
                  _ayarKarti(
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Günlük Kariyer Tavsiyeleri"),
                          subtitle: Text("AI destekli motivasyon ve gelişim ipuçları", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          secondary: const Icon(Icons.psychology_outlined, color: Colors.orange),
                          value: _gunlukMotivasyon,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() => _gunlukMotivasyon = val);
                            _ayarKaydet('notif_gunlukMotivasyon', val);
                          },
                        ),
                        _ayirici(theme),
                        SwitchListTile(
                          title: const Text("İş ve Staj Fırsatları"),
                          subtitle: Text("Profiline uygun yeni ilanlar eklendiğinde", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          secondary: const Icon(Icons.work_outline, color: Colors.blue),
                          value: _isFirsatlari,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() => _isFirsatlari = val);
                            _ayarKaydet('notif_isFirsatlari', val);
                          },
                        ),
                      ],
                    ),
                    theme,
                  ),

                  const SizedBox(height: 24),

                  // ── 3. UYGULAMA İÇİ ETKİLEŞİM ──
                  _bolumBasligi("Etkileşim", theme),
                  _ayarKarti(
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Profil Görüntülenmeleri"),
                          subtitle: Text("Bir şirket veya İK uzmanı CV'ni incelediğinde", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          secondary: const Icon(Icons.visibility_outlined, color: Colors.green),
                          value: _profilGoruntuleme,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() => _profilGoruntuleme = val);
                            _ayarKaydet('notif_profilGoruntuleme', val);
                          },
                        ),
                        _ayirici(theme),
                        SwitchListTile(
                          title: const Text("Sistem Uyarıları"),
                          subtitle: Text("Test sonuçların ve analizlerin hazır olduğunda", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          secondary: const Icon(Icons.analytics_outlined, color: Colors.deepPurpleAccent),
                          value: _yeniMesajlar,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) {
                            setState(() => _yeniMesajlar = val);
                            _ayarKaydet('notif_yeniMesajlar', val);
                          },
                        ),
                      ],
                    ),
                    theme,
                  ),

                  const SizedBox(height: 24),

                  // ── 4. İLETİŞİM KANALLARI ──
                  _bolumBasligi("Diğer İletişim Kanalları", theme),
                  _ayarKarti(
                    SwitchListTile(
                      title: const Text("E-Posta Bülteni"),
                      subtitle: Text("Haftalık kariyer bültenini mail adresime gönder", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      secondary: const Icon(Icons.email_outlined, color: Colors.teal),
                      value: _emailBulteni,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        setState(() => _emailBulteni = val);
                        _ayarKaydet('notif_emailBulteni', val);
                      },
                    ),
                    theme,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── YARDIMCI WIDGETLAR (Görselliği Korumak İçin) ──
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
    return Divider(height: 1, indent: 60, color: theme.colorScheme.onSurface.withOpacity(0.05));
  }
}