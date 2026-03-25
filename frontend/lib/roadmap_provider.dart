// lib/roadmap_provider.dart

import 'package:flutter/material.dart';
import 'roadmap_model.dart';
import 'roadmap_data.dart';

class RoadmapProvider extends ChangeNotifier {
  RoadmapModel? _model;
  bool _isLoading = false;

  RoadmapModel? get model => _model;
  bool get isLoading => _isLoading;

  RoadmapProvider() {
    initFromCareer('yazilim');
  }

  void initFromTraits(List<String> traits) {
    _isLoading = true;
    notifyListeners();

    final careerKey = RoadmapData.matchCareerFromTraits(traits);
    _model = RoadmapData.getByCareer(careerKey);

    _isLoading = false;
    notifyListeners();
  }

  void initFromCareer(String careerKey) {
    _model = RoadmapData.getByCareer(careerKey);
    notifyListeners();
  }

  // Görevi Tamamla veya Geri Al (Toggle)
  void toggleTask(String stepId, String taskId) {
    if (_model == null) return;

    final step = _model!.steps.firstWhere((s) => s.id == stepId);
    final taskIndex = step.tasks.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) return;

    // Şu anki durumun tersine çevir (True ise False, False ise True yap)
    bool suAnkiDurum = step.tasks[taskIndex].isCompleted;
    step.tasks[taskIndex] = step.tasks[taskIndex].copyWith(isCompleted: !suAnkiDurum);

    // Eğer tiki KALDIRDIYSAK (Geri aldıysak) ve aşama "Bitti" görünüyorsa onu tekrar "Sırada" yap ve XP'yi geri al
    if (suAnkiDurum == true && step.status == StepStatus.completed) {
      step.status = StepStatus.active;
      _model!.totalXP -= step.xpReward;
    } 
    // Eğer tiki ATTIYSAK ve tüm görevler bittiyse aşamayı tamamla
    else if (step.allTasksDone && step.status == StepStatus.active) {
      step.status = StepStatus.completed;
      _model!.totalXP += step.xpReward;
      _unlockNextStep();
      _checkBadges(stepId);
    }
    
    notifyListeners();
  }

  void _unlockNextStep() {
    final steps = _model!.steps;
    for (int i = 0; i < steps.length - 1; i++) {
      if (steps[i].status == StepStatus.completed &&
          steps[i + 1].status == StepStatus.locked) {
        steps[i + 1].status = StepStatus.active;
        break;
      }
    }
  }

  void _checkBadges(String completedStepId) {
    final stepIndex = _model!.steps.indexWhere((s) => s.id == completedStepId);
    if (stepIndex < _model!.badges.length) {
      _model!.badges[stepIndex].isEarned = true;
    }
  }
}