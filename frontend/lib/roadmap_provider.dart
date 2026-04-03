// lib/roadmap_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'roadmap_model.dart';

class RoadmapProvider extends ChangeNotifier {
  RoadmapModel? _model;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;

  RoadmapModel? get model => _model;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;

  RoadmapProvider() {
    // initFromCareer('yazilim'); ---> SAHTE HARİTAYI SİLDİK! Artık boş başlıyor.
    fetchDashboardData();
  }

  // 1. DASHBOARD VERİSİNİ ÇEK (Eski Kodumuz)
  Future<void> fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final response = await http.post(
        Uri.parse('http://10.24.2.85:5000/api/dashboard'), // IP Kontrol!
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({"uid": user.uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _dashboardData = data['data'];
      }
    } catch (e) {
      print("Dashboard veri çekme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. YENİ: YAPAY ZEKA İLE YOL HARİTASI ÜRET VE JSON'U ÇEVİR
  Future<void> generateRoadmap(String career) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners(); // Yükleme animasyonunu başlat

    try {
      final response = await http.post(
        Uri.parse('http://10.24.2.85:5000/api/generate_roadmap'),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "uid": user.uid,
          "career": career
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final roadmapJson = responseData['roadmap'];

        // Gelen JSON'u Flutter'ın anlayacağı Modele (RoadmapStep) çeviriyoruz
        List<RoadmapStep> parsedSteps = [];
        for (var step in roadmapJson['steps']) {
          List<RoadmapTask> parsedTasks = [];
          for (var task in step['tasks']) {
            parsedTasks.add(RoadmapTask(
              id: task['id'] ?? UniqueKey().toString(),
              title: task['title'] ?? 'Görev',
              isCompleted: false,
            ));
          }
          parsedSteps.add(RoadmapStep(
            id: step['id'] ?? UniqueKey().toString(),
            title: step['title'] ?? 'Aşama',
            subtitle: step['subtitle'] ?? '',
            xpReward: step['xpReward'] ?? 100,
            tasks: parsedTasks,
            status: parsedSteps.isEmpty ? StepStatus.active : StepStatus.locked, // İlki aktif başlar
          ));
        }

        _model = RoadmapModel(
          careerTitle: roadmapJson['careerTitle'] ?? career,
          steps: parsedSteps,
          badges: [
            RoadmapBadge(id: 'b1', title: 'İlk Adım', description: 'Yol haritasına başladın', icon: 'rocket_launch', isEarned: false),
          ],
          totalXP: 0,
        );
      }
    } catch (e) {
      print("Yol haritası oluşturma hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Görevi Tamamla veya Geri Al (Toggle)
  void toggleTask(String stepId, String taskId) {
    if (_model == null) return;
    final step = _model!.steps.firstWhere((s) => s.id == stepId);
    final taskIndex = step.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    bool suAnkiDurum = step.tasks[taskIndex].isCompleted;
    step.tasks[taskIndex] = step.tasks[taskIndex].copyWith(isCompleted: !suAnkiDurum);

    if (suAnkiDurum == true && step.status == StepStatus.completed) {
      step.status = StepStatus.active;
      _model!.totalXP -= step.xpReward;
    } else if (step.allTasksDone && step.status == StepStatus.active) {
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
      if (steps[i].status == StepStatus.completed && steps[i + 1].status == StepStatus.locked) {
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