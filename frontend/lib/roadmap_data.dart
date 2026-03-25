// lib/roadmap_data.dart

import 'roadmap_model.dart';

class RoadmapData {
  static RoadmapModel getByCareer(String careerKey) {
    switch (careerKey) {
      case 'yazilim':
        return _yazilimGelistirici();
      case 'tasarim':
        return _uxTasarimci();
      case 'veri':
        return _veriAnalisti();
      default:
        return _yazilimGelistirici();
    }
  }

  static String matchCareerFromTraits(List<String> traits) {
    int yazilim = 0, tasarim = 0, veri = 0;
    for (final t in traits) {
      final lower = t.toLowerCase();
      if (lower.contains('analitik') || lower.contains('problem') || lower.contains('mantık')) yazilim++;
      if (lower.contains('yaratıcı') || lower.contains('estetik') || lower.contains('görsel')) tasarim++;
      if (lower.contains('veri') || lower.contains('istatistik') || lower.contains('araştırma')) veri++;
    }
    if (tasarim >= yazilim && tasarim >= veri) return 'tasarim';
    if (veri >= yazilim) return 'veri';
    return 'yazilim';
  }

  static RoadmapModel _yazilimGelistirici() {
    return RoadmapModel(
      careerTitle: 'Yazılım Geliştirici',
      badges: [
        RoadmapBadge(id: 'b1', title: 'İlk Adım', description: 'İlk aşamayı tamamla', icon: 'rocket_launch', isEarned: true),
        RoadmapBadge(id: 'b2', title: 'Kod Ustası', description: 'Veri yapıları aşamasını bitir', icon: 'code', isEarned: true),
        RoadmapBadge(id: 'b3', title: 'Web Kaşifi', description: 'Web temelleri aşamasını tamamla', icon: 'language'),
        RoadmapBadge(id: 'b4', title: 'Tam Yığın', description: 'Backend aşamasını tamamla', icon: 'layers'),
      ],
      totalXP: 620,
      steps: [
        RoadmapStep(
          id: 's1', title: 'Temel Programlama',
          subtitle: 'Değişkenler, döngüler, fonksiyonlar',
          xpReward: 150, status: StepStatus.completed,
          tasks: [
            RoadmapTask(id: 't1', title: 'Python giriş kursu', isCompleted: true),
            RoadmapTask(id: 't2', title: 'Temel algoritmalar', isCompleted: true),
            RoadmapTask(id: 't3', title: 'Proje: Hesap makinesi', isCompleted: true),
          ],
        ),
        RoadmapStep(
          id: 's2', title: 'Veri Yapıları',
          subtitle: 'Liste, sözlük, ağaç, graf',
          xpReward: 200, status: StepStatus.completed,
          tasks: [
            RoadmapTask(id: 't4', title: 'Diziler ve listeler', isCompleted: true),
            RoadmapTask(id: 't5', title: 'Sözlük ve kümeler', isCompleted: true),
            RoadmapTask(id: 't6', title: 'Ağaç yapıları', isCompleted: true),
            RoadmapTask(id: 't7', title: 'Graf algoritmaları', isCompleted: true),
          ],
        ),
        RoadmapStep(
          id: 's3', title: 'Web Geliştirme Temelleri',
          subtitle: 'HTML, CSS, JavaScript',
          xpReward: 250, status: StepStatus.active,
          tasks: [
            RoadmapTask(id: 't8', title: 'HTML & CSS temelleri', isCompleted: true),
            RoadmapTask(id: 't9', title: 'JavaScript giriş', isCompleted: false),
            RoadmapTask(id: 't10', title: 'Proje: Kişisel portfolio', isCompleted: false),
          ],
        ),
        RoadmapStep(
          id: 's4', title: 'React & Bileşen Mimarisi',
          subtitle: 'Bileşenler, state, props, hooks',
          xpReward: 300, status: StepStatus.locked,
          tasks: [
            RoadmapTask(id: 't11', title: 'React temelleri'),
            RoadmapTask(id: 't12', title: 'State & Props'),
            RoadmapTask(id: 't13', title: 'React Hooks'),
            RoadmapTask(id: 't14', title: 'Proje: Todo uygulaması'),
          ],
        ),
      ],
    );
  }

  static RoadmapModel _uxTasarimci() {
    return RoadmapModel(
      careerTitle: 'UX/UI Tasarımcı',
      badges: [
        RoadmapBadge(id: 'b1', title: 'İlk Adım', description: 'Tasarım temellerini tamamla', icon: 'brush', isEarned: true),
      ],
      totalXP: 150,
      steps: [
        RoadmapStep(
          id: 's1', title: 'Tasarım Temelleri',
          subtitle: 'Renk teorisi, tipografi, ızgara',
          xpReward: 150, status: StepStatus.completed,
          tasks: [
            RoadmapTask(id: 't1', title: 'Renk teorisi', isCompleted: true),
          ],
        ),
      ],
    );
  }

  static RoadmapModel _veriAnalisti() {
    return RoadmapModel(
      careerTitle: 'Veri Analisti',
      badges: [],
      totalXP: 0,
      steps: [],
    );
  }
}