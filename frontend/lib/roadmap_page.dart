// lib/roadmap_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'roadmap_provider.dart';
import 'roadmap_model.dart';
import 'ai_service.dart';

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoadmapProvider>();

    // 1. Veriler Flask'tan gelirken ekranda şık bir yüklenme animasyonu göster
    if (provider.isLoading || provider.dashboardData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Gelişim Merkezin Hazırlanıyor...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    // 🌟 YENİ EKLENEN HAYAT KURTARICI KOD: Eğer harita boşsa, YZ Butonlu ekranı göster!
    if (provider.model == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            'Gelişim Merkezim',
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: _EmptyState(), // Az önce yazdığımız butonlu ekran buraya gelecek!
      );
    }
    final model = provider.model!;
    final dashboard = provider.dashboardData!; // FLASK'TAN GELEN GERÇEK VERİ KUTUMUZ!
    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Gelişim Merkezim', // Artık sayfanın adı bu!
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            onPressed: () => _showDictionarySheet(context),
          ),
          IconButton(
            icon: Icon(Icons.emoji_events, color: Colors.amber.shade600),
            onPressed: () => _showBadgesSheet(context, model, dashboard['badges'] ?? []), // Gerçek rozetleri gönderiyoruz
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SummaryCard(model: model, dashboard: dashboard), // KARTA GERÇEK VERİYİ VERDİK!
          const SizedBox(height: 25),
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'KİŞİSELLEŞTİRİLMİŞ YOL HARİTASI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _TimelineWidget(model: model),
        ],
      ),
    );
  }

  void _showBadgesSheet(BuildContext context, RoadmapModel model, List<dynamic> earnedBadgeIds) {
    // Backend'den gelen kazandığımız rozetlerin ID'lerini UI ile eşleştiriyoruz
    for (var badge in model.badges) {
      badge.isEarned = earnedBadgeIds.contains(badge.id) || earnedBadgeIds.contains("ilk_mulakat");
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BadgesSheet(badges: model.badges),
    );
  }

  void _showDictionarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DictionarySheet(),
    );
  }
}

// ── Özet Kart (GERÇEK VERİLERLE ÇALIŞAN KISIM) ───────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final RoadmapModel model;
  final Map<String, dynamic> dashboard; // Backend verisi buraya geldi
  
  const _SummaryCard({required this.model, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // --- FLASK'TAN GELEN DEĞERLERİ ÇIKARTIYORUZ ---
    final ad = dashboard['ad'] ?? "Kullanıcı";
    final levelInfo = dashboard['level'] ?? {};
    final currentLevel = levelInfo['current'] ?? 1;
    final xp = levelInfo['xp'] ?? 0;
    final xpForNext = levelInfo['xp_for_next'] ?? 100;
    
    final stats = dashboard['stats'] ?? {};
    final totalInterviews = stats['total_interviews'] ?? 0;
    final earnedBadgesCount = (dashboard['badges'] as List?)?.length ?? 0;
    
    // XP Barının % kaç dolu olduğunu matematiğe döküyoruz
    double levelProgress = (xp % xpForNext) / xpForNext;
    if (levelProgress.isNaN || levelProgress.isInfinite) levelProgress = 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.rocket_launch, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Merhaba, $ad! 👋', // GERÇEK ADIN YAZIYOR
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        )),
                    Text('Hedef: ${model.careerTitle}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        )),
                  ],
                ),
              ),
              _StatusBadge(label: 'Seviye $currentLevel', color: Colors.teal), // GERÇEK SEVİYE
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatBox(value: '$xp', label: 'Toplam XP', context: context), // GERÇEK XP
              const SizedBox(width: 10),
              _StatBox(value: '$totalInterviews', label: 'Mülakat', context: context), // GERÇEK MÜLAKAT
              const SizedBox(width: 10),
              _StatBox(value: '$earnedBadgesCount', label: 'Rozet', context: context), // GERÇEK ROZET SAYISI
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text('Lv.$currentLevel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: levelProgress, // BARI GERÇEK XP İLE DOLDURDUK
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${xp % xpForNext} / $xpForNext', // KALAN XP'Yİ GÖSTERDİK
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}
class _StatBox extends StatelessWidget {
  final String value, label;
  final BuildContext context;
  const _StatBox({required this.value, required this.label, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ── Timeline ───────────────────────────────────────────────────────────────
class _TimelineWidget extends StatelessWidget {
  final RoadmapModel model;
  const _TimelineWidget({required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(model.steps.length, (i) {
        final step = model.steps[i];
        final isLast = i == model.steps.length - 1;
        return _TimelineItem(step: step, isLast: isLast);
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final RoadmapStep step;
  final bool isLast;
  const _TimelineItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color dotColor;
    Color dotBorder;
    Widget dotChild;

    switch (step.status) {
      case StepStatus.completed:
        dotColor = Colors.teal.withValues(alpha: 0.2);
        dotBorder = Colors.teal;
        dotChild = const Icon(Icons.check, color: Colors.teal, size: 16);
        break;
      case StepStatus.active:
        dotColor = theme.colorScheme.primary.withValues(alpha: 0.2);
        dotBorder = theme.colorScheme.primary;
        dotChild = Icon(Icons.play_arrow, color: theme.colorScheme.primary, size: 16);
        break;
      case StepStatus.locked:
        dotColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
        dotBorder = theme.colorScheme.outline.withValues(alpha: 0.3);
        dotChild = Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4));
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotBorder, width: 2),
                  ),
                  child: Center(child: dotChild),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.status == StepStatus.completed 
                          ? Colors.teal.withValues(alpha: 0.5) 
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: GestureDetector(
                onTap: step.status != StepStatus.locked
                    ? () => _showStepDetail(context, step)
                    : null,
                child: _StepCard(step: step),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStepDetail(BuildContext context, RoadmapStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StepDetailSheet(step: step),
    );
  }
}

class _StepCard extends StatelessWidget {
  final RoadmapStep step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = step.status == StepStatus.locked;
    final isActive = step.status == StepStatus.active;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(step.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ),
                _stepBadge(theme),
              ],
            ),
            const SizedBox(height: 6),
            Text(step.subtitle,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...step.tasks.take(2).map((t) => _TaskChip(task: t)),
                if (step.tasks.length > 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('+${step.tasks.length - 2} görev', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ),
                _XpChip(xp: step.xpReward, theme: theme),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: step.progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${step.tasks.where((t) => t.isCompleted).length}/${step.tasks.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepBadge(ThemeData theme) {
    switch (step.status) {
      case StepStatus.completed:
        return _StatusBadge(label: 'Bitti', color: Colors.teal);
      case StepStatus.active:
        return _StatusBadge(label: 'Sırada', color: theme.colorScheme.primary);
      case StepStatus.locked:
        return const SizedBox.shrink(); 
    }
  }
}

class _TaskChip extends StatelessWidget {
  final RoadmapTask task;
  const _TaskChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.teal.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: task.isCompleted ? Border.all(color: Colors.teal.withValues(alpha: 0.3)) : null,
      ),
      child: Text(task.title,
          style: TextStyle(
              fontSize: 11,
              color: task.isCompleted ? Colors.teal : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
    );
  }
}

class _XpChip extends StatelessWidget {
  final int xp;
  final ThemeData theme;
  const _XpChip({required this.xp, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Text('+$xp',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }
}

// ── Görev Detay Bottom Sheet ───────────────────────────────────────────────
class _StepDetailSheet extends StatelessWidget {
  final RoadmapStep step;
  const _StepDetailSheet({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // SİHİRLİ DOKUNUŞ 1: read yerine "watch" kullanıyoruz. Artık bu pencere canlı yayında!
    final provider = context.watch<RoadmapProvider>(); 
    
    // SİHİRLİ DOKUNUŞ 2: Provider'dan bu aşamanın EN GÜNCEL (anlık) halini çekiyoruz
    final guncelStep = provider.model!.steps.firstWhere((s) => s.id == step.id);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(guncelStep.title, // Artık step değil guncelStep kullanıyoruz
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(guncelStep.subtitle,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 30),
            Text('GÖREV LİSTESİ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            
            ...guncelStep.tasks.map((task) => _TaskTile(
                  task: task,
                  stepId: guncelStep.id,
                  // ESKİSİ: canCheck: guncelStep.status == StepStatus.active,
                  // YENİSİ: (Aşama kilitli değilse her zaman tıklanabilsin)
                  canCheck: guncelStep.status != StepStatus.locked, 
                  provider: provider,
                )),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Tüm görevleri bitirerek bu aşamadan +${guncelStep.xpReward} XP kazanabilirsin.',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final RoadmapTask task;
  final String stepId;
  final bool canCheck;
  final RoadmapProvider provider;

  const _TaskTile({required this.task, required this.stepId, required this.canCheck, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          // SİHİRLİ DOKUNUŞ 3: "!task.isCompleted" kısıtlamasını SİLDİK! Artık her zaman basılabilir.
          onTap: canCheck 
              ? () => provider.toggleTask(stepId, task.id)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? Colors.teal : Colors.transparent,
              border: Border.all(
                color: task.isCompleted ? Colors.teal : theme.colorScheme.outline.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: task.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Rozet Sheet ────────────────────────────────────────────────────────────
class _BadgesSheet extends StatelessWidget {
  final List<RoadmapBadge> badges;
  const _BadgesSheet({required this.badges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 28),
              const SizedBox(width: 10),
              Text('Kazanılan Rozetler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 20, runSpacing: 20,
            children: badges.map((b) => _BadgeItem(badge: b)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final RoadmapBadge badge;
  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: badge.isEarned ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.isEarned ? Colors.amber.withValues(alpha: 0.15) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              border: badge.isEarned 
                  ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
                  : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.star, // Şimdilik hep yıldız ikonu koyduk, ileride değiştirilebilir
              color: badge.isEarned ? Colors.amber.shade600 : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 35,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 80,
            child: Text(badge.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

// ── Boş Durum (YENİ YAPAY ZEKA BUTONLU HALİ) ──────────────────────────────────
class _EmptyState extends StatefulWidget {
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  final TextEditingController _hedefController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<RoadmapProvider>(); // read kullanıyoruz çünkü butona basınca tetikleyeceğiz

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text('Yol Haritan Henüz Yok',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text('Yapay zekanın senin test sonuçlarına göre özel bir eğitim haritası çizmesine izin ver.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 30),
            TextField(
              controller: _hedefController,
              decoration: InputDecoration(
                labelText: "Hedef Mesleğin Nedir? (Örn: Siber Güvenlik)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: Icon(Icons.work, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_hedefController.text.isNotEmpty) {
                    provider.generateRoadmap(_hedefController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen bir meslek girin!")),
                    );
                  }
                },
                icon: const Icon(Icons.rocket_launch, color: Colors.white),
                label: const Text("Yapay Zeka ile Oluştur", style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ── Jargon Sözlüğü Bottom Sheet (Yapay Zeka Destekli) ──────────────
class _DictionarySheet extends StatefulWidget {
  const _DictionarySheet();

  @override
  State<_DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<_DictionarySheet> {
  String aramaMetni = "";
  bool _isAiLoading = false;
  String? _aiCevap;

  // Kendi yerel sözlüğümüz (Hızlı sonuçlar için)
  final List<Map<String, String>> sozluk = [
    {"term": "API", "desc": "Farklı yazılımların birbiriyle iletişim kurmasını sağlayan dijital köprü."},
    {"term": "Backend", "desc": "Bir uygulamanın kullanıcı tarafından görünmeyen, veritabanı ve sunucu tarafı."},
    {"term": "Frontend", "desc": "Kullanıcının etkileşime girdiği, uygulamanın ön yüzü ve tasarımı."},
    {"term": "Framework", "desc": "Yazılımcıların işini kolaylaştıran, önceden hazırlanmış kod iskeleti (Örn: Flutter)."},
    {"term": "Scrum", "desc": "Yazılım ekiplerinin projeleri küçük parçalara bölerek hızlı yönetme taktiği."},
    {"term": "UI / UX", "desc": "Kullanıcı arayüzü tasarımı (UI) ve kullanım kolaylığı/deneyimi (UX)."},
    {"term": "Bug", "desc": "Yazılımdaki kod hatalarına verilen isim."},
    {"term": "Deploy", "desc": "Yazılan kodun canlı sunucuya (herkesin kullanımına) aktarılma işlemi."},
  ];

  // Yapay zekaya sorma fonksiyonu
  Future<void> _yapayZekayaSor() async {
    setState(() {
      _isAiLoading = true;
      _aiCevap = null;
    });

    // ai_service.dart içindeki beyni çalıştırıyoruz!
    final cevap = await AiService.terimiAcikla(aramaMetni);

    setState(() {
      _isAiLoading = false;
      _aiCevap = cevap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Yerel sözlükte arama yap
    final filtrelenmisSozluk = sozluk
        .where((item) => item["term"]!.toLowerCase().contains(aramaMetni.toLowerCase()))
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Text('Jargon Sözlüğü',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                onChanged: (value) {
                  setState(() {
                    aramaMetni = value;
                    _aiCevap = null; // Yeni arama yapılınca eski AI cevabını temizle
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Terim ara (Örn: API, Agile)...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: filtrelenmisSozluk.isNotEmpty
                    // EĞER KELİME BİZİM LİSTEDEYSE BUNU GÖSTER
                    ? ListView.builder(
                        controller: scrollCtrl,
                        itemCount: filtrelenmisSozluk.length,
                        itemBuilder: (context, index) {
                          final item = filtrelenmisSozluk[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item["term"]!,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(item["desc"]!,
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12, height: 1.3)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    // EĞER KELİME BİZİM LİSTEDE YOKSA YAPAY ZEKA DEVREYE GİRSİN
                    : aramaMetni.isNotEmpty
                        ? ListView(
                            controller: scrollCtrl,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  '"$aramaMetni" kelimesi sözlükte yok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ),
                              if (_isAiLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (_aiCevap != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Yapay Zeka Yanıtı',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(_aiCevap!,
                                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, height: 1.4)),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _yapayZekayaSor,
                                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                                  label: const Text('Yapay Zekaya Sor', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}