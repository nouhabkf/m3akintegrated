import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class GestureRecognitionService {
  CameraController? _cameraController;
  bool _isInitialized = false;
  Function(String)? onError;

  Future<bool> initialize() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        onError?.call('Permission caméra non accordée');
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('Aucune caméra disponible');
        return false;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      onError?.call('Erreur: $e');
      return false;
    }
  }

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _isInitialized = false;
  }
}