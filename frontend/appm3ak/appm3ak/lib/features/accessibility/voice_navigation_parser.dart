/// Commandes reconnues pour la navigation vocale (FR + variantes).
enum VoiceNavCommand {
  home,
  health,
  transport,
  community,
  communityPosts,
  communityPlaces,
  communityProches,
  communityHelp,
  profile,
  createPost,
  createHelpRequest,
  sosTactile,
  sosAlerts,
  emergencyContacts,
  submitPlace,
  back,
  stop,
  unknown,
}

/// Analyse le texte issu de la reconnaissance vocale.
class VoiceNavigationParser {
  VoiceNavigationParser._();

  static String _normalize(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll(RegExp(r"[''`´]"), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    const pairs = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ù': 'u',
      'û': 'u',
      'ô': 'o',
      'î': 'i',
      'ï': 'i',
      'ç': 'c',
    };
    pairs.forEach((k, v) => t = t.replaceAll(k, v));
    return t;
  }

  static bool _wordish(String t, String word) {
    if (t == word) return true;
    if (t.contains(' $word ')) return true;
    if (t.startsWith('$word ')) return true;
    if (t.endsWith(' $word')) return true;
    if (t.endsWith(' $word.')) return true;
    return t.contains('$word,') || t.contains('$word.');
  }

  static VoiceNavCommand parse(String raw) {
    if (raw.isEmpty) return VoiceNavCommand.unknown;
    final t = _normalize(raw);

    if (_stop(t)) return VoiceNavCommand.stop;
    if (_back(t)) return VoiceNavCommand.back;

    if (_createPost(t)) return VoiceNavCommand.createPost;
    if (_profile(t)) return VoiceNavCommand.profile;

    if (_sosTactile(t)) return VoiceNavCommand.sosTactile;
    if (_sosAlerts(t)) return VoiceNavCommand.sosAlerts;

    if (_communityHelp(t)) return VoiceNavCommand.communityHelp;
    if (_createHelpRequest(t)) return VoiceNavCommand.createHelpRequest;
    if (_emergencyContacts(t)) return VoiceNavCommand.emergencyContacts;
    if (_submitPlace(t)) return VoiceNavCommand.submitPlace;

    if (_community(t)) return VoiceNavCommand.community;
    if (_communityProches(t)) return VoiceNavCommand.communityProches;
    if (_communityPosts(t)) return VoiceNavCommand.communityPosts;
    if (_communityPlaces(t)) return VoiceNavCommand.communityPlaces;

    if (_transport(t)) return VoiceNavCommand.transport;
    if (_health(t)) return VoiceNavCommand.health;
    if (_home(t)) return VoiceNavCommand.home;

    return VoiceNavCommand.unknown;
  }

  static bool _back(String t) {
    return t == 'retour' ||
        t.contains('retour en arriere') ||
        t.contains('precedent') ||
        t.contains('page precedente') ||
        t.contains('revenir');
  }

  static bool _stop(String t) {
    return t.contains('stop') ||
        t.contains('arrete') ||
        t.contains('arret') ||
        t.contains('ferme') ||
        t.contains('fermer') ||
        t.contains('quitte') ||
        t == 'merci';
  }

  static bool _createPost(String t) {
    if (t.contains('publier')) return true;
    if (t.contains('raconter')) return true;
    if (t.contains('partager')) return true;
    if (t.contains('ecrire') &&
        (t.contains('message') || t.contains('quelque chose'))) {
      return true;
    }
    return (t.contains('creer') && (t.contains('post') || t.contains('poste'))) ||
        (t.contains('nouveau') && (t.contains('post') || t.contains('poste'))) ||
        (t.contains('ajouter') && (t.contains('post') || t.contains('poste')));
  }

  static bool _profile(String t) {
    return t.contains('profil') ||
        t.contains('mon compte') ||
        t.contains('parametre') ||
        t.contains('reglage');
  }

  static bool _communityHelp(String t) {
    return (t.contains('demande') && t.contains('aide')) ||
        t.contains('demandes d aide') ||
        t.contains('aide communautaire');
  }

  static bool _createHelpRequest(String t) {
    return (t.contains('creer') && t.contains('demande') && t.contains('aide')) ||
        (t.contains('demander') && t.contains('aide')) ||
        (t.contains('besoin') && t.contains('aide'));
  }

  static bool _sosTactile(String t) {
    return t.contains('sos tactile') ||
        (t.contains('aide') && t.contains('tactile')) ||
        (t.contains('toucher') && t.contains('sos')) ||
        (t.contains('urgence') && t.contains('tactile'));
  }

  static bool _sosAlerts(String t) {
    return t.contains('aidez moi') ||
        t.contains('aidez-moi') ||
        t.contains('au secours') ||
        t.contains('danger') ||
        (t.contains('alerte') && t.contains('sos')) ||
        t.contains('alertes sos') ||
        t == 'sos';
  }

  static bool _emergencyContacts(String t) {
    return (t.contains('contact') && t.contains('urgence')) ||
        t.contains('accompagnants') ||
        (t.contains('proche') && t.contains('appeler'));
  }

  static bool _submitPlace(String t) {
    return (t.contains('ajouter') && t.contains('lieu')) ||
        (t.contains('proposer') && t.contains('lieu')) ||
        t.contains('nouveau lieu');
  }

  static bool _communityPosts(String t) {
    if (_createPost(t)) return false;
    if (t.contains('forum')) return true;
    if (t.contains('publication') || t.contains('publications')) return true;
    if (t.contains('discussions')) return true;
    if (t.contains('fil d actualite')) return true;
    if (t.contains('poste') || t.contains('postes')) return true;
    if (_wordish(t, 'post') || _wordish(t, 'posts')) return true;
    return false;
  }

  static bool _communityPlaces(String t) {
    if (_community(t)) return false;
    return t.contains('lieux') ||
        t.contains('lieu accessible') ||
        t.contains('carte') ||
        t.contains('adresse');
  }

  static bool _communityProches(String t) {
    if (t.contains('proches')) return true;
    if (t.contains('proche')) return true;
    if (t.contains('cercle de confiance')) return true;
    if (t.contains('amis')) return true;
    if (t.contains('famille')) return true;
    if (_wordish(t, 'proches') || _wordish(t, 'proche')) return true;
    return false;
  }

  static bool _community(String t) {
    if (t.contains('communaute')) return true;
    if (t.contains('milieux') || t.contains('milieu')) return true;
    if (t.contains('millieux') || t.contains('millieu')) return true;
    if (t.contains('mi lieu')) return true;
    if (t.contains('onglet milieux')) return true;
    if (t.contains('voisinage')) return true;
    if (_wordish(t, 'milieux') || _wordish(t, 'milieu')) return true;
    return false;
  }

  static bool _transport(String t) {
    return t.contains('transport') ||
        t.contains('bus') ||
        t.contains('trajet') ||
        t.contains('deplacement');
  }

  static bool _health(String t) {
    return t.contains('sante') ||
        t.contains('medical') ||
        t.contains('docteur') ||
        t.contains('chat sante');
  }

  static bool _home(String t) {
    return t.contains('accueil') ||
        t.contains('home') ||
        t.contains('principal') ||
        t.contains('debut') ||
        t.contains('maison');
  }
}
