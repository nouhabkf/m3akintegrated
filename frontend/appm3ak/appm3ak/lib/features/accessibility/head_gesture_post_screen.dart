import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/location/current_position.dart';
import '../../data/models/post_model.dart';
import 'accessibility_post_handoff.dart';
import 'canned_post_phrases.dart';

/// Mode “Tête & yeux” version Hub:
/// - Caméra arrière = l’obstacle (photo publiée).
/// - Caméra avant = le contrôle (visage/clignement) — aucune photo du visage n’est sauvegardée.
/// - Menu texte: sélection par “dwell time” (visée) + clignement long pour publier.
class HeadGesturePostScreen extends StatefulWidget {
  const HeadGesturePostScreen({super.key});

  @override
  State<HeadGesturePostScreen> createState() => _HeadGesturePostScreenState();
}

enum _Step {
  scanning,
  aimingRear,
  captured,
  menu,
  finalConfirm,
  locationConfirm,
  success,
}

class _HeadGesturePostScreenState extends State<HeadGesturePostScreen> {
  CameraController? _rear;
  CameraController? _front;
  CameraDescription? _rearDesc;
  CameraDescription? _frontDesc;
  String _cameraDebug = '';
  late final FaceDetector _faceDetector;
  final FlutterTts _tts = FlutterTts();

  bool _initializing = true;
  bool _processingFrame = false;
  bool _busyCapture = false;

  _Step _step = _Step.scanning;
  final List<XFile> _shots = [];

  bool _faceDetected = false;
  String _liveDebug = '';
  DateTime _lastDebugUi = DateTime.fromMillisecondsSinceEpoch(0);

  bool _eyesWereOpen = false;
  DateTime? _eyeClosedSince;
  DateTime _lastBlinkAt = DateTime.fromMillisecondsSinceEpoch(0);

  int _hoverIndex = -1;
  int _selectedIndex = -1;
  double _progress = 0; // 0..1
  Timer? _dwellTimer;
  DateTime? _menuEnteredAt;

  static const Duration _blinkCooldown = Duration(milliseconds: 900);
  static const Duration _longBlinkMin = Duration(milliseconds: 900);
  // Plus lent pour éviter des sélections trop rapides/involontaires.
  static const Duration _dwellDuration = Duration(milliseconds: 2600);
  static const Duration _dwellTick = Duration(milliseconds: 80);

  static const double _eyeClosedMax = 0.40;
  static const double _eyeOpenMin = 0.48;
  bool _returnHandoffOnPublish = false;
  double? _draftLatitude;
  double? _draftLongitude;
  String? _draftLocationSharingMode;
  bool _locationDecisionInProgress = false;
  DateTime _lastLocationDecisionAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _locationDecisionCooldown = Duration(milliseconds: 1400);
  static const Duration _locationYesHoldMin = Duration(milliseconds: 1000);
  static const double _locationNoYawLeft = -16;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,
        minFaceSize: 0.06,
      ),
    );
    if (kIsWeb) {
      _initializing = false;
      return;
    }
    _initTts();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = GoRouterState.of(context).uri.queryParameters;
      _returnHandoffOnPublish = q['returnHandoff'] == '1';
    });
  }

  Future<void> _init() async {
    final ok = await _ensureCameraPermission();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _liveDebug =
            'Permission caméra refusée.\nActive-la dans Paramètres > Apps > Ma3ak > Autorisations.';
      });
      unawaited(_speak("Permission caméra refusée."));
      return;
    }
    await _initCameras();
  }

  Future<bool> _ensureCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      final req = await Permission.camera.request();
      return req.isGranted;
    } catch (_) {
      // Fallback: let camera plugin request itself.
      return true;
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.42);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _initCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initializing = false;
            _liveDebug = 'Aucune caméra détectée sur cet appareil.';
          });
        }
        unawaited(_speak('Aucune caméra détectée.'));
        return;
      }

      CameraDescription? frontDesc;
      CameraDescription? rearDesc;

      // Choix robuste: on évite `orElse: cameras.first` car certains devices listent la front en premier
      // et la "back" peut être absente ou non marquée correctement.
      final fronts =
          cameras.where((c) => c.lensDirection == CameraLensDirection.front);
      if (fronts.isNotEmpty) {
        frontDesc = fronts.first;
      }

      final backs =
          cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      if (backs.isNotEmpty) {
        rearDesc = backs.first;
      }

      // Fallbacks: si pas de "back" reconnu, prend une caméra différente de la front si possible.
      frontDesc ??= cameras.first;
      rearDesc ??= cameras.firstWhere(
        (c) => c.name != frontDesc!.name,
        orElse: () => cameras.length >= 2 ? cameras.last : cameras.first,
      );
      // Si malgré tout c'est la même, on force "last" quand possible.
      if (rearDesc.name == frontDesc.name && cameras.length >= 2) {
        rearDesc = cameras.last;
      }

      _frontDesc = frontDesc;
      _rearDesc = rearDesc;
      _cameraDebug =
          'Front=${frontDesc.lensDirection.name}/${frontDesc.name} · Rear=${rearDesc.lensDirection.name}/${rearDesc.name}';

      // IMPORTANT (compatibilité Android): n'ouvre qu'UNE caméra à la fois.
      // Le double preview (avant+arrière) déclenche souvent `releaseFlutterSurfaceTexture` sur certains appareils.
      await _initFrontOnly();
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _liveDebug = 'Erreur caméra.\n${e.runtimeType}: $e';
        });
      }
      unawaited(_speak('Erreur caméra.'));
    }
  }

  Future<void> _disposeRear() async {
    final c = _rear;
    _rear = null;
    if (c == null) return;
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _disposeFront() async {
    final c = _front;
    _front = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _initFrontOnly() async {
    final desc = _frontDesc;
    if (desc == null) return;
    await _disposeRear();
    await _disposeFront();

    CameraController front = CameraController(
      desc,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    try {
      await front.initialize();
    } catch (e) {
      await front.dispose();
      // Fallback format (certains devices)
      front = CameraController(
        desc,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await front.initialize();
    }

    if (!mounted) {
      await front.dispose();
      return;
    }
    setState(() {
      _front = front;
      _initializing = false;
      // Ne force pas un reset si on revient du mode arrière avec une photo déjà capturée.
      if (_step == _Step.aimingRear) {
        _step = _Step.scanning;
      }
    });
    await _startFrontStreamWithRetry();
    unawaited(_speak(
        "Contrôle activé. Regardez la caméra. Clignement long pour commencer la capture."));
  }

  Future<void> _initRearOnly() async {
    final desc = _rearDesc;
    if (desc == null) return;
    await _disposeRear();
    await _disposeFront();

    final rear = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await rear.initialize();
    if (!mounted) {
      await rear.dispose();
      return;
    }
    setState(() {
      _rear = rear;
    });
  }

  Future<void> _startFrontStream() async {
    final c = _front;
    if (c == null || !c.value.isInitialized || c.value.isStreamingImages) return;
    await c.startImageStream(_onFrontImage);
  }

  Future<void> _startFrontStreamWithRetry() async {
    try {
      await _startFrontStream();
      return;
    } catch (_) {
      // CameraX peut être instable juste après init: retry court.
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    try {
      await _startFrontStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liveDebug = 'Erreur stream caméra avant.\n${e.runtimeType}: $e';
      });
    }
  }

  InputImageRotation? _inputRotationForCamera(CameraDescription camera) {
    var o = camera.sensorOrientation;
    if (Platform.isAndroid && camera.lensDirection == CameraLensDirection.front) {
      o = (360 - o) % 360;
    }
    return InputImageRotationValue.fromRawValue(o);
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    // Convert YUV_420_888 planes to NV21 (Y + interleaved VU).
    // This makes ML Kit input reliable across Android devices/CameraX backends.
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = Uint8List(width * height + (width * height ~/ 2));
    var outIndex = 0;

    // Copy Y.
    for (var row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      out.setRange(outIndex, outIndex + width, yPlane.bytes, rowStart);
      outIndex += width;
    }

    // Interleave VU for NV21.
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (var row = 0; row < uvHeight; row++) {
      final uRow = row * uvRowStride;
      final vRow = row * vPlane.bytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        final uvOffset = col * uvPixelStride;
        final v = vPlane.bytes[vRow + uvOffset];
        final u = uPlane.bytes[uRow + uvOffset];
        out[outIndex++] = v;
        out[outIndex++] = u;
      }
    }
    return out;
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = _inputRotationForCamera(camera);
    if (rotation == null) return null;

    if (Platform.isAndroid) {
      // On Android, ML Kit is most reliable with NV21. CameraX may deliver YUV_420_888 (3 planes),
      // so we convert to NV21 when needed.
      final bytes = image.planes.length == 1
          ? image.planes.first.bytes
          : (image.planes.length >= 3 ? _yuv420ToNv21(image) : null);
      if (bytes == null) return null;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          // NV21 stride = image width in bytes.
          bytesPerRow: image.width,
        ),
      );
    }

    if (Platform.isIOS) {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
    return null;
  }

  Future<void> _onFrontImage(CameraImage image) async {
    if (_processingFrame || _busyCapture || !mounted) return;
    _processingFrame = true;
    try {
      final controller = _front;
      if (controller == null) return;
      final input = _toInputImage(image, controller.description);
      if (input == null) return;

      final faces = await _faceDetector.processImage(input);
      if (!mounted) return;
      if (faces.isEmpty) {
        _faceDetected = false;
        _throttledDebug(null, null, null, null, faceDetected: false);
        return;
      }

      final face = faces.first;
      final y = face.headEulerAngleY;
      final z = face.headEulerAngleZ;
      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;

      _faceDetected = true;
      _throttledDebug(y, z, left, right, faceDetected: true);
      if (_step == _Step.locationConfirm) {
        _handleLocationConfirm(y, left, right);
        return;
      }
      _handleDwellSelection(y, z);
      _handleBlink(left, right);
    } catch (_) {
      // ignore frame
    } finally {
      _processingFrame = false;
    }
  }

  void _throttledDebug(
    double? y,
    double? z,
    double? left,
    double? right, {
    required bool faceDetected,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastDebugUi) < const Duration(milliseconds: 350)) return;
    _lastDebugUi = now;

    if (!faceDetected) {
      if (mounted && _liveDebug != 'Pas de visage détecté') {
        setState(() => _liveDebug = 'Pas de visage détecté — facez bien la caméra.');
      }
      return;
    }
    final ys = y?.toStringAsFixed(0) ?? '—';
    final zs = z?.toStringAsFixed(0) ?? '—';
    final ls = left?.toStringAsFixed(2) ?? '—';
    final rs = right?.toStringAsFixed(2) ?? '—';
    final line = 'Visage OK — tête Y:$ys° Z:$zs° · yeux g:$ls d:$rs';
    if (mounted && line != _liveDebug) setState(() => _liveDebug = line);
  }

  int _indexFromHeadPose(double? y, double? z) {
    // Approximation “dwell eye selection”.
    final yaw = y ?? 0;
    final roll = z ?? 0;
    final col = yaw >= 0 ? 1 : 0;
    final row = roll >= 0 ? 1 : 0;
    final idx = (row * 2) + col;
    return idx.clamp(0, 3);
  }

  void _handleDwellSelection(double? y, double? z) {
    if (_step != _Step.menu) return;
    if (!_faceDetected) return;
    final entered = _menuEnteredAt;
    if (entered != null &&
        DateTime.now().difference(entered) < const Duration(milliseconds: 900)) {
      return; // petite latence pour éviter sélection immédiate
    }
    final idx = _indexFromHeadPose(y, z);
    if (idx == _hoverIndex) return;

    _hoverIndex = idx;
    _progress = 0;
    _dwellTimer?.cancel();
    _dwellTimer = Timer.periodic(_dwellTick, (t) {
      if (!mounted || _step != _Step.menu) {
        t.cancel();
        return;
      }
      setState(() {
        _progress = (_progress +
                (_dwellTick.inMilliseconds / _dwellDuration.inMilliseconds))
            .clamp(0, 1);
      });
      if (_progress >= 1) {
        t.cancel();
        setState(() {
          _selectedIndex = _hoverIndex;
          _step = _Step.finalConfirm;
        });
        HapticFeedback.mediumImpact();
        unawaited(_speak('Texte choisi. Clignement long pour publier.'));
      }
    });
  }

  void _handleBlink(double? left, double? right) {
    if (_busyCapture) return;
    if (left == null && right == null) return;

    final minEye = (left != null && right != null)
        ? math.min(left, right)
        : (left ?? right!);
    final now = DateTime.now();

    if (minEye >= _eyeOpenMin) {
      _eyesWereOpen = true;
      _eyeClosedSince = null;
      return;
    }
    if (minEye > _eyeClosedMax) return;
    if (!_eyesWereOpen) return;

    _eyeClosedSince ??= now;
    final closedFor = now.difference(_eyeClosedSince!);
    if (closedFor < _longBlinkMin) return;
    if (now.difference(_lastBlinkAt) < _blinkCooldown) return;

    _eyesWereOpen = false;
    _lastBlinkAt = now;
    HapticFeedback.heavyImpact();
    _onLongBlink();
  }

  void _onLongBlink() {
    switch (_step) {
      case _Step.scanning:
        unawaited(_captureRearPhoto());
        return;
      case _Step.aimingRear:
        // Ignore: on laisse la capture se dérouler.
        return;
      case _Step.captured:
        setState(() {
          _step = _Step.menu;
          _hoverIndex = 0;
          _selectedIndex = -1;
          _progress = 0;
          _menuEnteredAt = DateTime.now();
        });
        unawaited(_speak('Choisissez un commentaire en visant une carte.'));
        return;
      case _Step.finalConfirm:
        if (_selectedIndex < 0) return;
        setState(() {
          _step = _Step.locationConfirm;
          _locationDecisionInProgress = false;
        });
        _eyeClosedSince = null;
        _eyesWereOpen = false;
        unawaited(
          _speak(
            'Photo ajoutée. Voulez-vous joindre votre localisation ? '
            'Fermez les yeux pour oui. Tournez la tête à gauche pour non.',
          ),
        );
        return;
      case _Step.menu:
      case _Step.locationConfirm:
      case _Step.success:
        return;
    }
  }

  Future<void> _resolveLocationDecision({required bool attach}) async {
    if (_locationDecisionInProgress) return;
    final now = DateTime.now();
    if (now.difference(_lastLocationDecisionAt) < _locationDecisionCooldown) {
      return;
    }
    _lastLocationDecisionAt = now;
    _locationDecisionInProgress = true;

    if (!attach) {
      _draftLatitude = null;
      _draftLongitude = null;
      _draftLocationSharingMode = null;
      await _speak('Localisation ignorée.');
      if (!mounted) return;
      setState(() => _step = _Step.success);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _finishWithHandoff();
      });
      return;
    }

    final pos = await getCurrentPositionForPostOrNull();
    if (!mounted) return;
    if (pos == null) {
      _draftLatitude = null;
      _draftLongitude = null;
      _draftLocationSharingMode = null;
      await _speak(
        'Localisation non disponible. Vous pouvez continuer sans localisation.',
      );
    } else {
      _draftLatitude = pos.latitude;
      _draftLongitude = pos.longitude;
      _draftLocationSharingMode = 'precise';
      await _speak('Localisation ajoutée.');
    }
    if (!mounted) return;
    setState(() => _step = _Step.success);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _finishWithHandoff();
    });
  }

  void _handleLocationConfirm(double? y, double? left, double? right) {
    if (_step != _Step.locationConfirm || _locationDecisionInProgress) return;

    if (y != null && y <= _locationNoYawLeft) {
      unawaited(_resolveLocationDecision(attach: false));
      return;
    }

    if (left == null || right == null) return;
    final minEye = math.min(left, right);
    final now = DateTime.now();
    if (minEye >= _eyeOpenMin) {
      _eyesWereOpen = true;
      _eyeClosedSince = null;
      return;
    }
    if (minEye > _eyeClosedMax) return;
    _eyeClosedSince ??= now;
    final held = now.difference(_eyeClosedSince!);
    if (held < _locationYesHoldMin) return;
    unawaited(_resolveLocationDecision(attach: true));
  }

  Future<void> _captureRearPhoto() async {
    if (_busyCapture) return;
    setState(() => _busyCapture = true);
    try {
      // Switch camera: front (control) -> rear (preview+photo) -> front
      if (mounted) setState(() => _step = _Step.aimingRear);
      await _initRearOnly();
      if (!mounted) return;
      unawaited(_speak("Cadrez l'obstacle. Photo dans trois. Deux. Un."));
      await Future<void>.delayed(const Duration(milliseconds: 1750));

      final c = _rear;
      if (c == null || !c.value.isInitialized) {
        throw StateError('rear_not_initialized');
      }

      final file = await c.takePicture();
      if (!mounted) return;
      setState(() {
        _shots
          ..clear()
          ..add(file);
        _step = _Step.captured;
      });
      // Re-enable front control for menu selection + publish confirm
      await _initFrontOnly();
      unawaited(_speak('Photo capturée. Clignement long pour ajouter le texte.'));
    } catch (_) {
      unawaited(_speak('Échec de la photo.'));
    } finally {
      if (mounted) setState(() => _busyCapture = false);
    }
  }

  void _finishWithHandoff() {
    final idx = _selectedIndex >= 0 ? _selectedIndex : 0;
    final text = kAccessibilityCannedPostPhrases[idx];
    final handoff = AccessibilityPostHandoff(
      content: text,
      images: List<XFile>.from(_shots),
      suggestedPostType: PostType.handicapMoteur,
      autoPublish: !_returnHandoffOnPublish,
      latitude: _draftLatitude,
      longitude: _draftLongitude,
      locationSharingMode: _draftLocationSharingMode,
    );
    if (_returnHandoffOnPublish) {
      context.pop(handoff);
      return;
    }
    context.pushReplacement('/create-post', extra: handoff);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    unawaited(_disposeFront());
    unawaited(_disposeRear());
    unawaited(_faceDetector.close());
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post par mouvement de tête')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cette fonction utilise la caméra et ML Kit sur appareil mobile uniquement.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post — tête & yeux'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _faceDetected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.18)
                                : Colors.grey.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _faceDetected
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.55)
                                  : Colors.grey.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.remove_red_eye_outlined,
                            color: _faceDetected ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contrôle avant',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _faceDetected ? 'Visage détecté' : 'Cherche le visage…',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.volume_up,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black,
                              child: (_rear != null && _rear!.value.isInitialized)
                                  ? CameraPreview(_rear!)
                                  : Center(
                                      child: Text(
                                        'Contrôle yeux actif.\nClignement long pour commencer.',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ),
                          if (_step == _Step.scanning)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "CADREZ L'OBSTACLE",
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Clignement long pour capturer',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_liveDebug.isNotEmpty)
                                        Text(
                                          _liveDebug,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (_cameraDebug.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _cameraDebug,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontFamily: 'monospace',
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_step == _Step.captured)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.95),
                                        size: 56,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Photo capturée',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Clignement long pour ajouter le texte',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_step == _Step.aimingRear)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "CADREZ L'OBSTACLE",
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Photo imminente…',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_step == _Step.menu)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.62),
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'FIXEZ VOTRE COMMENTAIRE',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF93C5FD),
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _MenuGrid(
                                      phrases: kAccessibilityCannedPostPhrases.take(4).toList(),
                                      hoverIndex: _hoverIndex,
                                      progress: _progress,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_step == _Step.finalConfirm && _selectedIndex >= 0)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF1E3A8A), Color(0xFF020617)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.all(18),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '"${kAccessibilityCannedPostPhrases[_selectedIndex]}"',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: const Color(0xFF1E3A8A),
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Clignement long pour publier',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFFBFDBFE),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_step == _Step.locationConfirm)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.72),
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Joindre la localisation ?',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Fermez les yeux pour OUI\nTournez la tête à gauche pour NON',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_step == _Step.success)
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFF16A34A),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 74),
                                      const SizedBox(height: 10),
                                      Text(
                                        'PUBLIÉ !',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Communauté M3AK alertée',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.phrases,
    required this.hoverIndex,
    required this.progress,
  });

  final List<String> phrases;
  final int hoverIndex;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: col == 0 ? 12 : 0),
                      child: _MenuCard(
                        text: phrases[(row * 2) + col],
                        selected: hoverIndex == (row * 2) + col,
                        progress: hoverIndex == (row * 2) + col ? progress : 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Text(
          'Visez une carte jusqu’à sélection',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.text,
    required this.selected,
    required this.progress,
  });

  final String text;
  final bool selected;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? const Color(0xFF2563EB).withValues(alpha: 0.80)
              : Colors.white.withValues(alpha: 0.10),
          width: selected ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (selected)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
