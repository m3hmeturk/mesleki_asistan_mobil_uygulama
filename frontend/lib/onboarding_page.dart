import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _isLastPage = index == 2);
            },
            children: [
              _buildPage(
                icon: Icons.explore,
                title: "Kariyerini Keşfet",
                subtitle: "Yeteneklerine en uygun meslekleri ve sana özel yolları bul.",
                color: Colors.blue,
              ),
              _buildPage(
                icon: Icons.smart_toy,
                title: "Yapay Zeka Asistanın",
                subtitle: "Aklına takılan her soruyu, kariyer koçuna 7/24 anında sor.",
                color: Colors.deepPurple,
              ),
              _buildPage(
                icon: Icons.flag,
                title: "Yol Haritanı Çiz",
                subtitle: "Adım adım ilerle, başarıya giden yolu kendi ellerinle inşa et.",
                color: Colors.orange,
              ),
            ],
          ),
          
          Container(
            alignment: const Alignment(0, 0.85),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _controller.jumpToPage(2),
                  child: const Text("Geç", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                Row(
                  children: [
                    _buildDot(0),
                    _buildDot(1),
                    _buildDot(2),
                  ],
                ),
                
                GestureDetector(
                  onTap: () async {
                    if (_isLastPage) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_tamamlandi', true);
                      
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
                    }
                  },
                  child: Text(
                    _isLastPage ? "Başla" : "İleri", 
                    style: const TextStyle(color: Colors.deepPurple, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: color),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = (_controller.hasClients ? _controller.page!.round() : 0) == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 25 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.deepPurple : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}