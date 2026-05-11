import 'package:appm3ak/m3ak_port/models/sign_phrase_analysis.dart';

class SignPhraseAiService {
  const SignPhraseAiService();

  SignPhraseAnalysis analyzeTextToSigns(String rawText) {
    final normalized = _normalizeForLearning(rawText);
    final plainInput = _plain(rawText);
    final tokens = _tokenizeWords(plainInput);

    if (tokens.isEmpty) {
      return const SignPhraseAnalysis(
        normalizedText: '',
        translatedText: '',
        detectedContext: 'Aucun',
        confidence: 0,
        gestures: [],
        tips: ['Ecris une phrase pour obtenir une proposition de gestes.'],
      );
    }

    final gestures = <String>[];
    final unknownWords = <String>[];

    var i = 0;
    while (i < tokens.length) {
      if (i + 1 < tokens.length) {
        final pair = '${tokens[i]} ${tokens[i + 1]}';
        if (_phraseToGesture.containsKey(pair)) {
          gestures.add(_phraseToGesture[pair]!);
          i += 2;
          continue;
        }
      }

      if (i + 2 < tokens.length) {
        final tri = '${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}';
        if (_phraseToGesture.containsKey(tri)) {
          gestures.add(_phraseToGesture[tri]!);
          i += 3;
          continue;
        }
      }

      final token = tokens[i];
      final mapped = _wordToGesture[token];
      if (mapped != null) {
        gestures.add(mapped);
      } else {
        gestures.add('Epeler: ${token.toUpperCase()}');
        unknownWords.add(token);
      }
      i += 1;
    }

    final knownCount = gestures.length - unknownWords.length;
    final ratio = tokens.isEmpty ? 0 : knownCount / tokens.length;
    final confidence = (55 + (ratio * 40)).round().clamp(35, 96);
    final context = _contextFromGestures(gestures);

    final tips = <String>[
      'La phrase complete est traduite mot par mot.',
      if (unknownWords.isNotEmpty)
        'Mots epeles automatiquement: ${unknownWords.take(4).join(', ')}${unknownWords.length > 4 ? '...' : ''}',
      'Tu peux remplacer un mot par un synonyme pour obtenir un geste plus standard.',
    ];

    return SignPhraseAnalysis(
      normalizedText: normalized,
      translatedText: gestures.join(', '),
      detectedContext: context,
      confidence: confidence,
      gestures: gestures,
      tips: tips,
    );
  }

  SignPhraseAnalysis analyzeSignsToText(String rawSigns) {
    final normalizedInput = _normalizeSignInput(rawSigns);
    if (normalizedInput.isEmpty) {
      return const SignPhraseAnalysis(
        normalizedText: '',
        translatedText: '',
        detectedContext: 'Aucun',
        confidence: 0,
        gestures: [],
        tips: [
          'Ecris une sequence de gestes, ex: Bonjour, Merci, Medecin.',
        ],
      );
    }

    final tokens = normalizedInput
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final words = <String>[];
    final detectedGestures = <String>[];
    for (final token in tokens) {
      final canonical = _canonicalGesture(token);
      if (canonical != null) {
        detectedGestures.add(canonical);
        words.add(_gestureToWord(canonical));
      }
    }

    if (detectedGestures.isEmpty) {
      return SignPhraseAnalysis(
        normalizedText: normalizedInput,
        translatedText: 'Je n ai pas reconnu les gestes.',
        detectedContext: 'Inconnu',
        confidence: 20,
        gestures: const [],
        tips: const [
          'Utilise des gestes connus: Bonjour, Merci, Medecin, Douleur, Taxi...',
          'Separe les gestes avec des virgules.',
        ],
      );
    }

    final sentence = _toSentence(words);
    final context = _contextFromGestures(detectedGestures);
    final confidence = (60 + detectedGestures.length * 8).clamp(0, 96);

    return SignPhraseAnalysis(
      normalizedText: normalizedInput,
      translatedText: sentence,
      detectedContext: context,
      confidence: confidence,
      gestures: detectedGestures,
      tips: const [
        'Tu peux reajuster l ordre des gestes pour une phrase plus naturelle.',
        'Ajoute une expression faciale selon le contexte.',
      ],
    );
  }

  String _normalizeForLearning(String text) {
    final value = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _normalizeSignInput(String text) {
    return text
        .replaceAll('->', ',')
        .replaceAll(';', ',')
        .replaceAll('|', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _plain(String text) {
    return text
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c')
        .trim();
  }

  List<String> _tokenizeWords(String text) {
    final clean = text
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return const [];
    return clean.split(' ').where((w) => w.isNotEmpty).toList();
  }

  String? _canonicalGesture(String token) {
    final t = _plain(token);
    const gestures = {
      'bonjour': 'Bonjour',
      'merci': 'Merci',
      'au revoir': 'Au revoir',
      'au secours': 'Au secours',
      'urgence': 'Urgence',
      'ambulance': 'Ambulance',
      'medecin': 'Médecin',
      'hopital': 'Hôpital',
      'douleur': 'Douleur',
      'taxi': 'Taxi',
      'bus': 'Bus',
      'arret': 'Arrêt',
      'billet': 'Billet',
      'gare': 'Gare',
      'infirmier': 'Infirmier',
      'medicament': 'Médicament',
      'eau': 'Eau',
      'manger': 'Manger',
      'toilettes': 'Toilettes',
      'aide': 'Aide',
      'oui': 'Oui',
      'non': 'Non',
      'je': 'Je',
      'moi': 'Moi',
      'vous': 'Vous',
      'tu': 'Tu',
      'nom': 'Nom',
      'je m appelle': 'Je m appelle',
      'rendez vous': 'Rendez-vous',
      'operation': 'Opération',
    };
    return gestures[t];
  }

  String _gestureToWord(String gesture) {
    switch (gesture) {
      case 'Bonjour':
        return 'bonjour';
      case 'Merci':
        return 'merci';
      case 'Au revoir':
        return 'au revoir';
      case 'Médecin':
        return 'medecin';
      case 'Hôpital':
        return 'hopital';
      case 'Douleur':
        return 'douleur';
      case 'Taxi':
        return 'taxi';
      case 'Bus':
        return 'bus';
      case 'Arrêt':
        return 'arret';
      case 'Billet':
        return 'billet';
      case 'Au secours':
        return 'au secours';
      case 'Urgence':
        return 'urgence';
      case 'Ambulance':
        return 'ambulance';
      case 'Médicament':
        return 'medicament';
      case 'Toilettes':
        return 'toilettes';
      case 'Eau':
        return 'eau';
      case 'Manger':
        return 'manger';
      case 'Aide':
        return 'aide';
      case 'Oui':
        return 'oui';
      case 'Non':
        return 'non';
      case 'Je':
        return 'je';
      case 'Moi':
        return 'moi';
      case 'Vous':
        return 'vous';
      case 'Tu':
        return 'tu';
      case 'Nom':
        return 'nom';
      case 'Je m appelle':
        return 'je m appelle';
      default:
        return gesture.toLowerCase();
    }
  }

  String _toSentence(List<String> words) {
    if (words.isEmpty) return '';
    final sentence = words.join(', ');
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
  }

  String _contextFromGestures(List<String> gestures) {
    final g = gestures.join(' ').toLowerCase();
    if (g.contains('médecin') || g.contains('hôpital') || g.contains('douleur') || g.contains('médicament')) {
      return 'Sante';
    }
    if (g.contains('taxi') || g.contains('bus') || g.contains('arrêt') || g.contains('billet')) {
      return 'Transport';
    }
    if (g.contains('urgence') || g.contains('secours') || g.contains('ambulance')) {
      return 'Urgence';
    }
    if (g.contains('bonjour') || g.contains('merci') || g.contains('au revoir')) {
      return 'Salutations';
    }
    return 'General';
  }

  static const Map<String, String> _phraseToGesture = {
    'au revoir': 'Au revoir',
    'au secours': 'Au secours',
    's il vous plait': 'S il vous plait',
    'je m appelle': 'Je m appelle',
  };

  static const Map<String, String> _wordToGesture = {
    'bonjour': 'Bonjour',
    'salut': 'Bonjour',
    'merci': 'Merci',
    'revoir': 'Au revoir',
    'secours': 'Au secours',
    'urgence': 'Urgence',
    'ambulance': 'Ambulance',
    'medecin': 'Médecin',
    'hopital': 'Hôpital',
    'infirmier': 'Infirmier',
    'medicament': 'Médicament',
    'douleur': 'Douleur',
    'taxi': 'Taxi',
    'bus': 'Bus',
    'gare': 'Gare',
    'billet': 'Billet',
    'arret': 'Arrêt',
    'eau': 'Eau',
    'manger': 'Manger',
    'toilette': 'Toilettes',
    'aide': 'Aide',
    'aider': 'Aide',
    'oui': 'Oui',
    'non': 'Non',
    'je': 'Je',
    'moi': 'Moi',
    'vous': 'Vous',
    'tu': 'Tu',
    'nom': 'Nom',
    'appelle': 'Je m appelle',
  };
}

