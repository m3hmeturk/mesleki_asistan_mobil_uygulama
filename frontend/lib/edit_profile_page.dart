import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentTitle;

  const EditProfilePage({super.key, required this.currentName, required this.currentTitle});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  
  String? _selectedStatus;
  File? _image;
  final picker = ImagePicker();

  final List<String> _kariyerDurumlari = [
    'Lise Öğrencisi',
    'Üniversite Öğrencisi',
    'Yeni Mezun / İş Arıyor',
    'Çalışan (Deneyimli)',
    'Girişimci / Kurucu',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _titleController = TextEditingController(text: widget.currentTitle);
    
    // Şimdilik buralar boş başlıyor, ileride veritabanından çekeceğiz
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _linkedinController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  // Galeriden Fotoğraf Seçme
  Future<void> _fotoSec() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // 🌟 GÜNCELLENDİ: Kaydederken kullanıcının gerçek UID'sini gönderiyoruz
  Future<void> _kaydet() async {
    // Firebase'den mevcut kullanıcıyı al
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oturum bulunamadı!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
    );

    try {
      String base64Image = "";
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/user/update_profile');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': user.uid, // 🌟 SİHİRLİ DOKUNUŞ: Sunucuya kim olduğumuzu söylüyoruz
          'ad_soyad': _nameController.text,
          'unvan': _titleController.text,
          'hakkimda': _bioController.text,
          'konum': _locationController.text,
          'kariyer_durumu': _selectedStatus ?? '',
          'linkedin': _linkedinController.text,
          'profil_foto': base64Image 
        }),
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Yükleniyor'u kapat
      Navigator.pop(context, true); // Başarılı sinyaliyle dön
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FOTOĞRAF ALANI ──
            Center(
              child: GestureDetector(
                onTap: _fotoSec,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                        ]
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary, 
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 3)
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text("Kişisel Bilgiler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),

            // ── FORM ALANLARI ──
            _buildTextField("Ad Soyad", _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField("Kariyer Unvanı (Örn: Yazılım Geliştirici)", _titleController, Icons.work_outline),
            const SizedBox(height: 16),
            _buildTextField("Konum (Örn: İstanbul, Türkiye)", _locationController, Icons.location_on_outlined),
            const SizedBox(height: 16),
            
            // Kariyer Durumu Açılır Menüsü (Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: "Mevcut Durum",
                prefixIcon: const Icon(Icons.school_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2))),
              ),
              items: _kariyerDurumlari.map((String durum) {
                return DropdownMenuItem(value: durum, child: Text(durum));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() { _selectedStatus = newValue; });
              },
            ),
            
            const SizedBox(height: 32),
            const Text("Detaylar & Bağlantılar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),

            // Hakkımda (Geniş Metin Alanı)
            _buildTextField("Hakkımda (Kısa bir biyografi yaz...)", _bioController, Icons.description_outlined, maxLines: 4),
            const SizedBox(height: 16),
            
            _buildTextField("LinkedIn Profil Linki", _linkedinController, Icons.link),
            
            const SizedBox(height: 40),

            // ── KAYDET BUTONU ──
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _kaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.5),
                ),
                child: const Text("Değişiklikleri Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Özelleştirilmiş TextField Şablonu
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1, // Biyografi kutusunda yazıyı yukarı hizalar
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)
        ),
      ),
    );
  }
}