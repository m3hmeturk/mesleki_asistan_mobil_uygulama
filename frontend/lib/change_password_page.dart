// lib/change_password_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Kontrolcüler
  final _mevcutSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();
  
  // Şifre gizleme durumları
  bool _mevcutGizli = true;
  bool _yeniGizli = true;
  bool _yeniTekrarGizli = true;
  
  bool _isLoading = false;

  // ── ŞİFRE GÜNCELLEME İŞLEMİ ──
  Future<void> _sifreGuncelle() async {
    if (!_formKey.currentState!.validate()) return; // Form hatalıysa dur

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception("Oturum bulunamadı.");

      // 1. Önce eski şifre ile kullanıcıyı yeniden doğrula (Firebase Güvenlik Kuralı)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: _mevcutSifreController.text.trim()
      );
      
      await user.reauthenticateWithCredential(credential);

      // 2. Yeniden doğrulama başarılıysa yeni şifreyi belirle
      await user.updatePassword(_yeniSifreController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Başarılı olursa önceki sayfaya (Güvenlik sayfasına) dön
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Şifren başarıyla güncellendi!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String errorMessage = "Bir hata oluştu.";
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMessage = "Mevcut şifreni yanlış girdin.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Yeni şifren çok zayıf. Daha güçlü bir şifre seçmelisin.";
      } else {
        errorMessage = "Hata: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beklenmedik Hata: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  void dispose() {
    _mevcutSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Şifremi Değiştir", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.lock_reset, size: 60, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Hesap güvenliğin için yeni şifrenin güçlü ve hatırlanabilir olduğundan emin ol.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── MEVCUT ŞİFRE ──
                  _buildPasswordField(
                    controller: _mevcutSifreController,
                    label: "Mevcut Şifre",
                    icon: Icons.lock_outline,
                    isObscure: _mevcutGizli,
                    onVisibilityToggle: () => setState(() => _mevcutGizli = !_mevcutGizli),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Mevcut şifreni girmelisin.";
                      return null;
                    },
                    theme: theme,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ── YENİ ŞİFRE ──
                  _buildPasswordField(
                    controller: _yeniSifreController,
                    label: "Yeni Şifre",
                    icon: Icons.vpn_key_outlined,
                    isObscure: _yeniGizli,
                    onVisibilityToggle: () => setState(() => _yeniGizli = !_yeniGizli),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Yeni şifreni girmelisin.";
                      if (value.length < 6) return "Şifre en az 6 karakter olmalıdır.";
                      return null;
                    },
                    theme: theme,
                  ),

                  const SizedBox(height: 16),
                  
                  // ── YENİ ŞİFRE TEKRAR ──
                  _buildPasswordField(
                    controller: _yeniSifreTekrarController,
                    label: "Yeni Şifreyi Tekrar Gir",
                    icon: Icons.check_circle_outline,
                    isObscure: _yeniTekrarGizli,
                    onVisibilityToggle: () => setState(() => _yeniTekrarGizli = !_yeniTekrarGizli),
                    validator: (value) {
                      if (value != _yeniSifreController.text) return "Şifreler eşleşmiyor.";
                      return null;
                    },
                    theme: theme,
                  ),

                  const SizedBox(height: 50),

                  // ── KAYDET BUTONU ──
                  ElevatedButton(
                    onPressed: _sifreGuncelle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Şifreyi Güncelle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Özel Şifre Alanı Tasarımı
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isObscure,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onVisibilityToggle,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
    );
  }
}