// lib/roadmap_model.dart

enum StepStatus { completed, active, locked }

class RoadmapTask {
  final String id;
  final String title;
  bool isCompleted;

  RoadmapTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  RoadmapTask copyWith({bool? isCompleted}) => RoadmapTask(
        id: id,
        title: title,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class RoadmapStep {
  final String id;
  final String title;
  final String subtitle;
  final int xpReward;
  final List<RoadmapTask> tasks;
  StepStatus status;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.tasks,
    this.status = StepStatus.locked,
  });

  double get progress {
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.isCompleted).length / tasks.length;
  }

  bool get allTasksDone => tasks.every((t) => t.isCompleted);
}

class RoadmapBadge {
  final String id;
  final String title;
  final String description;
  final String icon; 
  bool isEarned;

  RoadmapBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isEarned = false,
  });
}

class RoadmapModel {
  final String careerTitle;
  final List<RoadmapStep> steps;
  final List<RoadmapBadge> badges;
  int totalXP;

  RoadmapModel({
    required this.careerTitle,
    required this.steps,
    required this.badges,
    this.totalXP = 0,
  });

  int get level => (totalXP / 1000).floor() + 1;
  double get levelProgress => (totalXP % 1000) / 1000;
  int get completedStepCount => steps.where((s) => s.status == StepStatus.completed).length;
  int get earnedBadgeCount => badges.where((b) => b.isEarned).length;
}