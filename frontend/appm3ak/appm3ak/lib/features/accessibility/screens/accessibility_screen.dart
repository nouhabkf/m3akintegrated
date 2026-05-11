import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import '../accessibility_ai_service.dart';
import '../ai_score_widget.dart';

/// Géocode un libellé lieu via l’API publique Nominatim (OSM).
/// Les coordonnées sont requises par [AccessibilityAIService.analyze].
Future<({double lat, double lon})?> _geocodePlace(String query) async {
  final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
    queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '1',
    },
  );
  try {
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'M3akAccessibilityScreen/1.0',
        'Accept-Language': 'fr',
      },
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final list = jsonDecode(response.body);
    if (list is! List<dynamic> || list.isEmpty) return null;
    final first = list.first;
    if (first is! Map<String, dynamic>) return null;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon);
  } catch (_) {
    return null;
  }
}

/// Onglet **Lieux** : recherche d’un lieu et analyse d’accessibilité IA.
class AccessibilityScreen extends ConsumerStatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  ConsumerState<AccessibilityScreen> createState() =>
      _AccessibilityScreenState();
}

class _AccessibilityScreenState extends ConsumerState<AccessibilityScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  AIAccessibilityResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _result = null;
    });

    final coords = await _geocodePlace(query);
    if (!mounted) return;

    if (coords == null) {
      setState(() {
        _loading = false;
        _errorMessage =
            'Impossible de localiser ce lieu (réseau indisponible ou aucun résultat). '
            'Vérifiez l’orthographe ou ajoutez la ville.';
      });
      return;
    }

    final iaOnline = await AccessibilityAIService.isBackendOnline();
    if (!mounted) return;

    if (!iaOnline) {
      setState(() {
        _loading = false;
        _errorMessage =
            'Le serveur d’analyse IA sur http://127.0.0.1:8000 est hors ligne. '
            'Démarrez le backend, puis réessayez.';
      });
      return;
    }

    final result = await AccessibilityAIService.analyze(
      placeName: query,
      latitude: coords.lat,
      longitude: coords.lon,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result == null) {
        _result = null;
        _errorMessage =
            'L’analyse n’a pas pu aboutir (réponse vide ou erreur du serveur IA).';
      } else {
        _errorMessage = null;
        _result = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.navLieux),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Nom du lieu',
                hintText: 'Ex. Gare de Tunis, Tunis',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Analyser',
                  icon: const Icon(Icons.search),
                  onPressed: _loading ? null : _runAnalysis,
                ),
              ),
              onSubmitted: (_) {
                if (!_loading) _runAnalysis();
              },
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AIScoreWidget(
              result: _result,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
