import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accessibility_module.dart';

/// Point d’entrée onglet **Lieux** : carte OSM, itinéraires accessibles, réservations, contributions.
class AccessibilityLieuxHubScreen extends StatelessWidget {
  const AccessibilityLieuxHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1A237E);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux accessibles'),
        foregroundColor: Colors.white,
        backgroundColor: brand,
        actions: [
          IconButton(
            tooltip: 'Mes réservations',
            icon: const Icon(Icons.event_note_rounded),
            onPressed: () => context.push('/reservations-history'),
          ),
        ],
      ),
      body: const AccessibilityModuleScreen(),
    );
  }
}
