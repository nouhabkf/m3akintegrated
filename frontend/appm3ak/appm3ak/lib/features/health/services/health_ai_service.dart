import 'health_voice_lang.dart';

/// Résultat d’analyse glycémie (mg/dL à jeun comme référence principale).
class GlycemiaAnalysis {
  const GlycemiaAnalysis({
    required this.zoneKey,
    required this.summaryFr,
    required this.summaryEn,
    required this.adviceFr,
    required this.adviceEn,
  });

  final String zoneKey;
  final String summaryFr;
  final String summaryEn;
  final String adviceFr;
  final String adviceEn;

  String summary(HealthVoiceLang lang) =>
      lang == HealthVoiceLang.fr ? summaryFr : summaryEn;

  String advice(HealthVoiceLang lang) =>
      lang == HealthVoiceLang.fr ? adviceFr : adviceEn;
}

/// Contexte profil (non médical — pour adapter le langage général).
class HealthUserContext {
  const HealthUserContext({
    this.typeHandicap,
    this.besoinSpecifique,
    this.hasRecentGlucoseLog = false,
    this.fastingForAnalysis = true,
  });

  final String? typeHandicap;
  final String? besoinSpecifique;
  final bool hasRecentGlucoseLog;
  final bool fastingForAnalysis;

  bool get hintsDiabetes {
    final t = _join;
    return t.contains('diab') ||
        t.contains('glyc') ||
        t.contains('sucre') ||
        t.contains('insulin') ||
        hasRecentGlucoseLog;
  }

  bool get hintsMotorLimitation {
    final t = _join;
    return t.contains('moteur') ||
        t.contains('motor') ||
        t.contains('mobilit') ||
        t.contains('fauteuil') ||
        t.contains('wheelchair') ||
        t.contains('handicap') ||
        t.contains('paralys');
  }

  String get _join {
    final a = (typeHandicap ?? '').toLowerCase();
    final b = (besoinSpecifique ?? '').toLowerCase();
    return '$a $b';
  }

  String preambleFr(HealthVoiceLang lang) {
    if (lang != HealthVoiceLang.fr) return '';
    final parts = <String>[];
    if (hintsMotorLimitation) {
      parts.add(
        'Compte tenu d’une situation de mobilité à prendre en compte, privilégiez le repos, '
        'évitez les efforts brusques et demandez de l’aide pour vous déplacer en cas de malaise.',
      );
    }
    if (hintsDiabetes) {
      parts.add(
        'Pour un suivi glycémique, notez l’heure et si vous étiez à jeun ; en cas de valeur '
        'inhabituelle ou de symptômes, contactez votre équipe soignante.',
      );
    }
    if (parts.isEmpty) return '';
    return '${parts.join(' ')} ';
  }

  String preambleEn(HealthVoiceLang lang) {
    if (lang != HealthVoiceLang.en) return '';
    final parts = <String>[];
    if (hintsMotorLimitation) {
      parts.add(
        'Given possible mobility limitations, rest when needed, avoid sudden exertion, '
        'and ask for help if you feel unwell when moving.',
      );
    }
    if (hintsDiabetes) {
      parts.add(
        'For blood sugar follow-up, log the time and whether you were fasting; if readings '
        'are unusual or you have symptoms, contact your care team.',
      );
    }
    if (parts.isEmpty) return '';
    return '${parts.join(' ')} ';
  }
}

/// Logique d’aide à la décision locale (pas un avis médical — toujours renvoyer vers un pro).
class HealthAiService {
  const HealthAiService();

  static const String disclaimerFr =
      'Information générale uniquement — consultez un professionnel de santé pour tout diagnostic ou traitement.';
  static const String disclaimerEn =
      'General information only — see a healthcare professional for diagnosis or treatment.';

  GlycemiaAnalysis analyzeGlycemia(double mgDl, {bool fastingAssumed = true}) {
    if (mgDl < 54) {
      return const GlycemiaAnalysis(
        zoneKey: 'severe_low',
        summaryFr: 'Hypoglycémie sévère probable (très bas).',
        summaryEn: 'Likely severe hypoglycemia (very low).',
        adviceFr:
            'Si des symptômes importants : sucre rapide puis repas ; appelez les secours si pas d’amélioration.',
        adviceEn:
            'If significant symptoms: take fast sugar then a meal; call emergency services if no improvement.',
      );
    }
    if (mgDl < 70) {
      return const GlycemiaAnalysis(
        zoneKey: 'low',
        summaryFr: 'Glycémie basse (hypoglycémie légère à modérée).',
        summaryEn: 'Low blood sugar (mild to moderate hypoglycemia).',
        adviceFr:
            'Prenez 15–20 g de sucre rapide, attendez 15 minutes, vérifiez à nouveau.',
        adviceEn:
            'Take 15–20 g of fast-acting sugar, wait 15 minutes, recheck.',
      );
    }

    if (fastingAssumed) {
      if (mgDl <= 99) {
        return const GlycemiaAnalysis(
          zoneKey: 'normal_fasting',
          summaryFr: 'À jeun : valeur dans la plage habituellement considérée comme normale.',
          summaryEn: 'Fasting: commonly considered within normal range.',
          adviceFr:
              'Maintenez une alimentation équilibrée et l’activité physique adaptée.',
          adviceEn:
              'Keep balanced meals and appropriate physical activity.',
        );
      }
      if (mgDl <= 125) {
        return const GlycemiaAnalysis(
          zoneKey: 'prediabetes_fasting',
          summaryFr: 'À jeun : plage souvent associée au pré-diabète (à confirmer par un médecin).',
          summaryEn:
              'Fasting: range often associated with prediabetes (confirm with a doctor).',
          adviceFr:
              'Surveillance glycémique, alimentation et bilan médical recommandés.',
          adviceEn:
              'Blood sugar monitoring, diet, and medical follow-up recommended.',
        );
      }
      return const GlycemiaAnalysis(
        zoneKey: 'high_fasting',
        summaryFr: 'À jeun : taux élevé — bilan médical urgent recommandé.',
        summaryEn: 'Fasting: high reading — prompt medical follow-up recommended.',
        adviceFr:
            'Contactez votre médecin ou un service d’urgence selon vos symptômes.',
        adviceEn:
            'Contact your doctor or emergency care depending on symptoms.',
      );
    }

    if (mgDl < 140) {
      return const GlycemiaAnalysis(
        zoneKey: 'normal_pp',
        summaryFr: 'Après repas : souvent dans une plage acceptable (indicatif).',
        summaryEn: 'After meal: often within an acceptable range (indicative).',
        adviceFr: 'Répartissez les glucides et privilégiez les fibres.',
        adviceEn: 'Spread carbs and favor fiber-rich foods.',
      );
    }
    if (mgDl < 200) {
      return const GlycemiaAnalysis(
        zoneKey: 'elevated_pp',
        summaryFr: 'Après repas : élévation modérée — à discuter avec votre médecin.',
        summaryEn:
            'After meal: moderate elevation — discuss with your clinician.',
        adviceFr: 'Notez le repas et l’heure pour le prochain rendez-vous.',
        adviceEn: 'Log meal and time for your next appointment.',
      );
    }
    return const GlycemiaAnalysis(
      zoneKey: 'high_pp',
      summaryFr: 'Après repas : taux très élevé — avis médical recommandé.',
      summaryEn: 'After meal: very high — medical advice recommended.',
      adviceFr: 'Hydratez-vous et contactez un professionnel si malaise.',
      adviceEn: 'Stay hydrated and seek care if you feel unwell.',
    );
  }

  /// Interprète un nombre dans un texte (mg/dL, ou g/L type « 1,30 »).
  double? parseGlycemicMgDlFromMessage(String message) {
    final m = RegExp(r'(\d+[.,]\d+|\d+)').firstMatch(message);
    if (m == null) return null;
    final raw = m.group(1)!.replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null) return null;
    if (v >= 0.5 && v <= 4.0 && raw.contains('.')) {
      return v * 100;
    }
    if (v >= 40 && v <= 600) {
      return v;
    }
    if (v > 4 && v <= 35) {
      return v * 18;
    }
    return null;
  }

  bool _messageAboutGlycemia(String q) {
    return q.contains('glyc') ||
        q.contains('glucose') ||
        q.contains('sucre') ||
        q.contains('blood sugar') ||
        q.contains('blood glucose') ||
        RegExp(r'\b\d+[.,]?\d*\s*(g/l|mg/dl|mmol)?').hasMatch(q);
  }

  /// Score 0–100 indicatif (non clinique).
  int computeHealthScore({
    required double? lastGlucoseMgDl,
    required int medicationCount,
    required bool glucoseInRangeIfKnown,
  }) {
    var score = 55;
    if (lastGlucoseMgDl != null) {
      score += glucoseInRangeIfKnown ? 25 : 10;
    } else {
      score += 12;
    }
    if (medicationCount > 0) {
      score += 12;
      score += (medicationCount.clamp(1, 3) - 1) * 3;
    } else {
      score += 5;
    }
    return score.clamp(0, 100);
  }

  ({String fr, String en}) chatReply(
    String userMessage, {
    required HealthVoiceLang voiceLang,
    HealthUserContext? profile,
  }) {
    final q = userMessage.toLowerCase().trim();
    final ctx = profile ?? const HealthUserContext();

    if (_isSos(q)) {
      return (
        fr:
            'Mode urgence : si la vie est en danger ou la douleur est intense, composez le 190 (SAMU) ou le 15, ou les services d’urgence locaux. '
            'Restez calme, décrivez votre position. Ce message ne remplace pas les secours.',
        en:
            'Emergency mode: if life-threatening or severe pain, call your local emergency number (e.g. 15/112/911). '
            'Stay calm and state your location. This app is not a substitute for emergency services.',
      );
    }

    if (_isHeadache(q)) {
      return (
        fr:
            '${ctx.preambleFr(HealthVoiceLang.fr)}Céphalée : réponse générale uniquement (pas de diagnostic). '
            'Reposez-vous dans un endroit calme, buvez de l’eau, limitez les écrans. '
            'Consultez vite un médecin si céphalée brutale « coup de tonnerre », fièvre, raideur de nuque, troubles de la vision ou de la parole, '
            'ou si la douleur est inhabituelle et forte. $disclaimerFr',
        en:
            '${ctx.preambleEn(HealthVoiceLang.en)}Headache: general guidance only (not a diagnosis). '
            'Rest in a quiet place, hydrate, limit screen time. '
            'Seek urgent care for sudden “thunderclap” headache, fever, stiff neck, vision or speech changes, '
            'or unusually severe pain. $disclaimerEn',
      );
    }

    if (_messageAboutGlycemia(q)) {
      final mg = parseGlycemicMgDlFromMessage(userMessage);
      if (mg != null) {
        final a = analyzeGlycemia(mg, fastingAssumed: ctx.fastingForAnalysis);
        final alert = a.zoneKey.contains('high') ||
                a.zoneKey.contains('severe') ||
                a.zoneKey.contains('low')
            ? (_voiceLangAlert(voiceLang))
            : '';
        return (
          fr:
              '${ctx.preambleFr(HealthVoiceLang.fr)}Valeur interprétée environ ${mg.toStringAsFixed(0)} mg/dL (approximation selon votre saisie). '
              '${a.summaryFr} ${a.adviceFr} $alert$disclaimerFr',
          en:
              '${ctx.preambleEn(HealthVoiceLang.en)}Interpreted roughly ${mg.toStringAsFixed(0)} mg/dL (approximate from your input). '
              '${a.summaryEn} ${a.adviceEn} $alert$disclaimerEn',
        );
      }
      return (
        fr:
            '${ctx.preambleFr(HealthVoiceLang.fr)}Pour la glycémie : indiquez la valeur (par ex. « 130 » en mg/dL ou « 1,30 » souvent lu en g/L), '
            'l’heure et si vous étiez à jeun. Vous pouvez aussi utiliser l’outil d’analyse dans cet onglet. '
            'En cas de malaise ou de confusion, contactez les secours. $disclaimerFr',
        en:
            '${ctx.preambleEn(HealthVoiceLang.en)}For blood sugar: give the value (e.g. 130 mg/dL or 1.30 often read as g/L), '
            'time, and whether you were fasting. You can also use the analysis tool on this screen. '
            'If confused or very unwell, seek emergency care. $disclaimerEn',
      );
    }

    if (q.contains('médic') || q.contains('medic') || q.contains('pilule') || q.contains('rappel')) {
      return (
        fr:
            '${ctx.preambleFr(HealthVoiceLang.fr)}Ajoutez vos rappels dans cet onglet Santé : nom et heure. '
            'Prenez vos médicaments exactement comme prescrit par votre médecin. $disclaimerFr',
        en:
            '${ctx.preambleEn(HealthVoiceLang.en)}Add reminders here in Health: name and time. '
            'Take medications exactly as prescribed. $disclaimerEn',
      );
    }

    if (q.contains('bonjour') || q.contains('hello') || q.contains('salut') || q.contains('hi')) {
      return (
        fr:
            'Bonjour, je suis l’assistant santé intelligent Ma3ak. Je peux vous orienter en français ou en anglais : '
            'symptômes simples (ex. mal à la tête), glycémie avec valeur, rappels de traitements, et urgences générales — '
            'avec lecture vocale. Ceci ne remplace pas un professionnel de santé.',
        en:
            'Hello, I am the Ma3ak intelligent health assistant. I can guide you in French or English: '
            'simple symptoms (e.g. headache), blood sugar with a value, medication reminders, and general emergencies — '
            'with voice playback. This does not replace a clinician.',
      );
    }

    return (
      fr:
          '${ctx.preambleFr(HealthVoiceLang.fr)}Je comprends : « $userMessage ». '
          'Réponse générale : $disclaimerFr '
          'Pour toute question médicale précise, parlez à votre médecin ou à un pharmacien.',
      en:
          '${ctx.preambleEn(HealthVoiceLang.en)}I understood: « $userMessage ». '
          'General reply: $disclaimerEn '
          'For specific medical questions, speak with your doctor or pharmacist.',
    );
  }

  String _voiceLangAlert(HealthVoiceLang lang) {
    if (lang == HealthVoiceLang.fr) {
      return 'Point d’attention : suivez les consignes de votre médecin et réévaluez si besoin. ';
    }
    return 'Note: follow your clinician’s instructions and reassess as needed. ';
  }

  bool _isHeadache(String q) {
    const keys = [
      'mal à la tête',
      'mal a la tete',
      'mal de tête',
      'mal de tete',
      'céphalée',
      'cephalee',
      'headache',
      'head hurts',
      'migraine',
    ];
    return keys.any(q.contains);
  }

  bool _isSos(String q) {
    const keys = [
      'sos',
      'urgence',
      'urgent',
      'emergency',
      'douleur forte',
      'severe pain',
      'can\'t breathe',
      'can\'t breath',
      'inconscient',
      'unconscious',
      'saigne beaucoup',
      'bleeding heavily',
    ];
    if (keys.any(q.contains)) return true;
    if (q.contains('j\'ai mal') || q.contains('j ai mal')) {
      return q.contains('poitrine') ||
          q.contains('thorax') ||
          q.contains('chest') ||
          q.contains('souffle') ||
          q.contains('breath');
    }
    return false;
  }
}
