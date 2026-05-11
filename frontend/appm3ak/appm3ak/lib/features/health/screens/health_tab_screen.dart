import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/health_providers.dart';
import '../models/health_chat_launch.dart';
import '../services/health_ai_service.dart';
/// Onglet Santé : tableau de bord + entrée vers l’assistant IA (icône / carte humain‑assistant).
class HealthTabScreen extends ConsumerStatefulWidget {
  const HealthTabScreen({super.key, required this.strings, required this.user});

  final AppStrings strings;
  final UserModel user;

  @override
  ConsumerState<HealthTabScreen> createState() => _HealthTabScreenState();
}

class _HealthTabScreenState extends ConsumerState<HealthTabScreen> {
  final _glyCtrl = TextEditingController();
  final _ai = const HealthAiService();

  @override
  void dispose() {
    _glyCtrl.dispose();
    super.dispose();
  }

  void _openChat([String? initial]) {
    context.push(
      '/health-chat',
      extra: HealthChatLaunch(
        initialMessage: initial,
        user: widget.user,
      ),
    );
  }

  Future<void> _analyzeGlycemia() async {
    final raw = _glyCtrl.text.replaceAll(',', '.').trim();
    final v = double.tryParse(raw);
    final s = widget.strings;
    if (v == null || v <= 0 || v > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.healthGlycemiaInvalid)),
      );
      return;
    }
    final health = ref.read(healthDashboardProvider);
    final analysis = _ai.analyzeGlycemia(
      v,
      fastingAssumed: health.fastingForAnalysis,
    );
    await ref.read(healthDashboardProvider.notifier).addGlucose(v);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(s.healthGlycemiaTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  analysis.summaryFr,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(analysis.adviceFr),
                const Divider(height: 24),
                Text(
                  analysis.summaryEn,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(analysis.adviceEn),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.continueBtn),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMedication() async {
    final s = widget.strings;
    final nameCtrl = TextEditingController();
    var time = TimeOfDay.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(s.healthMedsAdd),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: s.healthMedName),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(s.healthMedTime),
                    subtitle: Text(time.format(context)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setLocal(() => time = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final n = nameCtrl.text.trim();
                    if (n.isEmpty) return;
                    ref
                        .read(healthDashboardProvider.notifier)
                        .addMedication(n, time);
                    Navigator.pop(ctx);
                  },
                  child: Text(s.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _minutesSinceMidnight(TimeOfDay t) => t.hour * 60 + t.minute;

  List<MedicationReminder> _sortedMeds(List<MedicationReminder> meds) {
    final now = TimeOfDay.now();
    final nowM = _minutesSinceMidnight(now);
    int medMinutes(MedicationReminder m) => m.hour * 60 + m.minute;
    final copy = [...meds]..sort((a, b) {
        final am = medMinutes(a);
        final bm = medMinutes(b);
        var da = am - nowM;
        var db = bm - nowM;
        if (da < 0) da += 24 * 60;
        if (db < 0) db += 24 * 60;
        return da.compareTo(db);
      });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;
    final health = ref.watch(healthDashboardProvider);

    final last = health.latestGlucose;
    final analysis = last != null
        ? _ai.analyzeGlycemia(
            last.mgDl,
            fastingAssumed: health.fastingForAnalysis,
          )
        : null;
    final glucoseOk = analysis != null &&
        (analysis.zoneKey == 'normal_fasting' ||
            analysis.zoneKey == 'normal_pp');

    final score = _ai.computeHealthScore(
      lastGlucoseMgDl: last?.mgDl,
      medicationCount: health.medications.length,
      glucoseInRangeIfKnown: last == null ? false : glucoseOk,
    );

    final orderedMeds = _sortedMeds(health.medications);

    final fabBottom =
        MediaQuery.paddingOf(context).bottom + 72;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Bandeau fixe très visible : ouvre le chat IA (évite tout problème de FAB masqué).
            SliverToBoxAdapter(
              child: Material(
                color: theme.colorScheme.primary,
                child: InkWell(
                  onTap: () => _openChat(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 36,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.healthAssistantTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.healthFabChat,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary
                                      .withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.health,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.user.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: s.healthOpenChat,
                      iconSize: 32,
                      onPressed: () => _openChat(),
                      icon: Icon(
                        Icons.volunteer_activism,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Carte « humain + IA » — point d’entrée principal du chatbot
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openChat(),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.accessibility_new,
                                  size: 36,
                                  color: theme.colorScheme.onPrimary,
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.smart_toy,
                                      size: 18,
                                      color: theme.colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.healthAssistantTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.healthAssistantSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => _openChat(),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: Text(s.healthOpenChat),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  s.healthDisclaimerShort,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Score santé
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 8,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              Text(
                                '$score',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.healthScoreTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.healthScoreHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Glycémie
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          s.healthGlycemiaTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _glyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: s.healthGlycemiaValueLabel,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.healthGlycemiaFasting),
                          value: health.fastingForAnalysis,
                          onChanged: (v) {
                            ref
                                .read(healthDashboardProvider.notifier)
                                .setFasting(v);
                          },
                        ),
                        FilledButton.icon(
                          onPressed: _analyzeGlycemia,
                          icon: const Icon(Icons.analytics_outlined),
                          label: Text(s.healthGlycemiaAnalyze),
                        ),
                        if (last != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${s.healthGlycemiaValueLabel}: ${last.mgDl.toStringAsFixed(0)} (${analysis?.zoneKey ?? ''})',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Rappels médicaments (tri « intelligent » par prochaine échéance)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.healthMedsTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addMedication,
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: s.healthMedsAdd,
                        ),
                      ],
                    ),
                    Text(
                      s.healthNextReminders,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (health.medications.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        s.healthMedsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: orderedMeds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = orderedMeds[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${i + 1}'),
                        ),
                        title: Text(m.name),
                        subtitle: Text(m.timeOfDay.format(context)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            ref
                                .read(healthDashboardProvider.notifier)
                                .removeMedication(m.id);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // SOS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.healthSosTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(s.healthSosBody),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          onPressed: () => _openChat('SOS urgence'),
                          icon: const Icon(Icons.support_agent),
                          label: Text(s.healthSosButton),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: fabBottom,
          child: FloatingActionButton.extended(
            heroTag: 'health_tab_ai_fab',
            icon: const Icon(Icons.record_voice_over_rounded, size: 26),
            label: Text(
              s.healthFabChat,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            tooltip: s.healthOpenChat,
            onPressed: () => _openChat(),
          ),
        ),
      ],
    );
  }
}
