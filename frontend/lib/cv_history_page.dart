import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'api_config.dart';

class CVHistoryPage extends StatefulWidget {
  const CVHistoryPage({super.key});

  @override
  State<CVHistoryPage> createState() => _CVHistoryPageState();
}

class _CVHistoryPageState extends State<CVHistoryPage> {
  List _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // 1. API'den geçmişi çekme
  Future<void> _fetchHistory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/get_cv_history');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonim_kullanici'
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _history = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Arşiv çekilemedi: $e");
    }
  }

  // 2. Yerel hafızadaki PDF'i açma
  Future<void> _openExistingCV(String? fileName) async {
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya adı geçersiz.')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await OpenFilex.open(filePath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya bu telefonda bulunamadı. Silinmiş olabilir.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      print("Dosya açma hatası: $e");
    }
  }

  // 🚀 YENİ: Silme İşlemini Yapan Fonksiyon
  Future<void> _deleteCV(String cvId, int index) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/delete_cv');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonim_kullanici',
          'cv_id': cvId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _history.removeAt(index); // Listeden anında kaldır (UI güncelle)
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV başarıyla silindi.'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      print("Silme hatası: $e");
    }
  }

  // 🚀 YENİ: Silme Onay Penceresi
  void _showDeleteDialog(String cvId, int index, String jobTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // Koyu tema ile uyumlu
        title: const Text('CV\'yi Sil?', style: TextStyle(color: Colors.white)),
        content: Text('$jobTitle pozisyonu için hazırlanan CV kalıcı olarak silinecek. Emin misiniz?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Pencereyi kapat
              _deleteCV(cvId, index); // Silme işlemini başlat
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş CV\'lerim', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      const Text('Henüz üretilmiş bir CV yok.', 
                        style: TextStyle(color: Colors.grey, fontSize: 16)
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                        ),
                        title: Text(
                          item['hedef_meslek'] ?? 'Kariyer Belgesi',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '📅 ${item['tarih']}\n🎨 Şablon: ${item['sablon'].toString().toUpperCase()}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.open_in_new_rounded, color: Colors.deepPurpleAccent),
                        onTap: () => _openExistingCV(item['dosya_adi']),
                        // 🚀 YENİ EKLENEN BASILI TUTMA ÖZELLİĞİ BURADA:
                        onLongPress: () => _showDeleteDialog(
                          item['_id'], 
                          index, 
                          item['hedef_meslek'] ?? 'Kariyer Belgesi'
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}