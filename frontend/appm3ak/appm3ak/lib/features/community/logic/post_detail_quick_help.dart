import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/create_help_request_input.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/community_providers.dart';

/// Aide rapide depuis le detail d'un post : envoi d'une demande avec position, sans formulaire complet.
Future<String?> submitQuickHelpFromPost(WidgetRef ref, PostModel post) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return 'Activez la localisation pour envoyer une aide rapide.';
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return 'Autorisez la localisation pour envoyer votre position.';
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return 'Localisation refusee. Modifiez les parametres de l\'application.';
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );

  final excerpt = post.contenu.replaceAll(RegExp(r'\s+'), ' ').trim();
  final short =
      excerpt.length > 200 ? '${excerpt.substring(0, 200)}…' : excerpt;
  final desc = 'Aide rapide depuis un post (parcours court).\n'
      'Reference post : ${post.id}\n\n'
      '${short.isEmpty ? '(post sans texte)' : short}';

  try {
    await ref.read(
      createHelpRequestProvider(
        CreateHelpRequestInput(
          description: desc,
          latitude: pos.latitude,
          longitude: pos.longitude,
          inputMode: 'tap',
          presetMessageKey: 'blocked',
          helpType: 'mobility',
        ),
      ).future,
    );
    return null;
  } catch (e) {
    return e.toString();
  }
}
