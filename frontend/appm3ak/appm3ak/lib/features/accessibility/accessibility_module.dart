/// Module accessibilité M3ak (carte OSM, scores IA, itinéraires, réservations).
/// Extrait et découpé depuis le `main.dart` du projet standalone m3ak.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'accessibility_ai_service.dart';
import 'ai_score_widget.dart';
import 'screens/reservations_history_screen.dart';
import 'services/accessible_route_service.dart';

part 'accessibility_module_models_directions.dart';
part 'accessibility_module_screen.dart';
part 'accessibility_module_widgets.dart';
