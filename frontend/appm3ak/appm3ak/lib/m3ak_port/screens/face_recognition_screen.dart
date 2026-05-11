import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:appm3ak/m3ak_port/models/face_test_result.dart';
import 'package:appm3ak/m3ak_port/services/face_ai_service.dart';
import 'package:appm3ak/m3ak_port/services/face_recognition_service.dart';
import 'package:appm3ak/m3ak_port/services/voice_command_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum FaceRecognitionMode { recognition, adding, testing }

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final FaceAiService _faceAiService = FaceAiService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceCommandService _voiceCommandService = VoiceCommandService();

  CameraController? _controller;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  String? _error;
  FaceRecognitionMode _mode = FaceRecognitionMode.recognition;

  // Mode ajout
  String? _addingName;
  String? _addingRelation;
  final List<Uint8List> _capturedPhotos = [];
  final int _photosToCapture = 3;
  bool _isCapturing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  // Reconnaissance
  String? _lastRecognizedPerson;
  DateTime? _lastAnnouncement;
  Timer? _recognitionTimer;
  Timer? _voiceTimer;

  bool _faceWelcomeAnnounced = false;

  // Mode test détaillé
  FaceTestResult? _lastTestResult;
  bool _showTestDetails = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
    _initVoiceCommands();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = 'Aucune caméra disponible.';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });

      if (_mode == FaceRecognitionMode.recognition) {
        _startRecognition();
        if (!_faceWelcomeAnnounced) {
          _faceWelcomeAnnounced = true;
          unawaited(_announceFaceWelcomeAfterOpen());
        }
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Erreur caméra: $e';
      });
    }
  }

  Future<void> _initVoiceCommands() async {
    await _voiceCommandService.initialize();
    await _voiceCommandService.startListening(
      _handleVoiceCommand,
      context: VoiceListenContext.faceRecognition,
    );
  }

  /// Laisse le micro se stabiliser puis décrit les boutons pour l’accessibilité.
  Future<void> _announceFaceWelcomeAfterOpen() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _mode != FaceRecognitionMode.recognition) return;
    await _speak(
      'M3AK Visage est prêt. En bas de l’écran, deux boutons : Ajouter, pour enregistrer une nouvelle personne, '
      'et Tester, pour lancer une reconnaissance immédiate. Vous pouvez aussi dire ajouter, ou bien tester.',
    );
  }

  void _handleVoiceCommand(String command) {
    if (command == 'face_screen_test') {
      if (_mode == FaceRecognitionMode.recognition) {
        unawaited(_recognizeNow());
      } else if (_mode == FaceRecognitionMode.adding) {
        unawaited(_speak(
          'Vous êtes dans le mode ajout. Dites annuler ou retour pour revenir à l’écran principal, puis dites tester.',
        ));
      }
      return;
    }

    if (command == 'face_screen_cancel') {
      unawaited(_onVoiceCancel());
      return;
    }

    if (command == 'add_person') {
      unawaited(_startAddingPerson());
    } else if (command == 'who_is_there') {
      unawaited(_recognizeNow());
    } else if (command == 'list_persons') {
      unawaited(_listAllPersons());
    }
  }

  Future<void> _onVoiceCancel() async {
    if (_mode == FaceRecognitionMode.adding) {
      if (!mounted) return;
      setState(() {
        _mode = FaceRecognitionMode.recognition;
        _addingName = null;
        _addingRelation = null;
        _capturedPhotos.clear();
        _nameController.clear();
        _relationController.clear();
      });
      _startRecognition();
      await _speak(
        'Ajout annulé. Bouton Ajouter et bouton Tester sont à nouveau disponibles en bas de l’écran. '
        'Vous pouvez dire ajouter ou tester.',
      );
      return;
    }

    if (_mode == FaceRecognitionMode.testing) {
      if (!mounted) return;
      setState(() {
        _showTestDetails = false;
        _mode = FaceRecognitionMode.recognition;
      });
      _startRecognition();
      await _speak('Test fermé. La reconnaissance automatique reprend.');
      return;
    }

    await _speak('Rien à annuler.');
  }

  Future<void> _startAddingPerson() async {
    setState(() {
      _mode = FaceRecognitionMode.adding;
      _addingName = null;
      _addingRelation = null;
      _capturedPhotos.clear();
      _nameController.clear();
      _relationController.clear();
    });

    await _speak('Mode ajout activé. Entrez le nom et la relation, ou utilisez la commande vocale.');
  }

  Future<void> _startAddingPersonWithForm() async {
    final name = _nameController.text.trim();
    final relation = _relationController.text.trim();

    if (name.isEmpty) {
      await _speak('Veuillez entrer un nom');
      return;
    }

    if (relation.isEmpty) {
      await _speak('Veuillez entrer une relation');
      return;
    }

    if (await _faceService.personExists(name)) {
      await _speak(
        'Une personne nommée $name est déjà enregistrée. Utilisez un autre nom pour éviter les doublons.',
      );
      return;
    }

    setState(() {
      _addingName = name;
      _addingRelation = relation;
    });

    await _speak('Nom: $name, Relation: $relation. Positionnez la caméra vers le visage et appuyez sur Capturer les photos.');
  }


  Future<void> _startPhotoCapture() async {
    if (_addingName == null || _addingRelation == null) {
      await _speak('Veuillez d\'abord entrer le nom et la relation');
      return;
    }

    setState(() => _isCapturing = true);
    await _speak('Début de la capture. Positionnez la caméra vers le visage.');
    await Future.delayed(const Duration(seconds: 1));
    await _capturePhotos();
  }

  Future<void> _capturePhotos() async {
    _capturedPhotos.clear();

    for (int i = 0; i < _photosToCapture; i++) {
      if (!mounted || _controller == null) break;

      try {
        final image = await _controller!.takePicture();
        final bytes = await image.readAsBytes();
        _capturedPhotos.add(bytes);

        if (i < _photosToCapture - 1) {
          final directions = [
            'Photo ${i + 1} capturée. Tournez légèrement à gauche.',
            'Photo ${i + 1} capturée. Tournez à droite.',
            'Photo ${i + 1} capturée. Regardez vers le haut.',
          ];
          await _speak(directions[i % directions.length]);
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        await _speak('Erreur lors de la capture: $e');
        break;
      }
    }

    await _speak('Toutes les photos sont capturées. Traitement en cours...');
    await _processAndSavePerson();
  }

  Future<void> _processAndSavePerson() async {
    if (_addingName == null || _addingRelation == null) return;

    final List<List<double>> embeddings = [];

    for (final photoBytes in _capturedPhotos) {
      final encodingResult = await _faceAiService.encodeFace(photoBytes);
      if (encodingResult.success && encodingResult.embedding != null) {
        embeddings.add(encodingResult.embedding!);
      }
    }

    if (embeddings.isEmpty) {
      await _speak('Erreur: Impossible de générer les embeddings. Réessayez.');
      setState(() {
        _mode = FaceRecognitionMode.recognition;
        _isCapturing = false;
      });
      return;
    }

    if (await _faceService.personExists(_addingName!)) {
      await _speak(
        'Cette personne existe déjà dans la base. Enregistrement annulé pour éviter un doublon.',
      );
      setState(() {
        _mode = FaceRecognitionMode.recognition;
        _isCapturing = false;
        _addingName = null;
        _addingRelation = null;
        _capturedPhotos.clear();
      });
      _startRecognition();
      return;
    }

    await _faceService.addPerson(_addingName!, _addingRelation!, embeddings);
    await _speak('$_addingName a été ajouté avec succès comme $_addingRelation.');

    setState(() {
      _mode = FaceRecognitionMode.recognition;
      _isCapturing = false;
      _addingName = null;
      _addingRelation = null;
      _capturedPhotos.clear();
    });

    _startRecognition();
  }

  void _startRecognition() {
    _recognitionTimer?.cancel();
    _recognitionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isAnalyzing && _mode == FaceRecognitionMode.recognition) {
        _recognizeCurrentFrame();
      }
    });
  }

  Future<void> _recognizeCurrentFrame() async {
    if (_controller == null || _isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      // Détecter le visage
      final detection = await _faceAiService.detectFace(bytes);
      if (!detection.faceDetected) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // Générer l'embedding
      final encoding = await _faceAiService.encodeFace(bytes);
      if (!encoding.success || encoding.embedding == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // Reconnaître (avec seuil très permissif)
      final recognition = await _faceService.recognizeFace(encoding.embedding!, threshold: 0.9);

      // Détecter l'émotion
      final emotion = await _faceAiService.detectEmotion(bytes);

      if (recognition != null && recognition.recognized) {
        final announcement = 'C\'est ${recognition.relation} ${recognition.personName}';
        final emotionText = emotion.emotionInFrench;

        // Éviter les répétitions trop fréquentes (sauf en mode test)
        final now = DateTime.now();
        if (_mode == FaceRecognitionMode.testing ||
            _lastRecognizedPerson != recognition.personName ||
            _lastAnnouncement == null ||
            now.difference(_lastAnnouncement!).inSeconds > 5) {
          await _speak('$announcement, $emotionText');
          setState(() {
            _lastRecognizedPerson = recognition.personName;
            _lastAnnouncement = now;
          });
        }
      } else {
        // Visiteur inconnu
        final now = DateTime.now();
        if (_mode == FaceRecognitionMode.testing ||
            _lastAnnouncement == null ||
            now.difference(_lastAnnouncement!).inSeconds > 10) {
          await _speak('Visiteur inconnu devant vous');
          setState(() => _lastAnnouncement = now);
        }
      }
    } catch (e) {
      // Ignore errors silently
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _recognizeNow() async {
    setState(() {
      _mode = FaceRecognitionMode.testing;
      _showTestDetails = true;
    });
    _recognitionTimer?.cancel();
    await _speak('Scan de reconnaissance en cours. Restez immobile face à la caméra...');
    
    // Faire plusieurs scans pour améliorer la précision
    await _scanMultipleTimes();
  }

  Future<void> _scanMultipleTimes() async {
    final List<FaceTestResult> results = [];
    
    // Faire 3 scans rapides
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await _performSingleScan();
      if (result != null) {
        results.add(result);
      }
    }

    // Prendre le meilleur résultat (distance la plus faible)
    if (results.isNotEmpty) {
      results.sort((a, b) => a.distance.compareTo(b.distance));
      final bestResult = results.first;
      
      setState(() {
        _lastTestResult = bestResult;
        _isAnalyzing = false;
      });

      // Annonce vocale
      if (bestResult.recognized && bestResult.personName != null) {
        final confidencePercent = (bestResult.confidence * 100).toInt();
        await _speak(
          'Reconnu: ${bestResult.personName}, ${bestResult.relation}. Confiance: $confidencePercent pourcent.',
        );
      } else {
        final bestMatch = bestResult.allMatches.isNotEmpty ? bestResult.allMatches.first : null;
        if (bestMatch != null) {
          await _speak(
            'Non reconnu. Meilleur match: ${bestMatch.personName} avec distance ${bestMatch.distance.toStringAsFixed(3)}. Essayez de mieux vous positionner face à la caméra.',
          );
        } else {
          await _speak('Aucun match trouvé. Vérifiez que vous êtes bien enregistré dans la base.');
        }
      }
    } else {
      await _speak('Erreur: Impossible de scanner le visage. Vérifiez la caméra.');
      setState(() => _isAnalyzing = false);
    }
  }

  Future<FaceTestResult?> _performSingleScan() async {
    if (_controller == null) return null;

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      final detection = await _faceAiService.detectFace(bytes);
      if (!detection.faceDetected) return null;

      final encoding = await _faceAiService.encodeFace(bytes);
      if (!encoding.success || encoding.embedding == null) return null;

      return await _faceService.testRecognition(encoding.embedding!, threshold: 0.98);
    } catch (e) {
      return null;
    }
  }

  Future<void> _testRecognitionWithDetails() async {
    if (_controller == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      // Détecter le visage
      final detection = await _faceAiService.detectFace(bytes);
      if (!detection.faceDetected) {
        await _speak('Aucun visage détecté. Positionnez-vous face à la caméra.');
        setState(() {
          _isAnalyzing = false;
          _lastTestResult = null;
        });
        return;
      }

      // Générer l'embedding
      final encoding = await _faceAiService.encodeFace(bytes);
      if (!encoding.success || encoding.embedding == null) {
        await _speak('Erreur: Impossible de générer l\'embedding du visage.');
        setState(() {
          _isAnalyzing = false;
          _lastTestResult = FaceTestResult(
            recognized: false,
            confidence: 0.0,
            distance: 1.0,
            threshold: 0.6,
            faceDetected: true,
            embeddingGenerated: false,
            totalPersons: 0,
            totalEmbeddings: 0,
            allMatches: [],
          );
        });
        return;
      }

      // Test détaillé avec statistiques (seuil très permissif pour le test)
      final testResult = await _faceService.testRecognition(encoding.embedding!, threshold: 0.95);

      setState(() {
        _lastTestResult = testResult;
        _isAnalyzing = false;
      });

      // Annonce vocale détaillée
      if (testResult.recognized && testResult.personName != null) {
        final confidencePercent = (testResult.confidence * 100).toInt();
        await _speak(
          'Reconnu: ${testResult.personName}, ${testResult.relation}. Confiance: $confidencePercent pourcent. Distance: ${testResult.distance.toStringAsFixed(3)}.',
        );
      } else {
        if (testResult.totalPersons == 0) {
          await _speak('Aucune personne enregistrée dans la base de données.');
        } else {
          final bestMatch = testResult.allMatches.isNotEmpty ? testResult.allMatches.first : null;
          if (bestMatch != null) {
            final distanceStr = bestMatch.distance.toStringAsFixed(3);
            final thresholdStr = testResult.threshold.toStringAsFixed(3);
            await _speak(
              'Personne non reconnue. Meilleur match: ${bestMatch.personName} avec distance $distanceStr. Seuil requis: $thresholdStr. Distance trop élevée pour être reconnu.',
            );
          } else {
            await _speak('Personne non reconnue. Aucun match trouvé.');
          }
        }
      }
    } catch (e) {
      await _speak('Erreur lors du test: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _listAllPersons() async {
    final persons = await _faceService.getAllPersons();
    if (persons.isEmpty) {
      await _speak('Aucune personne enregistrée.');
      return;
    }

    final names = persons.map((p) => '${p.name}, ${p.relation}').join(', ');
    await _speak('Personnes enregistrées: $names');
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Délai pour éviter les conflits
      await _tts.speak(text);
    } catch (e) {
      // Ignorer les erreurs TTS pour garder l'UI responsive
      print('TTS Error: $e');
    }
  }

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    _voiceTimer?.cancel();
    _controller?.dispose();
    _tts.stop();
    _speech.stop();
    _voiceCommandService.dispose();
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initialisation de la caméra...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('M3AK Visage')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('M3AK Visage'),
        actions: [
          if (_mode == FaceRecognitionMode.adding)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _mode = FaceRecognitionMode.recognition;
                  _addingName = null;
                  _addingRelation = null;
                  _capturedPhotos.clear();
                });
                _startRecognition();
              },
              tooltip: 'Annuler',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            CameraPreview(_controller!),
          
          // Formulaire d'ajout
          if (_mode == FaceRecognitionMode.adding)
            Container(
              color: Colors.black87,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 80, color: Colors.white),
                      const SizedBox(height: 30),
                      const Text(
                        'Ajouter une personne',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom de la personne',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _relationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Relation (ex: ma fille, mon ami)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _startAddingPersonWithForm,
                        icon: const Icon(Icons.check),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_addingName != null && _addingRelation != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Nom: $_addingName\nRelation: $_addingRelation',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (_isCapturing)
                          Text(
                            'Capture: ${_capturedPhotos.length}/$_photosToCapture',
                            style: const TextStyle(color: Colors.yellow, fontSize: 18),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _startPhotoCapture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capturer les photos'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Indicateur de reconnaissance/test
          if ((_mode == FaceRecognitionMode.recognition || _mode == FaceRecognitionMode.testing) && _isAnalyzing)
            const Positioned(
              top: 20,
              left: 20,
              child: Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Analyse...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Panneau de détails du test
          if (_mode == FaceRecognitionMode.testing && _lastTestResult != null && _showTestDetails)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Résultats du Test',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _showTestDetails = false;
                                _mode = FaceRecognitionMode.recognition;
                                _startRecognition();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTestStat('Statut', _lastTestResult!.recognized ? '✅ Reconnu' : '❌ Non reconnu', _lastTestResult!.recognized ? Colors.green : Colors.red),
                      if (_lastTestResult!.recognized) ...[
                        _buildTestStat('Personne', '${_lastTestResult!.personName} (${_lastTestResult!.relation})', Colors.blue),
                        _buildTestStat('Confiance', '${(_lastTestResult!.confidence * 100).toStringAsFixed(1)}%', Colors.green),
                      ],
                      _buildTestStat('Distance', _lastTestResult!.distance.toStringAsFixed(4), Colors.orange),
                      _buildTestStat('Seuil', _lastTestResult!.threshold.toStringAsFixed(4), Colors.yellow),
                      _buildTestStat('Base de données', '${_lastTestResult!.totalPersons} personne(s), ${_lastTestResult!.totalEmbeddings} embedding(s)', Colors.cyan),
                      if (_lastTestResult!.allMatches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Top 3 matches:',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._lastTestResult!.allMatches.take(3).map((match) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                match.personName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Distance: ${match.distance.toStringAsFixed(4)} (${(match.confidence * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: match.distance < _lastTestResult!.threshold ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Boutons flottants (sans Hero pour éviter l'erreur)
          if (_mode == FaceRecognitionMode.recognition)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Semantics(
                    button: true,
                    label: 'Ajouter une personne',
                    hint: 'Enregistrer un nouveau visage dans la base',
                    child: ElevatedButton.icon(
                      onPressed: _startAddingPerson,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Tester la reconnaissance',
                    hint: 'Lance un scan vocal et détaillé du visage devant la caméra',
                    child: ElevatedButton.icon(
                      onPressed: _recognizeNow,
                      icon: const Icon(Icons.search),
                      label: const Text('Tester'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

