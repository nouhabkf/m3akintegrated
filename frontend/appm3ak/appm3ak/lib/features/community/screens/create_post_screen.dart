import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/location/current_position.dart';
import '../../../core/volume/android_volume_hub.dart';
import '../../../data/models/community_action_plan_result.dart';
import '../../../data/models/create_post_input.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../../accessibility/accessibility_post_handoff.dart';
import '../../accessibility/accessibility_post_prefs.dart';
import '../logic/information_head_gesture_intent.dart';
import '../logic/post_create_legacy_type.dart';
import '../logic/post_create_preset_config.dart';

/// Écran de création d'un post (flux inclusif : qui publie, mode, nature, public, besoins, contenu, médias, lieu, aperçu).
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({
    super.key,
    this.initialContent,
    this.autoOpenCamera = false,
    this.autoPublishAfterCamera = false,
    this.accessibilityAnnounceGalleryVolumeOrCameraFallback = false,
    this.prefilledImages,
    this.initialPostType,
    this.initialAccessibilityHandoff,
    this.initialAiPlan,
    this.contentHintOverride,
  });

  final String? initialContent;
  final bool autoOpenCamera;
  final bool autoPublishAfterCamera;

  /// Android : synthèse vocale « galerie », Volume+ = galerie ; sinon délai → caméra.
  final bool accessibilityAnnounceGalleryVolumeOrCameraFallback;
  final List<XFile>? prefilledImages;
  final PostType? initialPostType;
  final AccessibilityPostHandoff? initialAccessibilityHandoff;
  final CommunityActionPlanResult? initialAiPlan;

  /// Surcharge du hint du champ « contenu » (ex. lien depuis Lieux → Contribuer).
  final String? contentHintOverride;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contenuController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _forSelf = true;
  String _inputMode = 'keyboard';
  String _postNature = 'information';
  String _targetAudience = 'all';

  bool _needAudio = false;
  bool _needVisual = false;
  bool _needPhysical = false;
  bool _needSimpleLang = false;

  PostCreatePresetId? _selectedPresetId;

  /// `none` | `approximate` | `precise`
  String _locationMode = 'none';

  bool _isLoading = false;
  bool _isAiLoading = false;
  bool _isAnalyzingAI = false;
  bool _aiRouteRedirectConsumed = false;
  bool _redirectToPostsAfterSubmit = false;
  final List<XFile> _images = [];
  bool _loadingLocation = false;
  double? _latitude;
  double? _longitude;

  static const int _maxImages = 10;
  Future<bool> Function()? _previousVolumeUpPriority;

  /// Accessibilité : choix galerie (Volume+) ou caméra (délai).
  bool _accessibilityImageChoiceActive = false;
  Timer? _cameraFallbackTimer;
  final FlutterTts _accessibilityTts = FlutterTts();

  static const List<String> _natureKeys = [
    'signalement',
    'conseil',
    'temoignage',
    'information',
    'alerte',
  ];

  static const List<String> _audienceKeys = [
    'all',
    'motor',
    'visual',
    'hearing',
    'cognitive',
    'caregiver',
  ];

  static const List<String> _inputModeKeys = [
    'keyboard',
    'voice',
    'headEyes',
    'vibration',
    'deafBlind',
    'caregiver',
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      AndroidVolumeHub.ensureInitialized();
      _previousVolumeUpPriority = AndroidVolumeHub.onVolumeUpPriority;
      AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpPublish;
    }
    final seed = widget.initialContent?.trim();
    if (seed != null && seed.isNotEmpty) {
      _contenuController.text = seed;
    }
    if (widget.initialPostType != null) {
      _applyPostType(widget.initialPostType!);
    }
    if (widget.initialAiPlan != null) {
      _applyAiPlanToForm(widget.initialAiPlan!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse intelligente appliquée')),
        );
      });
    }
    final pre = widget.prefilledImages;
    if (pre != null && pre.isNotEmpty) {
      for (final x in pre) {
        if (_images.length >= _maxImages) break;
        _images.add(x);
      }
    }

    if (widget.accessibilityAnnounceGalleryVolumeOrCameraFallback && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Platform.isAndroid) {
          unawaited(_startAccessibilityGalleryVolumeOrCamera());
        } else {
          unawaited(_accessibilitySpeakThenOpenCameraOnly());
        }
      });
    } else if (widget.autoOpenCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pickFromCamera();
        if (!mounted) return;
        if (widget.autoPublishAfterCamera && _images.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (!mounted) return;
          await _submitPost();
        }
      });
    }

    final handoff = widget.initialAccessibilityHandoff;
    if (handoff != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _applyAccessibilityHandoff(handoff);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || kIsWeb) return;
        final uri = GoRouterState.of(context).uri;
        final queryHead = uri.queryParameters['head'] == '1';
        final queryVoiceVib = uri.queryParameters['voiceVib'] == '1';
        final shortcut = await AccessibilityPostPrefs.getPostCreationShortcut();
        if (!mounted) return;
        if (queryHead) {
          await context.push('/create-post-head-gesture');
          return;
        }
        if (queryVoiceVib) {
          await context.push('/create-post-voice-vibration');
          return;
        }
        if (shortcut == PostCreationShortcut.headGesture) {
          await context.push('/create-post-head-gesture');
          return;
        }
        if (shortcut == PostCreationShortcut.voiceVibration) {
          await context.push('/create-post-voice-vibration');
          return;
        }
      });
    }
  }

  void _applyPostType(PostType t) {
    switch (t) {
      case PostType.conseil:
        _postNature = 'conseil';
        break;
      case PostType.temoignage:
        _postNature = 'temoignage';
        break;
      case PostType.handicapMoteur:
        _postNature = 'information';
        _targetAudience = 'motor';
        break;
      case PostType.handicapVisuel:
        _postNature = 'information';
        _targetAudience = 'visual';
        break;
      case PostType.handicapAuditif:
        _postNature = 'information';
        _targetAudience = 'hearing';
        break;
      case PostType.handicapCognitif:
        _postNature = 'information';
        _targetAudience = 'cognitive';
        break;
      case PostType.general:
      case PostType.autre:
        _postNature = 'information';
        _targetAudience = 'all';
        break;
    }
  }

  @override
  void dispose() {
    _resetAccessibilityImageChoiceTimer();
    unawaited(_accessibilityTts.stop());
    if (!kIsWeb && Platform.isAndroid) {
      final p = AndroidVolumeHub.onVolumeUpPriority;
      if (identical(p, _onVolumeUpPublish) ||
          identical(p, _onVolumeUpOpenGalleryShortcut)) {
        AndroidVolumeHub.onVolumeUpPriority = _previousVolumeUpPriority;
      }
    }
    _contenuController.dispose();
    super.dispose();
  }

  Future<bool> _onVolumeUpPublish() async {
    if (!mounted) return false;
    await _submitPost();
    return true;
  }

  /// Pendant le choix image accessibilité : Volume+ ouvre la galerie.
  Future<bool> _onVolumeUpOpenGalleryShortcut() async {
    if (!mounted || !_accessibilityImageChoiceActive) return false;
    _resetAccessibilityImageChoiceTimer();
    _accessibilityImageChoiceActive = false;
    if (!kIsWeb && Platform.isAndroid) {
      AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpPublish;
    }
    await _pickFromGallery();
    return true;
  }

  void _resetAccessibilityImageChoiceTimer() {
    _cameraFallbackTimer?.cancel();
    _cameraFallbackTimer = null;
  }

  Future<void> _startAccessibilityGalleryVolumeOrCamera() async {
    if (!mounted) return;
    _accessibilityImageChoiceActive = true;
    AndroidVolumeHub.ensureInitialized();
    AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpOpenGalleryShortcut;

    final user = ref.read(authStateProvider).valueOrNull;
    final lang = user?.preferredLanguage?.name.toLowerCase() ?? '';
    final ttsLang = lang == 'ar' ? 'ar-SA' : 'fr-FR';
    try {
      await _accessibilityTts.setLanguage(ttsLang);
      await _accessibilityTts.setSpeechRate(0.45);
      await _accessibilityTts.speak(
        lang == 'ar'
            ? 'المعرض. اضغط على زر رفع الصوت لفتح المعرض. في غياب ذلك، تُفتح الكاميرا.'
            : 'Galerie. Appuyez sur volume plus pour ouvrir la galerie. '
                'Sans action, l’appareil photo s’ouvrira.',
      );
    } catch (_) {}

    _cameraFallbackTimer = Timer(const Duration(seconds: 12), () async {
      if (!mounted || !_accessibilityImageChoiceActive) return;
      _resetAccessibilityImageChoiceTimer();
      _accessibilityImageChoiceActive = false;
      if (!kIsWeb && Platform.isAndroid) {
        AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpPublish;
      }
      await _pickFromCamera();
    });
  }

  /// iOS / desktop : pas de Volume+ global — annonce puis caméra après délai.
  Future<void> _accessibilitySpeakThenOpenCameraOnly() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final lang = user?.preferredLanguage?.name.toLowerCase() ?? '';
    final ttsLang = lang == 'ar' ? 'ar-SA' : 'fr-FR';
    try {
      await _accessibilityTts.setLanguage(ttsLang);
      await _accessibilityTts.setSpeechRate(0.45);
      await _accessibilityTts.speak(
        lang == 'ar'
            ? 'استخدم الأزرار لاختيار المعرض أو الكاميرا.'
            : 'Utilisez les boutons Galerie ou Appareil photo. '
                'La caméra s’ouvre dans quelques secondes si besoin.',
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 12));
    if (!mounted) return;
    await _pickFromCamera();
  }

  double? _roundApprox(double? v) {
    if (v == null) return null;
    return (v * 1000).round() / 1000;
  }

  String _legacyTypeApi() {
    return legacyPostTypeFromInclusive(
      postNature: _postNature,
      targetAudience: _targetAudience,
    );
  }

  String? _dangerLevel() {
    if (_postNature != 'alerte') return null;
    if (_locationMode != 'none' && _latitude != null && _longitude != null) {
      return 'critical';
    }
    return 'medium';
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fr().errorGeneric)),
      );
      return;
    }

    var locMode = kIsWeb ? 'none' : _locationMode;
    final missingCoords = _latitude == null || _longitude == null;
    if (locMode != 'none' && missingCoords) {
      // En flux accessibilité (voix/vibrations + photo), on ne bloque pas la
      // publication si le GPS échoue : on publie sans position.
      locMode = 'none';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position indisponible, publication envoyée sans localisation.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() => _isLoading = true);

    try {
      double? lat;
      double? lng;
      if (locMode != 'none' && _latitude != null && _longitude != null) {
        lat = locMode == 'approximate' ? _roundApprox(_latitude) : _latitude;
        lng = locMode == 'approximate' ? _roundApprox(_longitude) : _longitude;
      }

      final input = CreatePostInput(
        contenu: _contenuController.text.trim(),
        type: _legacyTypeApi(),
        images: _images.isEmpty ? null : List<XFile>.from(_images),
        latitude: lat,
        longitude: lng,
        dangerLevel: _dangerLevel(),
        postNature: _postNature,
        targetAudience: _targetAudience,
        inputMode: _inputMode,
        isForAnotherPerson: _forSelf ? false : true,
        needsAudioGuidance: _needAudio ? true : null,
        needsVisualSupport: _needVisual ? true : null,
        needsPhysicalAssistance: _needPhysical ? true : null,
        needsSimpleLanguage: _needSimpleLang ? true : null,
        locationSharingMode: locMode,
      );

      await ref.read(createPostProvider(input).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
                .postCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        if (_redirectToPostsAfterSubmit) {
          context.go('/community-posts?owner=mine');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.fr().errorGeneric}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeWithAi() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final text = _contenuController.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez un texte avant l’analyse IA.')),
      );
      return;
    }

    if (isInformationAccessibleInfoHeadGesturePhrase(text)) {
      await context.push('/create-post-head-gesture');
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiRouteRedirectConsumed = false;
    });
    try {
      final plan = await ref.read(communityRepositoryProvider).getCommunityActionPlan(
            text: text,
            contextHint: 'post',
            inputModeHint: _inputMode,
            isForAnotherPersonHint: !_forSelf,
          );

      if (!mounted) return;
      if (plan.action != 'create_post') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’IA suggère plutôt une demande d’aide. Vous pouvez continuer manuellement ici.',
            ),
          ),
        );
        return;
      }
      final nav = await _maybeNavigateToRecommendedRoute(plan, text);
      if (nav.navigatedAway) return;

      _applyAiPlanToForm(plan);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nav.alreadyOnTarget
                ? 'Parcours IA : vous êtes déjà sur l’écran publication. Champs mis à jour.'
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

  Future<void> _attachCurrentLocation() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    if (kIsWeb) return;
    setState(() => _loadingLocation = true);
    try {
      final pos = await getCurrentPositionForPostOrNull();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.locationUnavailable)),
        );
        return;
      }
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.locationAttached)),
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  /// Une photo prise sur place doit envoyer les coordonnées GPS actuelles en **précis**
  /// (pas une position antérieure ni le mode approximatif de l’IA).
  Future<void> _ensurePreciseGpsAfterPhotoCapture() async {
    if (kIsWeb) return;
    setState(() => _locationMode = 'precise');
    await _attachCurrentLocation();
  }

  Future<void> _pickFromGallery() async {
    var list = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (kIsWeb && list.isEmpty) {
      final one = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (one != null) list = [one];
    }
    if (!mounted || list.isEmpty) return;
    setState(() {
      for (final x in list) {
        if (_images.length >= _maxImages) break;
        _images.add(x);
      }
    });
  }

  Future<void> _pickFromCamera() async {
    final x = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || x == null) return;
    setState(() {
      if (_images.length < _maxImages) _images.add(x);
    });
    await _ensurePreciseGpsAfterPhotoCapture();
  }

  Future<void> _applyAccessibilityHandoff(AccessibilityPostHandoff? handoff) async {
    if (!mounted || handoff == null) return;
    final shouldPublish = handoff.autoPublish;
    setState(() {
      _redirectToPostsAfterSubmit = shouldPublish;
      if (handoff.content.trim().isNotEmpty) {
        _contenuController.text = handoff.content.trim();
      }
      if (handoff.suggestedPostType != null) {
        _applyPostType(handoff.suggestedPostType!);
      }
      for (final x in handoff.images) {
        if (_images.length >= _maxImages) break;
        _images.add(x);
      }
      final mode = handoff.locationSharingMode?.trim();
      if (handoff.latitude != null && handoff.longitude != null) {
        _latitude = handoff.latitude;
        _longitude = handoff.longitude;
        if (mode == 'approximate' || mode == 'precise') {
          _locationMode = mode!;
        } else {
          _locationMode = 'precise';
        }
      }
    });
    if (!kIsWeb &&
        handoff.images.isNotEmpty &&
        !(handoff.latitude != null && handoff.longitude != null)) {
      await _ensurePreciseGpsAfterPhotoCapture();
    }
    if (shouldPublish) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        await _submitPost();
      });
    }
  }

  Future<void> _openHeadGesturePost() async {
    final handoff =
        await context.push<AccessibilityPostHandoff?>('/create-post-head-gesture?returnHandoff=1');
    await _applyAccessibilityHandoff(handoff);
  }

  Future<void> _openVoiceVibrationPost() async {
    final handoff = await context
        .push<AccessibilityPostHandoff?>('/create-post-voice-vibration?returnHandoff=1');
    await _applyAccessibilityHandoff(handoff);
  }

  String _presetChipShort(AppStrings s, PostCreatePresetId id) {
    switch (id) {
      case PostCreatePresetId.blocked:
        return s.postCreatePresetChipBlocked;
      case PostCreatePresetId.difficultAccess:
        return s.postCreatePresetChipDifficultAccess;
      case PostCreatePresetId.inaccessibleEntrance:
        return s.postCreatePresetChipInaccessibleEntrance;
      case PostCreatePresetId.missingRamp:
        return s.postCreatePresetChipMissingRamp;
      case PostCreatePresetId.stairsWithoutHelp:
        return s.postCreatePresetChipStairsNoHelp;
      case PostCreatePresetId.needOrientation:
        return s.postCreatePresetChipNeedOrientation;
      case PostCreatePresetId.usefulAdvice:
        return s.postCreatePresetChipUsefulAdvice;
      case PostCreatePresetId.personalTestimony:
        return s.postCreatePresetChipPersonalTestimony;
    }
  }

  String _presetBodyTemplate(AppStrings s, PostCreatePresetId id) {
    switch (id) {
      case PostCreatePresetId.blocked:
        return s.postCreatePresetBodyBlocked;
      case PostCreatePresetId.difficultAccess:
        return s.postCreatePresetBodyDifficultAccess;
      case PostCreatePresetId.inaccessibleEntrance:
        return s.postCreatePresetBodyInaccessibleEntrance;
      case PostCreatePresetId.missingRamp:
        return s.postCreatePresetBodyMissingRamp;
      case PostCreatePresetId.stairsWithoutHelp:
        return s.postCreatePresetBodyStairsNoHelp;
      case PostCreatePresetId.needOrientation:
        return s.postCreatePresetBodyNeedOrientation;
      case PostCreatePresetId.usefulAdvice:
        return s.postCreatePresetBodyUsefulAdvice;
      case PostCreatePresetId.personalTestimony:
        return s.postCreatePresetBodyPersonalTestimony;
    }
  }

  void _applyPreset(PostCreatePresetMapping m) {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final base = _presetBodyTemplate(strings, m.id);
    final text = _forSelf
        ? base
        : '${strings.postCreateCaregiverPostIntro}\n\n$base';
    setState(() {
      _postNature = m.postNature;
      _targetAudience = m.targetAudience;
      _needAudio = m.needsAudio;
      _needVisual = m.needsVisual;
      _needPhysical = m.needsPhysical;
      _needSimpleLang = m.needsSimpleLanguage;
      _selectedPresetId = m.id;
      _contenuController.text = text;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.postCreatePresetAppliedSnack)),
    );
  }

  Future<void> _applyPresetAndAnalyze(
    PostCreatePresetMapping m,
    AppStrings strings,
  ) async {
    if (_isLoading || _isAiLoading || _isAnalyzingAI) return;

    _applyPreset(m);
    final text = _contenuController.text.trim();
    if (text.length < 2) return;

    if (isInformationAccessibleInfoHeadGesturePhrase(text)) {
      await context.push('/create-post-head-gesture');
      return;
    }

    setState(() {
      _isAnalyzingAI = true;
      _isAiLoading = true;
      _aiRouteRedirectConsumed = false;
    });
    try {
      final plan = await ref
          .read(
            communityActionPlanProvider(
              (
                text: text,
                contextHint: 'post',
                inputModeHint: _inputMode,
                isForAnotherPersonHint: !_forSelf,
              ),
            ).future,
          );

      if (!mounted) return;
      if (plan.action != 'create_post') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’IA suggère plutôt une demande d’aide. Vous pouvez continuer manuellement ici.',
            ),
          ),
        );
        return;
      }
      final nav = await _maybeNavigateToRecommendedRoute(plan, text);
      if (nav.navigatedAway) return;

      _applyAiPlanToForm(plan, keepPreset: m.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nav.alreadyOnTarget
                ? 'Parcours IA : vous êtes déjà sur l’écran publication. Champs mis à jour.'
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

  String _previewText(AppStrings s) {
    final parts = <String>[];
    parts.add(
      '${s.postCreateSectionPublisher}: ${_forSelf ? s.postCreateSwitchForSelf : s.postCreateSwitchForOther}',
    );
    if (!_forSelf) {
      parts.add(s.postCreatePreviewCaregiverNote);
    }
    parts.add('${s.postCreateSectionInputMode}: ${_inputModeLabel(s, _inputMode)}');
    parts.add('${s.postCreateSectionNature}: ${_natureLabel(s, _postNature)}');
    parts.add('${s.postCreateSectionAudience}: ${_audienceLabel(s, _targetAudience)}');
    final needs = <String>[];
    if (_needAudio) needs.add(s.helpCreateNeedAudio);
    if (_needVisual) needs.add(s.helpCreateNeedVisual);
    if (_needPhysical) needs.add(s.helpCreateNeedPhysical);
    if (_needSimpleLang) needs.add(s.helpCreateNeedSimpleLang);
    if (needs.isNotEmpty) {
      parts.add('${s.postCreateSectionNeeds}: ${needs.join(', ')}');
    }
    parts.add(_contenuController.text.trim());
    if (_images.isNotEmpty) parts.add('${s.postCreateSectionImages}: ${_images.length}');
    parts.add(
      '${s.postCreateSectionLocation}: ${_locationLabel(s)}',
    );
    return parts.join('\n\n');
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
      '[CommunityAI][post] action=${plan.action} route=${plan.recommendedRoute} '
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
        '[CommunityAI][post] recommended route matches current screen — no push',
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

  void _applyAiPlanToForm(
    CommunityActionPlanResult plan, {
    PostCreatePresetId? keepPreset,
  }) {
    final mapped = plan.toCreatePostInput();
    var needsGpsRefreshAfterAi = false;
    setState(() {
      if ((mapped.contenu).trim().isNotEmpty) {
        _contenuController.text = mapped.contenu.trim();
      }
      if (mapped.postNature != null && _natureKeys.contains(mapped.postNature)) {
        _postNature = mapped.postNature!;
      }
      if (mapped.targetAudience != null &&
          _audienceKeys.contains(mapped.targetAudience)) {
        _targetAudience = mapped.targetAudience!;
      }
      if (mapped.inputMode != null && _inputModeKeys.contains(mapped.inputMode)) {
        _inputMode = mapped.inputMode!;
      }
      _forSelf = !(mapped.isForAnotherPerson ?? false);
      _needAudio = mapped.needsAudioGuidance == true;
      _needVisual = mapped.needsVisualSupport == true;
      _needPhysical = mapped.needsPhysicalAssistance == true;
      _needSimpleLang = mapped.needsSimpleLanguage == true;
      if (mapped.locationSharingMode != null) {
        final loc = mapped.locationSharingMode!;
        if (loc == 'none' || loc == 'approximate' || loc == 'precise') {
          _locationMode = loc;
        }
      }
      // Avec une photo : une position sur le terrain attend des coordonnées précises.
      if (_images.isNotEmpty &&
          (_locationMode == 'approximate' || _locationMode == 'precise')) {
        _locationMode = 'precise';
        needsGpsRefreshAfterAi = true;
      }
      _selectedPresetId = keepPreset;
    });
    if (!kIsWeb && needsGpsRefreshAfterAi) {
      unawaited(_attachCurrentLocation());
    }
  }

  String _locationLabel(AppStrings s) {
    if (kIsWeb) return s.postCreateLocationNone;
    switch (_locationMode) {
      case 'approximate':
        return s.postCreateLocationApproximate;
      case 'precise':
        return s.postCreateLocationPrecise;
      default:
        return s.postCreateLocationNone;
    }
  }

  String _natureLabel(AppStrings s, String key) {
    switch (key) {
      case 'signalement':
        return s.postCreateNatureSignalement;
      case 'conseil':
        return s.postCreateNatureConseil;
      case 'temoignage':
        return s.postCreateNatureTemoignage;
      case 'information':
        return s.postCreateNatureInformation;
      case 'alerte':
        return s.postCreateNatureAlerte;
      default:
        return key;
    }
  }

  String _audienceLabel(AppStrings s, String key) {
    switch (key) {
      case 'all':
        return s.postCreateAudienceAll;
      case 'motor':
        return s.postCreateAudienceMotor;
      case 'visual':
        return s.postCreateAudienceVisual;
      case 'hearing':
        return s.postCreateAudienceHearing;
      case 'cognitive':
        return s.postCreateAudienceCognitive;
      case 'caregiver':
        return s.postCreateAudienceCaregiver;
      default:
        return key;
    }
  }

  String _inputModeLabel(AppStrings s, String key) {
    switch (key) {
      case 'keyboard':
        return s.postCreateInputKeyboard;
      case 'voice':
        return s.postCreateInputVoice;
      case 'headEyes':
        return s.postCreateInputHeadEyes;
      case 'vibration':
        return s.postCreateInputVibration;
      case 'deafBlind':
        return s.postCreateInputDeafBlind;
      case 'caregiver':
        return s.postCreateInputCaregiver;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    void safePopCreate() {
      if (!mounted) return;
      try {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/home');
      } catch (_) {
        if (mounted) {
          try {
            context.go('/home');
          } catch (_) {}
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: safePopCreate),
        title: Text(strings.createPost),
        actions: [
          IconButton(
            tooltip: strings.addImages,
            onPressed: _isLoading ? null : _pickFromGallery,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          if (!kIsWeb)
            IconButton(
              tooltip: strings.fromCamera,
              onPressed: _isLoading ? null : _pickFromCamera,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.createPostDescription,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: 'Assistant intelligent'),
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
            _SectionTitle(text: strings.postCreateSectionPublisher),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label:
                  '${strings.postCreateSectionPublisher}. ${_forSelf ? strings.postCreateSwitchForSelf : strings.postCreateSwitchForOther}',
              hint: strings.postCreateSemanticSwitchHint,
              child: Material(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  value: !_forSelf,
                  onChanged: _isLoading
                      ? null
                      : (forOther) {
                          setState(() {
                            _forSelf = !forOther;
                            if (!_forSelf && _inputMode == 'keyboard') {
                              _inputMode = 'caregiver';
                            }
                            if (_forSelf && _inputMode == 'caregiver') {
                              _inputMode = 'keyboard';
                            }
                          });
                        },
                  secondary: Icon(
                    _forSelf ? Icons.person_outline : Icons.family_restroom,
                    size: 28,
                    semanticLabel: _forSelf
                        ? strings.postCreateSwitchForSelf
                        : strings.postCreateSwitchForOther,
                  ),
                  title: Text(
                    _forSelf
                        ? strings.postCreateSwitchForSelf
                        : strings.postCreateSwitchForOther,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.postCreatePublisherSwitchTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _forSelf
                              ? strings.postCreatePublisherSubtitleSelf
                              : strings.postCreatePublisherSubtitleOther,
                        ),
                      ],
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionInputMode),
            const SizedBox(height: 8),
            _InclusiveRow(
              selectedKey: _inputMode,
              options: _inputModeKeys
                  .map(
                    (k) => (
                      key: k,
                      label: _inputModeLabel(strings, k),
                      icon: _inputModeIcon(k),
                      semantic: _inputModeLabel(strings, k),
                    ),
                  )
                  .toList(),
              onSelect: (k) => setState(() => _inputMode = k),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 8),
              Text(
                strings.postCreateShortcutsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _openHeadGesturePost,
                    icon: const Icon(Icons.face_retouching_natural),
                    label: Text(strings.postCreateInputHeadEyes),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _openVoiceVibrationPost,
                    icon: const Icon(Icons.record_voice_over),
                    label: Text(strings.postCreateInputVoice),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => context.push('/create-post-vibration'),
                    icon: const Icon(Icons.vibration),
                    label: Text(strings.postShortcutSourdAveugleTitle),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionNature),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _natureKeys.map((k) {
                final sel = _postNature == k;
                return Semantics(
                  selected: sel,
                  label: _natureLabel(strings, k),
                  button: true,
                  child: FilterChip(
                    label: Text(_natureLabel(strings, k)),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() {
                          _postNature = k;
                          _selectedPresetId = null;
                        }),
                    showCheckmark: true,
                    selectedColor: cs.primaryContainer,
                    side: BorderSide(
                      color: sel ? cs.primary : cs.outline,
                      width: sel ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionAudience),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _audienceKeys.map((k) {
                final sel = _targetAudience == k;
                return Semantics(
                  selected: sel,
                  label: _audienceLabel(strings, k),
                  button: true,
                  child: FilterChip(
                    label: Text(_audienceLabel(strings, k)),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() {
                          _targetAudience = k;
                          _selectedPresetId = null;
                        }),
                    showCheckmark: true,
                    selectedColor: cs.primaryContainer,
                    side: BorderSide(
                      color: sel ? cs.primary : cs.outline,
                      width: sel ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionNeeds),
            const SizedBox(height: 4),
            Text(
              strings.postCreateSectionNeedsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _NeedTile(
              value: _needAudio,
              label: strings.helpCreateNeedAudio,
              hint: strings.postCreateNeedAudioHint,
              onChanged: (v) => setState(() => _needAudio = v),
            ),
            _NeedTile(
              value: _needVisual,
              label: strings.helpCreateNeedVisual,
              hint: strings.postCreateNeedVisualHint,
              onChanged: (v) => setState(() => _needVisual = v),
            ),
            _NeedTile(
              value: _needPhysical,
              label: strings.helpCreateNeedPhysical,
              hint: strings.postCreateNeedPhysicalHint,
              onChanged: (v) => setState(() => _needPhysical = v),
            ),
            _NeedTile(
              value: _needSimpleLang,
              label: strings.helpCreateNeedSimpleLang,
              hint: strings.postCreateNeedSimpleLangHint,
              onChanged: (v) => setState(() => _needSimpleLang = v),
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionContent),
            const SizedBox(height: 8),
            Text(
              strings.postCreatePresetSuggestions,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              strings.postCreatePresetTapHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in PostCreatePresetMapping.ordered)
                  Semantics(
                    button: true,
                    label:
                        '${strings.postCreatePresetSuggestions}. ${_presetChipShort(strings, m.id)}',
                    child: FilterChip(
                      showCheckmark: true,
                      label: Text(_presetChipShort(strings, m.id)),
                      selected: _selectedPresetId == m.id,
                      avatar: (_isAnalyzingAI && _selectedPresetId == m.id)
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onSelected: (_isLoading || _isAiLoading || _isAnalyzingAI)
                          ? null
                          : (selected) {
                              if (selected) {
                                unawaited(_applyPresetAndAnalyze(m, strings));
                              }
                            },
                      selectedColor: cs.primaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      side: BorderSide(
                        color: _selectedPresetId == m.id
                            ? cs.primary
                            : cs.outline,
                        width: _selectedPresetId == m.id ? 2 : 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contenuController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.content,
                hintText: (widget.contentHintOverride?.trim().isNotEmpty ?? false)
                    ? widget.contentHintOverride!.trim()
                    : (_forSelf
                        ? strings.postContentHint
                        : strings.postCreateContentHintCaregiver),
                border: const OutlineInputBorder(),
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.fieldRequired;
                }
                if (value.trim().length < 10) {
                  return strings.minimumCharacters(10);
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.postCreateSectionImages),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(strings.fromGallery),
                ),
                if (!kIsWeb)
                  FilledButton.tonalIcon(
                    onPressed: _isLoading ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(strings.fromCamera),
                  ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder(
                            future: _images[index].readAsBytes(),
                            builder: (context, snap) {
                              if (snap.hasData) {
                                return Image.memory(
                                  snap.data!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                width: 88,
                                height: 88,
                                color: cs.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() => _images.removeAt(index)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (!kIsWeb) ...[
              const SizedBox(height: 20),
              _SectionTitle(text: strings.postCreateSectionLocation),
              const SizedBox(height: 8),
              ...[
                ('none', strings.postCreateLocationNone, Icons.location_off_outlined),
                ('approximate', strings.postCreateLocationApproximate, Icons.location_searching),
                ('precise', strings.postCreateLocationPrecise, Icons.my_location),
              ].map((t) {
                final sel = _locationMode == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    selected: sel,
                    button: true,
                    label: t.$2,
                    child: Material(
                      color: cs.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: sel ? cs.primary : cs.outline,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: _isLoading
                            ? null
                            : () async {
                                setState(() => _locationMode = t.$1);
                                if (t.$1 != 'none' &&
                                    (_latitude == null || _longitude == null)) {
                                  await _attachCurrentLocation();
                                }
                              },
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
                                  sel ? Icons.check_circle : Icons.circle_outlined,
                                  color: sel ? cs.primary : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Icon(t.$3, size: 22),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t.$2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_locationMode != 'none') ...[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: (_isLoading || _loadingLocation) ? null : _attachCurrentLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(strings.useCurrentLocation),
                ),
                if (_latitude != null && _longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
            const SizedBox(height: 24),
            _SectionTitle(text: strings.postCreateSectionPreview),
            const SizedBox(height: 8),
            Semantics(
              label: '${strings.postCreateSectionPreview}. ${_previewText(strings)}',
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _previewText(strings),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: strings.publish,
              button: true,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitPost,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.publish, style: theme.textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.postNote,
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

  IconData _inputModeIcon(String k) {
    switch (k) {
      case 'keyboard':
        return Icons.keyboard;
      case 'voice':
        return Icons.mic;
      case 'headEyes':
        return Icons.face_retouching_natural;
      case 'vibration':
        return Icons.vibration;
      case 'deafBlind':
        return Icons.touch_app;
      case 'caregiver':
        return Icons.family_restroom;
      default:
        return Icons.edit;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

typedef _InclusiveOption = ({
  String key,
  String label,
  IconData icon,
  String semantic,
});

class _InclusiveRow extends StatelessWidget {
  const _InclusiveRow({
    required this.selectedKey,
    required this.options,
    required this.onSelect,
  });

  final String selectedKey;
  final List<_InclusiveOption> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: options.map((o) {
        final sel = selectedKey == o.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            selected: sel,
            button: true,
            label: o.semantic,
            child: Material(
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: sel ? cs.primary : cs.outline,
                  width: sel ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => onSelect(o.key),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          sel ? Icons.check_circle : Icons.circle_outlined,
                          color: sel ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Icon(o.icon, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            o.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: sel ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({
    required this.value,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final String hint;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      hint: hint,
      checked: value,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: CheckboxListTile(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            title: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }
}
