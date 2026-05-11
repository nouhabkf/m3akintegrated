// Implémentation TFLite locale uniquement hors web (dart:ffi requis).
// Sur Chrome / navigateur, le stub sans FFI est utilisé automatiquement.
export 'face_tflite_service_stub.dart'
    if (dart.library.io) 'face_tflite_service_io.dart';
