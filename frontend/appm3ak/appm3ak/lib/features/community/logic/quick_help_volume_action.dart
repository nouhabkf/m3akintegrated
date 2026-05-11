import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/create_help_request_input.dart';
import '../../../providers/community_providers.dart';

/// Texte de la demande créée via la touche volume+ (onglet Aides).
const String kVolumeShortcutHelpDescription =
    'Demande d\'aide envoyée depuis l\'onglet Demandes d\'aide (touche volume+).';

/// Envoie une demande d’aide avec la position GPS actuelle. Retourne null si succès, sinon un message d’erreur.
Future<String?> submitQuickHelpWithCurrentLocation(WidgetRef ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return 'Activez la localisation dans les paramètres du téléphone.';
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return 'Autorisez la localisation pour envoyer votre position.';
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return 'Localisation refusée. Modifiez les paramètres de l’application.';
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );

  try {
    await ref.read(
      createHelpRequestProvider(
        CreateHelpRequestInput(
          description: kVolumeShortcutHelpDescription,
          latitude: pos.latitude,
          longitude: pos.longitude,
          inputMode: 'volume_shortcut',
        ),
      ).future,
    );
    return null;
  } catch (e) {
    return e.toString();
  }
}
