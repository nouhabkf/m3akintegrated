import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/location/current_position.dart';
import '../../../data/models/community_action_plan_result.dart';
import '../../../data/models/create_help_request_input.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../logic/help_request_voice_dictation_controller.dart';
import '../models/help_request_quick_preset.dart';
import '../services/post_detail_assistance/post_detail_assistance_models.dart';
import '../widgets/help_request_voice_dictation_section.dart';

/// Modes de saisie (alignés API `inputMode`).
enum _RequestInputMode {
  text,
  voice,
  tap,
  haptic,
  caregiver,
}

String _inputModeApi(_RequestInputMode m) {
  switch (m) {
    case _RequestInputMode.text:
      return 'text';
    case _RequestInputMode.voice:
      return 'voice';
    case _RequestInputMode.tap:
      return 'tap';
    case _RequestInputMode.haptic:
      return 'haptic';
    case _RequestInputMode.caregiver:
      return 'caregiver';
  }
}

/// Écran de création d’une demande d’aide (flux multi-entrées inclusif).
class CreateHelpRequestScreen extends ConsumerStatefulWidget {
  const CreateHelpRequestScreen({
    super.key,
    this.initialPrefill,
    this.initialAiPlan,
  });

  /// Préremplissage depuis un post communauté ([GoRouterState.extra]).
  final HelpRequestFromPostPrefill? initialPrefill;
  final CommunityActionPlanResult? initialAiPlan;

  @override
  ConsumerState<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends ConsumerState<CreateHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final HelpRequestVoiceDictationController _voiceDictation;
  late final VoidCallback _descriptionListener;
  bool _isLoading = false;
  bool _isAiLoading = false;
  bool _isAnalyzingAI = false;
  bool _aiRouteRedirectConsumed = false;

  _RequestInputMode _inputMode = _RequestInputMode.text;
  HelpRequestQuickPreset? _preset;

  bool _needAudio = false;
  bool _needVisual = false;
  bool _needPhysical = false;
  bool _needSimpleLang = false;

  double _latitude = 36.8065;
  double _longitude = 10.1815;

  @override
  void initState() {
    super.initState();
    _descriptionListener = () {
      if (mounted) setState(() {});
    };
    _descriptionController.addListener(_descriptionListener);
    _voiceDictation = HelpRequestVoiceDictationController(_descriptionController);

    final pre = widget.initialPrefill;
    if (pre != null) {
      _preset = pre.suggestedPreset;
      final m = HelpRequestQuickPresetMapping.forPreset(pre.suggestedPreset);
      _needAudio = pre.needsAudioGuidance ?? m.needsAudioGuidance;
      _needVisual = pre.needsVisualSupport ?? m.needsVisualSupport;
      _needPhysical = pre.needsPhysicalAssistance ?? m.needsPhysicalAssistance;
      _needSimpleLang = pre.needsSimpleLanguage ?? m.needsSimpleLanguage;
      if (pre.description.trim().isNotEmpty) {
        _descriptionController.text = pre.description.trim();
      }
      if (m.forceCaregiverInputMode) {
        _inputMode = _RequestInputMode.caregiver;
      }
    }
    final aiPlan = widget.initialAiPlan;
    if (aiPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _applyAiPlanToForm(aiPlan, preferCurrentLocation: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse intelligente appliquée')),
        );
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authStateProvider).valueOrNull;
      final ar = user?.preferredLanguage?.name.toLowerCase() == 'ar';
      unawaited(_voiceDictation.init(preferArabic: ar));
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_descriptionListener);
    _voiceDictation.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final pos = await getCurrentPositionOrNull();
    if (!mounted) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.locationUnavailable),
        ),
      );
      return;
    }
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.locationUpdated)),
    );
  }

  String _buildPreviewText(AppStrings strings) {
    final parts = <String>[];
    parts.add('${strings.helpCreateSectionHowTitle}: ${_modeLabel(strings, _inputMode)}');
    if (_preset != null) {
      parts.add(
        '${strings.helpCreateSectionWhatTitle}: ${_preset!.label(strings)}',
      );
    }
    final needs = <String>[];
    if (_needAudio) needs.add(strings.helpCreateNeedAudio);
    if (_needVisual) needs.add(strings.helpCreateNeedVisual);
    if (_needPhysical) needs.add(strings.helpCreateNeedPhysical);
    if (_needSimpleLang) needs.add(strings.helpCreateNeedSimpleLang);
    if (needs.isNotEmpty) {
      parts.add('${strings.helpCreateSectionNeedsTitle}: ${needs.join(', ')}');
    }
    final t = _descriptionController.text.trim();
    if (t.isNotEmpty) {
      parts.add('${strings.description}: $t');
    }
    parts.add(strings.helpCreatePreviewNote);
    return parts.join('\n\n');
  }

  void _stopVoiceIfListening() {
    if (_inputMode == _RequestInputMode.voice) {
      unawaited(_voiceDictation.stopIfListening());
    }
  }

  void _setInputMode(_RequestInputMode m) {
    if (_inputMode == _RequestInputMode.voice && m != _RequestInputMode.voice) {
      _stopVoiceIfListening();
    }
    setState(() => _inputMode = m);
  }

  void _applyPreset(HelpRequestQuickPreset p) {
    final m = HelpRequestQuickPresetMapping.forPreset(p);
    if (m.forceCaregiverInputMode) {
      _stopVoiceIfListening();
    }
    setState(() {
      _preset = p;
      _needAudio = m.needsAudioGuidance;
      _needVisual = m.needsVisualSupport;
      _needPhysical = m.needsPhysicalAssistance;
      _needSimpleLang = m.needsSimpleLanguage;
      if (m.forceCaregiverInputMode) {
        _inputMode = _RequestInputMode.caregiver;
      }
    });
  }

  Future<void> _applyPresetAndAnalyze(
    HelpRequestQuickPreset p,
    AppStrings strings,
  ) async {
    if (_isAiLoading || _isAnalyzingAI || _isLoading) return;

    final presetText = p.label(strings).trim();
    _descriptionController.text = presetText;
    _applyPreset(p);

    setState(() {
      _isAnalyzingAI = true;
      _isAiLoading = true;
      _aiRouteRedirectConsumed = false;
    });

    try {
      final presetMapping = HelpRequestQuickPresetMapping.forPreset(p);
      final plan = await ref
          .read(
            communityActionPlanProvider(
              (
                text: presetText,
                contextHint: 'help',
                inputModeHint: _inputModeApi(_inputMode),
                isForAnotherPersonHint:
                    (_inputMode == _RequestInputMode.caregiver) ||
                    presetMapping.isForAnotherPerson,
              ),
            ).future,
          );

      if (!mounted) return;
      if (plan.action != 'create_help_request') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’IA suggère plutôt un post. Vous pouvez continuer manuellement ici.',
            ),
          ),
        );
        return;
      }
      final nav = await _maybeNavigateToRecommendedRoute(plan, presetText);
      if (nav.navigatedAway) return;

      await _applyAiPlanToForm(plan);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nav.alreadyOnTarget
                ? 'Parcours IA : vous êtes déjà sur l’écran demande d’aide. Champs mis à jour.'
                : 'Suggestion analysée automatiquement',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Analyse intelligente indisponible, vous pouvez continuer manuellement',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingAI = false;
          _isAiLoading = false;
        });
      }
    }
  }

  HelpRequestQuickPreset? _presetFromMessageKey(String? key) {
    switch (key) {
      case 'blocked':
        return HelpRequestQuickPreset.blocked;
      case 'lost':
        return HelpRequestQuickPreset.lost;
      case 'cannot_reach':
        return HelpRequestQuickPreset.cannotFindEntrance;
      case 'medical_urgent':
        return HelpRequestQuickPreset.danger;
      case 'escort':
        return HelpRequestQuickPreset.forAnotherPerson;
      default:
        return null;
    }
  }

  _RequestInputMode _helpInputModeToUi(String? mode) {
    switch (mode) {
      case 'voice':
        return _RequestInputMode.voice;
      case 'tap':
        return _RequestInputMode.tap;
      case 'haptic':
        return _RequestInputMode.haptic;
      case 'caregiver':
        return _RequestInputMode.caregiver;
      case 'text':
      default:
        return _RequestInputMode.text;
    }
  }

  Future<void> _analyzeWithAi() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final text = _descriptionController.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez une description avant l’analyse IA.')),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiRouteRedirectConsumed = false;
    });
    try {
      final plan = await ref.read(communityRepositoryProvider).getCommunityActionPlan(
            text: text,
            contextHint: 'help',
            inputModeHint: _inputModeApi(_inputMode),
            isForAnotherPersonHint: _inputMode == _RequestInputMode.caregiver,
          );
      if (!mounted) return;
      if (plan.action != 'create_help_request') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’IA suggère plutôt un post. Vous pouvez continuer manuellement ici.',
            ),
          ),
        );
        return;
      }
      final nav = await _maybeNavigateToRecommendedRoute(plan, text);
      if (nav.navigatedAway) return;

      await _applyAiPlanToForm(plan);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nav.alreadyOnTarget
                ? 'Parcours IA : vous êtes déjà sur l’écran demande d’aide. Champs mis à jour.'
                : 'Le formulaire a été prérempli automatiquement.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.errorGeneric}. Analyse IA indisponible, vous pouvez continuer manuellement.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  String _modeLabel(AppStrings strings, _RequestInputMode m) {
    switch (m) {
      case _RequestInputMode.text:
        return strings.helpCreateModeText;
      case _RequestInputMode.voice:
        return strings.helpCreateModeVoice;
      case _RequestInputMode.tap:
        return strings.helpCreateModeTap;
      case _RequestInputMode.haptic:
        return strings.helpCreateModeHaptic;
      case _RequestInputMode.caregiver:
        return strings.helpCreateModeCaregiver;
    }
  }

  Future<void> _applyAiPlanToForm(
    CommunityActionPlanResult plan, {
    bool preferCurrentLocation = false,
  }) async {
    if (preferCurrentLocation) {
      final pos = await getCurrentPositionOrNull();
      if (mounted && pos != null) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      }
    }

    if (!mounted) return;
    final mapped = plan.toCreateHelpRequestInput(
      latitude: _latitude,
      longitude: _longitude,
    );
    setState(() {
      if ((mapped.description ?? '').trim().isNotEmpty) {
        _descriptionController.text = mapped.description!.trim();
      }
      _inputMode = _helpInputModeToUi(mapped.inputMode);
      _needAudio = mapped.needsAudioGuidance == true;
      _needVisual = mapped.needsVisualSupport == true;
      _needPhysical = mapped.needsPhysicalAssistance == true;
      _needSimpleLang = mapped.needsSimpleLanguage == true;
      final p = _presetFromMessageKey(mapped.presetMessageKey);
      if (p != null) {
        _preset = p;
      }
    });
  }

  Future<({bool navigatedAway, bool alreadyOnTarget})>
      _maybeNavigateToRecommendedRoute(
    CommunityActionPlanResult plan,
    String currentText,
  ) async {
    if (!mounted) {
      return (navigatedAway: false, alreadyOnTarget: false);
    }
    debugPrint(
      '[CommunityAI][help] action=${plan.action} route=${plan.recommendedRoute} '
      'reason=${plan.routeReason} confidence=${plan.confidence} '
      'path=${GoRouterState.of(context).uri.path}',
    );

    if (_aiRouteRedirectConsumed) {
      return (navigatedAway: false, alreadyOnTarget: false);
    }
    final route = plan.recommendedRoute?.trim();
    final currentPath = GoRouterState.of(context).uri.path;
    if (route == null || route.isEmpty) {
      return (navigatedAway: false, alreadyOnTarget: false);
    }

    final onSameScreen =
        communityActionRecommendedRouteMatchesLocation(route, currentPath);

    if (plan.shouldAutoNavigate(minConfidence: 0.85) && onSameScreen) {
      debugPrint(
        '[CommunityAI][help] recommended route matches current screen — no push',
      );
      return (navigatedAway: false, alreadyOnTarget: true);
    }

    if (plan.shouldAutoNavigate(minConfidence: 0.85) && !onSameScreen) {
      _aiRouteRedirectConsumed = true;
      final uri = Uri.parse(route);
      final merged = Map<String, String>.from(uri.queryParameters)
        ..putIfAbsent('aiAction', () => plan.action)
        ..putIfAbsent('aiSeed', () => currentText);
      await context.push(
        uri.replace(queryParameters: merged).toString(),
        extra: plan,
      );
      return (navigatedAway: true, alreadyOnTarget: false);
    }
    if (!onSameScreen && !plan.shouldAutoNavigate(minConfidence: 0.85)) {
      final reason = plan.routeReason?.trim();
      final msg = (reason != null && reason.isNotEmpty)
          ? 'Suggestion: $reason'
          : 'Suggestion de parcours disponible: $route';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
    return (navigatedAway: false, alreadyOnTarget: false);
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    if (_preset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.helpCreateSelectScenario)),
      );
      return;
    }

    final text = _descriptionController.text.trim();
    if (_inputMode == _RequestInputMode.text && text.isNotEmpty) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fr().errorGeneric)),
      );
      return;
    }

    final m = HelpRequestQuickPresetMapping.forPreset(_preset!);
    final caregiverUi = _inputMode == _RequestInputMode.caregiver;

    final input = CreateHelpRequestInput(
      description: text.isEmpty ? null : text,
      latitude: _latitude,
      longitude: _longitude,
      helpType: m.helpType,
      presetMessageKey: m.presetMessageKey,
      inputMode: _inputModeApi(_inputMode),
      requesterProfile: caregiverUi ? 'caregiver' : m.requesterProfile,
      needsAudioGuidance: _needAudio ? true : null,
      needsVisualSupport: _needVisual ? true : null,
      needsPhysicalAssistance: _needPhysical ? true : null,
      needsSimpleLanguage: _needSimpleLang ? true : null,
      isForAnotherPerson:
          caregiverUi || m.isForAnotherPerson ? true : null,
    );

    setState(() => _isLoading = true);

    try {
      await ref.read(createHelpRequestProvider(input).future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.helpRequestCreatedSuccess)),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.fr().errorGeneric}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.createHelpRequest)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.createHelpRequestDescription,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SectionHeader(text: 'Assistant intelligent'),
            const SizedBox(height: 8),
            Semantics(
              label: 'Assistant intelligent. Analyser avec IA',
              button: true,
              child: FilledButton.tonalIcon(
                onPressed: (_isLoading || _isAiLoading) ? null : _analyzeWithAi,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                icon: _isAiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Analyser avec IA'),
              ),
            ),
            const SizedBox(height: 20),

            // —— Section A ——
            _SectionHeader(text: strings.helpCreateSectionHowTitle),
            const SizedBox(height: 8),
            Semantics(
              label: strings.helpCreateSectionHowTitle,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InputModeChip(
                    selected: _inputMode == _RequestInputMode.text,
                    icon: Icons.text_fields_rounded,
                    label: strings.helpCreateModeText,
                    semantic: '${strings.helpCreateModeText}. Mode texte',
                    onSelected: () => _setInputMode(_RequestInputMode.text),
                  ),
                  _InputModeChip(
                    selected: _inputMode == _RequestInputMode.voice,
                    icon: Icons.mic_rounded,
                    label: strings.helpCreateModeVoice,
                    semantic: '${strings.helpCreateModeVoice}. Mode voix',
                    onSelected: () => _setInputMode(_RequestInputMode.voice),
                  ),
                  _InputModeChip(
                    selected: _inputMode == _RequestInputMode.tap,
                    icon: Icons.touch_app_rounded,
                    label: strings.helpCreateModeTap,
                    semantic: strings.helpCreateModeTap,
                    onSelected: () => _setInputMode(_RequestInputMode.tap),
                  ),
                  _InputModeChip(
                    selected: _inputMode == _RequestInputMode.haptic,
                    icon: Icons.vibration_rounded,
                    label: strings.helpCreateModeHaptic,
                    semantic: strings.helpCreateModeHaptic,
                    onSelected: () => _setInputMode(_RequestInputMode.haptic),
                  ),
                  _InputModeChip(
                    selected: _inputMode == _RequestInputMode.caregiver,
                    icon: Icons.family_restroom_rounded,
                    label: strings.helpCreateModeCaregiver,
                    semantic: strings.helpCreateModeCaregiver,
                    onSelected: () => _setInputMode(_RequestInputMode.caregiver),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_inputMode == _RequestInputMode.text ||
                _inputMode == _RequestInputMode.voice) ...[
              if (_inputMode == _RequestInputMode.voice) ...[
                HelpRequestVoiceDictationSection(
                  controller: _voiceDictation,
                  strings: strings,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: strings.description,
                  hintText: strings.helpRequestDescriptionHint,
                  border: const OutlineInputBorder(),
                  helperText: _inputMode == _RequestInputMode.voice
                      ? strings.helpCreateVoiceHint
                      : strings.describeYourNeed,
                ),
                validator: (v) {
                  if (_inputMode != _RequestInputMode.text) return null;
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  if (t.length < 10) return strings.minimumCharacters(10);
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),
            _SectionHeader(text: strings.helpCreateSectionWhatTitle),
            const SizedBox(height: 8),
            ...HelpRequestQuickPreset.values.map((p) {
              final selected = _preset == p;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: selected,
                  label: p.label(strings),
                  button: true,
                  child: Material(
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: (_isAnalyzingAI || _isAiLoading || _isLoading)
                          ? null
                          : () => _applyPresetAndAnalyze(p, strings),
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected ? Icons.check_circle : Icons.circle_outlined,
                                color: selected ? cs.primary : cs.onSurfaceVariant,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.label(strings),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: selected ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                              if (_isAnalyzingAI && selected)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            _SectionHeader(text: strings.helpCreateSectionNeedsTitle),
            const SizedBox(height: 8),
            _NeedTile(
              value: _needAudio,
              label: strings.helpCreateNeedAudio,
              semantic: strings.helpCreateNeedAudio,
              onChanged: (v) => setState(() => _needAudio = v),
            ),
            _NeedTile(
              value: _needVisual,
              label: strings.helpCreateNeedVisual,
              semantic: strings.helpCreateNeedVisual,
              onChanged: (v) => setState(() => _needVisual = v),
            ),
            _NeedTile(
              value: _needPhysical,
              label: strings.helpCreateNeedPhysical,
              semantic: strings.helpCreateNeedPhysical,
              onChanged: (v) => setState(() => _needPhysical = v),
            ),
            _NeedTile(
              value: _needSimpleLang,
              label: strings.helpCreateNeedSimpleLang,
              semantic: strings.helpCreateNeedSimpleLang,
              onChanged: (v) => setState(() => _needSimpleLang = v),
            ),

            const SizedBox(height: 24),
            _SectionHeader(text: strings.helpCreateSectionPreviewTitle),
            const SizedBox(height: 8),
            Semantics(
              label: _preset != null
                  ? '${strings.helpCreateSectionPreviewTitle}. ${strings.helpCreatePreviewMainMessageTitle}. ${_preset!.previewSentence(strings)}. ${_buildPreviewText(strings)}'
                  : '${strings.helpCreateSectionPreviewTitle}. ${_buildPreviewText(strings)}',
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_preset != null) ...[
                        Text(
                          strings.helpCreatePreviewMainMessageTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _preset!.previewSentence(strings),
                          style: theme.textTheme.titleMedium?.copyWith(
                            height: 1.35,
                          ),
                        ),
                        const Divider(height: 24),
                      ],
                      Text(
                        _buildPreviewText(strings),
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _SectionHeader(text: strings.location),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: Text(strings.useCurrentLocation),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.locationHelpMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Semantics(
              label: strings.submit,
              button: true,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.submit, style: theme.textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.helpRequestNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InputModeChip extends StatelessWidget {
  const _InputModeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.semantic,
    required this.onSelected,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String semantic;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semantic,
      button: true,
      selected: selected,
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({
    required this.value,
    required this.label,
    required this.semantic,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final String semantic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semantic,
      checked: value,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: CheckboxListTile(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            title: Text(label, style: Theme.of(context).textTheme.titleSmall),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }
}
