import '../../../data/models/post_model.dart';

/// Message d’alerte si le contenu ou les métadonnées suggèrent un risque.
String? postDetailDangerBannerMessage(PostModel post) {
  if (post.obstaclePresent) {
    return 'Obstacle ou accès difficile signalé sur ce contenu. '
        'Soyez prudent et utilisez l’aide rapide si vous êtes sur place.';
  }
  final t = '${post.contenu} ${post.postNature ?? ''}'
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e');
  const keys = <String, String>{
    'escalier': 'escalier',
    'danger': 'danger',
    'bloque': 'bloque',
    'urgence': 'urgence',
    'panne': 'panne',
    'glissant': 'sol glissant',
    'chute': 'chute',
  };
  for (final e in keys.entries) {
    if (t.contains(e.key)) {
      return 'Ce message évoque un risque ou une situation difficile '
          '(repère : ${e.value}). '
          'Vérifiez votre sécurité et demandez de l’aide si nécessaire.';
    }
  }
  return null;
}
