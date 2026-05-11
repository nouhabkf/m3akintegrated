/// Langue de sortie vocale de l’assistant (indépendante de la langue d’interface ar/fr).
enum HealthVoiceLang {
  fr,
  en,
}

extension HealthVoiceLangCode on HealthVoiceLang {
  String get ttsCode => this == HealthVoiceLang.fr ? 'fr-FR' : 'en-US';

  String get label => this == HealthVoiceLang.fr ? 'Français' : 'English';
}
