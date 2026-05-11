import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:appm3ak/m3ak_port/models/sign_explain_response.dart';
import 'package:appm3ak/m3ak_port/services/sign_ai_service.dart';

class SignCameraScreen extends StatefulWidget {
  const SignCameraScreen({super.key});

  @override
  State<SignCameraScreen> createState() => _SignCameraScreenState();
}

class _SignCameraScreenState extends State<SignCameraScreen> {
  final SignAiService _signAiService = SignAiService();
  final FlutterTts _tts = FlutterTts();
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  bool _isAutoAnalyzeEnabled = true;
  bool _isMuted = false;
  String? _error;
  SignExplainResponse? _lastResult;
  final List<String> _recognizedWords = [];
  String? _lastSpokenWord;
  DateTime? _lastAnalyzedAt;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  Timer? _autoAnalyzeTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
    _checkBackendHealth();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
    } catch (_) {
      // TTS remains optional; camera and analysis must continue.
    }
  }

  Future<void> _checkBackendHealth() async {
    final ok = await _signAiService.pingServer();
    if (!mounted || ok) return;
    setState(() {
      _error =
          'Backend IA introuvable (${_signAiService.baseUrl}). Verifiez Nest (Ma3ak API) et la route /m3ak.';
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = 'Aucune camera disponible.';
        });
        return;
      }

      _cameras = cameras;
      _selectedCameraIndex = 0;
      await _startCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Impossible d ouvrir la camera: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
        _error = null;
      });
      _startAutoAnalyze();
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error = 'Erreur camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isAnalyzing) return;
    setState(() => _isInitializing = true);
    _autoAnalyzeTimer?.cancel();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  void _startAutoAnalyze() {
    _autoAnalyzeTimer?.cancel();
    if (!_isAutoAnalyzeEnabled) return;
    // Lance une analyse immediatement puis en continu.
    _analyzeCurrentFrame();
    _autoAnalyzeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isAnalyzing && mounted) {
        _analyzeCurrentFrame();
      }
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final XFile snapshot = await controller.takePicture();
      final bytes = await snapshot.readAsBytes();
      final result = await _signAiService.explainSignBytes(bytes);
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _lastAnalyzedAt = DateTime.now();
        final word = result.detectedWord;
        if (word != null && word.isNotEmpty && word != _lastSpokenWord) {
          _lastSpokenWord = word;
          _recognizedWords.add(word);
          if (_recognizedWords.length > 8) {
            _recognizedWords.removeAt(0);
          }
          _speakWord(word);
        }
      });
    } catch (e) {
      if (!mounted) return;
      String msg;
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final detail = (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : data?.toString();

        if (status != null) {
          msg = 'Analyse IA impossible (HTTP $status): ${detail ?? e.message}';
        } else {
          msg = 'Analyse IA impossible: ${e.message}';
        }
      } else {
        msg = 'Analyse IA impossible: $e';
      }
      setState(() {
        _error = msg;
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  void dispose() {
    _autoAnalyzeTimer?.cancel();
    _tts.stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _speakWord(String word) async {
    if (_isMuted || word.trim().isEmpty) return;
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Délai pour éviter les conflits
      await _tts.speak(word);
    } catch (e) {
      // Ignorer les erreurs TTS pour garder l'UX stable
      print('TTS Error: $e');
    }
  }

  void _toggleAutoAnalyze() {
    setState(() {
      _isAutoAnalyzeEnabled = !_isAutoAnalyzeEnabled;
    });
    _startAutoAnalyze();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _tts.stop();
    }
  }

  void _clearSession() {
    setState(() {
      _recognizedWords.clear();
      _lastResult = null;
      _lastSpokenWord = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: const Text(
          'Camera IA - Traducteur complet',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: _buildCameraArea(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildStatusStrip(),
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (_lastResult != null) _buildResultCard(_lastResult!),
            if (_recognizedWords.isNotEmpty) _buildHistoryCard(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInitializing ? null : _switchCamera,
                    icon: const Icon(Icons.cameraswitch),
                    label: const Text('Changer camera'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isInitializing || _isAnalyzing) ? null : _analyzeCurrentFrame,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.psychology),
                    label: Text(_isAnalyzing ? 'Analyse...' : 'Analyser IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInitializing ? null : _toggleAutoAnalyze,
                    icon: Icon(_isAutoAnalyzeEnabled ? Icons.pause_circle : Icons.play_circle),
                    label: Text(_isAutoAnalyzeEnabled ? 'Pause auto' : 'Auto ON'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                    label: Text(_isMuted ? 'Muet' : 'Voix'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearSession,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Nettoyer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera indisponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        if (_lastResult != null && _lastResult!.landmarks.isNotEmpty)
          CustomPaint(
            painter: _HandLandmarksPainter(
              landmarks: _lastResult!.landmarks,
            ),
          ),
        if (_isAnalyzing)
          const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(color: Colors.white),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isAutoAnalyzeEnabled
                  ? 'Cadrez votre main: analyse auto active'
                  : 'Analyse auto en pause - utilisez "Analyser IA"',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        if (_lastResult != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signe: ${_lastResult!.detectedWord ?? "Aucun"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastResult!.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(SignExplainResponse result) {
    final detected = result.detectedWord ?? 'Aucun signe';
    final fingers = result.raisedFingers.isEmpty
        ? 'Aucun doigt detecte'
        : result.raisedFingers.join(', ');
    final confidencePct = (result.confidence * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signe detecte: $detected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.explanation,
            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Doigts: ${result.raisedFingersCount} ($fingers) · Confiance: $confidencePct%',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mots reconnus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recognizedWords.reversed.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    final last = _lastAnalyzedAt;
    final lastText = last == null
        ? '--'
        : '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}';
    final statusColor = _error == null ? const Color(0xFF2E7D32) : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusChip(
            label: _error == null ? 'Backend: connecte' : 'Backend: erreur',
            color: statusColor,
            icon: _error == null ? Icons.cloud_done : Icons.cloud_off,
          ),
          _StatusChip(
            label: _isAutoAnalyzeEnabled ? 'Auto: ON' : 'Auto: OFF',
            color: const Color(0xFF1565C0),
            icon: _isAutoAnalyzeEnabled ? Icons.bolt : Icons.bolt_outlined,
          ),
          _StatusChip(
            label: _isMuted ? 'Voix: OFF' : 'Voix: ON',
            color: const Color(0xFF6A1B9A),
            icon: _isMuted ? Icons.volume_off : Icons.volume_up,
          ),
          _StatusChip(
            label: 'Derniere analyse: $lastText',
            color: const Color(0xFF00897B),
            icon: Icons.schedule,
          ),
          _StatusChip(
            label: 'Mots: ${_recognizedWords.length}',
            color: const Color(0xFFEF6C00),
            icon: Icons.history,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandLandmarksPainter extends CustomPainter {
  _HandLandmarksPainter({required this.landmarks});

  final List<SignLandmark> landmarks;

  static const List<List<int>> _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [5, 9], [9, 10], [10, 11], [11, 12],
    [9, 13], [13, 14], [14, 15], [15, 16],
    [13, 17], [17, 18], [18, 19], [19, 20],
    [0, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xAA00E676)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final c in _connections) {
      if (c[0] < landmarks.length && c[1] < landmarks.length) {
        final p1 = Offset(landmarks[c[0]].x * size.width, landmarks[c[0]].y * size.height);
        final p2 = Offset(landmarks[c[1]].x * size.width, landmarks[c[1]].y * size.height);
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    for (final lm in landmarks) {
      final point = Offset(lm.x * size.width, lm.y * size.height);
      canvas.drawCircle(point, 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandLandmarksPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}

