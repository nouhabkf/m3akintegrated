import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:appm3ak/m3ak_port/models/face_detection_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Reconnaissance faciale locale via [face_model.tflite] + ML Kit (détection).
/// Non utilisé sur **web** (voir [face_tflite_service_stub.dart]).
class FaceTfliteService {
  FaceTfliteService();

  static const String assetPath = 'assets/models/face_model.tflite';

  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  bool _initAttempted = false;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> initialize() async {
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
        ),
      );
      _ready = true;
    } catch (e, st) {
      debugPrint('FaceTfliteService: impossible de charger le modèle ($e)\n$st');
      _ready = false;
    }
  }

  Future<void> dispose() async {
    await _faceDetector?.close();
    _faceDetector = null;
    _interpreter?.close();
    _interpreter = null;
    _ready = false;
    _initAttempted = false;
  }

  Future<InputImage> _jpegToInputImage(Uint8List jpegBytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/m3ak_face_input.jpg');
    await file.writeAsBytes(jpegBytes);
    return InputImage.fromFilePath(file.path);
  }

  Future<FaceDetectionResult> detectFace(Uint8List imageBytes) async {
    if (!_ready || _faceDetector == null) {
      return FaceDetectionResult(faceDetected: false);
    }
    try {
      final inputImage = await _jpegToInputImage(imageBytes);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        return FaceDetectionResult(faceDetected: false);
      }
      final f = faces.first;
      return FaceDetectionResult(
        faceDetected: true,
        confidence: f.headEulerAngleY?.abs() != null
            ? (1.0 - (f.headEulerAngleY!.abs() / 90.0)).clamp(0.0, 1.0)
            : 1.0,
        boundingBox: [
          f.boundingBox.left.toInt(),
          f.boundingBox.top.toInt(),
          f.boundingBox.width.toInt(),
          f.boundingBox.height.toInt(),
        ],
      );
    } catch (e) {
      debugPrint('FaceTfliteService.detectFace: $e');
      return FaceDetectionResult(faceDetected: false);
    }
  }

  Future<FaceEncodingResult> encodeFace(Uint8List imageBytes) async {
    if (!_ready || _interpreter == null || _faceDetector == null) {
      return FaceEncodingResult(
        success: false,
        error: 'Modèle TFLite non chargé',
      );
    }

    img.Image? decoded;
    try {
      decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        return FaceEncodingResult(success: false, error: 'Image invalide');
      }

      final inputImage = await _jpegToInputImage(imageBytes);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        return FaceEncodingResult(success: false, error: 'Aucun visage détecté');
      }

      final face = faces.reduce(
        (a, b) => a.boundingBox.width * a.boundingBox.height >=
                b.boundingBox.width * b.boundingBox.height
            ? a
            : b,
      );

      final cropped = _cropFace(decoded, face.boundingBox);
      final inputTensor = _interpreter!.getInputTensor(0);
      final shape = List<int>.from(inputTensor.shape);
      final isFloat = inputTensor.type == TensorType.float32 ||
          inputTensor.type == TensorType.float16;

      final input = _allocateTensor(shape, floatLeaf: isFloat);
      _fillInputFromImage(
        input: input,
        shape: shape,
        image: cropped,
        asFloat: isFloat,
      );

      final outTensor = _interpreter!.getOutputTensor(0);
      final outShape = List<int>.from(outTensor.shape);
      final outFloat = outTensor.type == TensorType.float32 ||
          outTensor.type == TensorType.float16;
      final output = _allocateTensor(outShape, floatLeaf: outFloat);

      _interpreter!.run(input, output);

      var embedding = _flattenToDoubleList(output);
      if (embedding.isEmpty) {
        return FaceEncodingResult(success: false, error: 'Sortie modèle vide');
      }
      embedding = _l2Normalize(embedding);

      return FaceEncodingResult(success: true, embedding: embedding);
    } catch (e, st) {
      debugPrint('FaceTfliteService.encodeFace: $e\n$st');
      return FaceEncodingResult(success: false, error: e.toString());
    }
  }

  img.Image _cropFace(img.Image source, Rect box) {
    var left = box.left.floor();
    var top = box.top.floor();
    var w = box.width.ceil();
    var h = box.height.ceil();
    final pad = (math.max(w, h) * 0.12).round();
    left = (left - pad).clamp(0, source.width - 1);
    top = (top - pad).clamp(0, source.height - 1);
    w = (w + 2 * pad).clamp(1, source.width - left);
    h = (h + 2 * pad).clamp(1, source.height - top);
    return img.copyCrop(source, x: left, y: top, width: w, height: h);
  }

  dynamic _allocateTensor(List<int> shape, {required bool floatLeaf}) {
    if (shape.isEmpty) return null;
    if (shape.length == 1) {
      return floatLeaf
          ? List<double>.filled(shape[0], 0.0)
          : List<int>.filled(shape[0], 0);
    }
    return List.generate(
      shape[0],
      (_) => _allocateTensor(shape.sublist(1), floatLeaf: floatLeaf),
    );
  }

  void _fillInputFromImage({
    required dynamic input,
    required List<int> shape,
    required img.Image image,
    required bool asFloat,
  }) {
    if (shape.length == 4) {
      final b = shape[0];
      final d1 = shape[1];
      final d2 = shape[2];
      final d3 = shape[3];
      if (d3 == 3) {
        final h = d1;
        final w = d2;
        final resized = img.copyResize(
          image,
          width: w,
          height: h,
          interpolation: img.Interpolation.linear,
        );
        for (var bi = 0; bi < b; bi++) {
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final p = resized.getPixel(x, y);
              final r = p.r.toDouble();
              final g = p.g.toDouble();
              final bch = p.b.toDouble();
              if (asFloat) {
                (input as List)[bi][y][x][0] = _normFace(r);
                input[bi][y][x][1] = _normFace(g);
                input[bi][y][x][2] = _normFace(bch);
              } else {
                (input as List)[bi][y][x][0] = r.clamp(0, 255).round();
                input[bi][y][x][1] = g.clamp(0, 255).round();
                input[bi][y][x][2] = bch.clamp(0, 255).round();
              }
            }
          }
        }
        return;
      }
      if (d1 == 3) {
        final h = d2;
        final w = d3;
        final resized = img.copyResize(
          image,
          width: w,
          height: h,
          interpolation: img.Interpolation.linear,
        );
        for (var bi = 0; bi < b; bi++) {
          for (var c = 0; c < 3; c++) {
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                final p = resized.getPixel(x, y);
                final v = c == 0 ? p.r : (c == 1 ? p.g : p.b);
                final vd = v.toDouble();
                if (asFloat) {
                  (input as List)[bi][c][y][x] = _normFace(vd);
                } else {
                  input[bi][c][y][x] = vd.clamp(0, 255).round();
                }
              }
            }
          }
        }
        return;
      }
    }
    throw StateError('Forme d\'entrée non supportée: $shape');
  }

  double _normFace(double channel255) {
    return (channel255 / 127.5) - 1.0;
  }

  List<double> _flattenToDoubleList(dynamic o) {
    final out = <double>[];
    void walk(dynamic v) {
      if (v is double) {
        out.add(v);
      } else if (v is int) {
        out.add(v.toDouble());
      } else if (v is Float32List) {
        out.addAll(v);
      } else if (v is List) {
        for (final e in v) {
          walk(e);
        }
      }
    }

    walk(o);
    return out;
  }

  List<double> _l2Normalize(List<double> v) {
    double s = 0;
    for (final x in v) {
      s += x * x;
    }
    final n = math.sqrt(s);
    if (n < 1e-12) return v;
    return v.map((e) => e / n).toList();
  }
}
