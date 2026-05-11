import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../providers/api_providers.dart';

enum _RiskLevel { safe, warning, danger }

class ActivityPostureDetectionScreen extends ConsumerStatefulWidget {
  const ActivityPostureDetectionScreen({super.key});

  @override
  ConsumerState<ActivityPostureDetectionScreen> createState() =>
      _ActivityPostureDetectionScreenState();
}

class _ActivityPostureDetectionScreenState
    extends ConsumerState<ActivityPostureDetectionScreen> {
  CameraController? _cameraController;
  late final PoseDetector _poseDetector;

  bool _initializing = true;
  bool _running = false;
  bool _processing = false;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _badPostureSince;
  DateTime? _lastFallAlertSentAt;

  String _statusTitle = 'Surveillance inactive';
  String _statusMessage =
      'Appuyez sur "Démarrer" pour analyser la posture et détecter les chutes.';
  _RiskLevel _riskLevel = _RiskLevel.safe;
  bool _autoSosOnFall = true;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _stopDetection(disposeCamera: true);
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _statusTitle = 'Caméra introuvable';
          _statusMessage =
              'Aucune caméra détectée sur cet appareil. Vérifiez les permissions.';
          _riskLevel = _RiskLevel.warning;
        });
        return;
      }

      final preferred = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        preferred,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _statusTitle = 'Erreur caméra';
        _statusMessage =
            'Impossible d’accéder à la caméra. Autorisez la permission dans les paramètres.';
        _riskLevel = _RiskLevel.danger;
      });
    }
  }

  Future<void> _startDetection() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _running) return;

    await controller.startImageStream((image) async {
      if (_processing) return;
      final now = DateTime.now();
      if (now.difference(_lastFrameAt).inMilliseconds < 600) return;

      _processing = true;
      _lastFrameAt = now;
      try {
        final inputImage = _toInputImage(image, controller.description);
        if (inputImage == null) return;

        final poses = await _poseDetector.processImage(inputImage);
        _evaluatePose(poses, now);
      } catch (_) {
        if (mounted) {
          setState(() {
            _statusTitle = 'Analyse interrompue';
            _statusMessage =
                'Le flux caméra a rencontré un problème. Redémarrez la surveillance.';
            _riskLevel = _RiskLevel.warning;
          });
        }
      } finally {
        _processing = false;
      }
    });

    if (!mounted) return;
    setState(() {
      _running = true;
      _statusTitle = 'Surveillance active';
      _statusMessage = 'Analyse en cours...';
      _riskLevel = _RiskLevel.safe;
    });
  }

  Future<void> _stopDetection({bool disposeCamera = false}) async {
    final controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    if (disposeCamera && controller != null) {
      await controller.dispose();
      _cameraController = null;
    }
    if (mounted) {
      setState(() {
        _running = false;
      });
    } else {
      _running = false;
    }
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isAndroid) {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    if (Platform.isIOS) {
      final plane = image.planes.first;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    }

    return null;
  }

  Future<void> _evaluatePose(List<Pose> poses, DateTime now) async {
    if (!mounted) return;
    if (poses.isEmpty) {
      setState(() {
        _statusTitle = 'Aucune posture détectée';
        _statusMessage = 'Placez le corps complet dans le cadre.';
        _riskLevel = _RiskLevel.warning;
      });
      _badPostureSince = null;
      return;
    }

    final pose = poses.first;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      setState(() {
        _statusTitle = 'Posture incomplète';
        _statusMessage = 'Le haut du corps doit rester visible pour analyser.';
        _riskLevel = _RiskLevel.warning;
      });
      _badPostureSince = null;
      return;
    }

    final shoulderCenter = Offset(
      (leftShoulder.x + rightShoulder.x) / 2,
      (leftShoulder.y + rightShoulder.y) / 2,
    );
    final hipCenter = Offset(
      (leftHip.x + rightHip.x) / 2,
      (leftHip.y + rightHip.y) / 2,
    );

    final torsoVector = hipCenter - shoulderCenter;
    final torsoLength = torsoVector.distance;
    if (torsoLength < 20) {
      return;
    }

    final angleToVertical = (math.atan2(torsoVector.dx, torsoVector.dy)).abs() *
        180 /
        math.pi;

    final isLikelyFall = angleToVertical > 55 ||
        (nose != null && nose.y > hipCenter.dy && angleToVertical > 45);

    final isBadPosture = angleToVertical > 25 && angleToVertical <= 55;

    if (isLikelyFall) {
      setState(() {
        _statusTitle = 'Chute détectée';
        _statusMessage =
            'Risque élevé: position au sol détectée. Vérifiez immédiatement la personne.';
        _riskLevel = _RiskLevel.danger;
      });
      _badPostureSince = null;
      if (_autoSosOnFall) {
        await _sendSosForFall(now);
      }
      return;
    }

    if (isBadPosture) {
      _badPostureSince ??= now;
      final seconds = now.difference(_badPostureSince!).inSeconds;
      if (seconds >= 45) {
        setState(() {
          _statusTitle = 'Mauvaise position prolongée';
          _statusMessage =
              'Tu es resté assis/mal positionné trop longtemps. Risque de douleur lombaire.';
          _riskLevel = _RiskLevel.warning;
        });
      } else {
        setState(() {
          _statusTitle = 'Position à corriger';
          _statusMessage =
              'Dos incliné détecté. Redressez le buste et repositionnez le bassin.';
          _riskLevel = _RiskLevel.warning;
        });
      }
      return;
    }

    _badPostureSince = null;
    setState(() {
      _statusTitle = 'Position correcte';
      _statusMessage = 'Posture stable détectée. Continuez ainsi.';
      _riskLevel = _RiskLevel.safe;
    });
  }

  Future<void> _sendSosForFall(DateTime now) async {
    final lastSent = _lastFallAlertSentAt;
    if (lastSent != null && now.difference(lastSent).inSeconds < 90) {
      return;
    }

    try {
      final repo = ref.read(sosRepositoryProvider);
      // TODO: brancher la géolocalisation réelle.
      await repo.create(latitude: 36.8065, longitude: 10.1815);
      _lastFallAlertSentAt = now;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte chute envoyée à l’accompagnant')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec envoi alerte chute')),
      );
    }
  }

  Color _riskColor(ThemeData theme) {
    switch (_riskLevel) {
      case _RiskLevel.safe:
        return Colors.green;
      case _RiskLevel.warning:
        return Colors.orange;
      case _RiskLevel.danger:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final camera = _cameraController;
    final riskColor = _riskColor(theme);

    return Scaffold(
      appBar: AppBar(title: const Text('Détection activité & posture')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColoredBox(
                        color: Colors.black,
                        child: camera != null && camera.value.isInitialized
                            ? CameraPreview(camera)
                            : const Center(
                                child: Text(
                                  'Caméra non disponible',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.circle, color: riskColor, size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _autoSosOnFall,
                    onChanged: (value) => setState(() => _autoSosOnFall = value),
                    title: const Text('Envoyer alerte SOS automatique si chute'),
                    subtitle: const Text('Avertit l’accompagnant immédiatement'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _running ? () => _stopDetection() : _startDetection,
                    icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _running
                          ? 'Arrêter la surveillance'
                          : 'Démarrer la surveillance',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
