// Déclarer l'enum en dehors de la classe (au niveau du fichier)
enum ScenarioType {
  hospital,
  transport,
  emergency,
  dailyLife,
  education,
}

class PracticalScenarios {
  static List<Scenario> getScenariosByType(ScenarioType type) {
    switch (type) {
      case ScenarioType.hospital:
        return _getHospitalScenarios();
      case ScenarioType.transport:
        return _getTransportScenarios();
      case ScenarioType.emergency:
        return _getEmergencyScenarios();
      case ScenarioType.dailyLife:
        return _getDailyLifeScenarios();
      case ScenarioType.education:
        return _getEducationScenarios();
    }
  }

  static List<Scenario> _getHospitalScenarios() {
    return [
      Scenario(
        id: 1,
        title: 'Consultation Médicale',
        description: 'Simulez une consultation médicale avec un médecin',
        type: ScenarioType.hospital,
        situation:
        'Vous êtes dans une salle d\'attente d\'un hôpital. Le médecin vous appelle.',
        requiredSigns: ['Bonjour', 'J\'ai mal', 'Où', 'Merci'],
        steps: [
          ScenarioStep(
            stepNumber: 1,
            instruction: 'Saluez le médecin en langue des signes',
            expectedSign: 'Bonjour',
            feedback: 'Le médecin vous répond avec un sourire',
          ),
          ScenarioStep(
            stepNumber: 2,
            instruction: 'Expliquez votre problème de santé',
            expectedSign: 'J\'ai mal',
            feedback: 'Le médecin comprend et vous pose des questions',
          ),
          ScenarioStep(
            stepNumber: 3,
            instruction: 'Demandez où se trouve la salle d\'examen',
            expectedSign: 'Où',
            feedback: 'Le médecin vous guide vers la salle',
          ),
        ],
        difficulty: 2,
      ),
      Scenario(
        id: 2,
        title: 'Pharmacie',
        description: 'Achetez des médicaments à la pharmacie',
        type: ScenarioType.hospital,
        situation: 'Vous êtes à la pharmacie pour acheter un médicament',
        requiredSigns: ['Bonjour', 'Je veux', 'Combien', 'Merci'],
        steps: [],
        difficulty: 1,
      ),
    ];
  }

  static List<Scenario> _getTransportScenarios() {
    return [
      Scenario(
        id: 3,
        title: 'Prendre le Bus',
        description: 'Demandez des informations sur le bus',
        type: ScenarioType.transport,
        situation:
        'Vous êtes à l\'arrêt de bus et avez besoin d\'informations',
        requiredSigns: ['Bonjour', 'Où', 'Quand', 'Merci'],
        steps: [
          ScenarioStep(
            stepNumber: 1,
            instruction: 'Demandez où se trouve l\'arrêt de bus',
            expectedSign: 'Où',
            feedback: 'Le conducteur vous indique la direction',
          ),
          ScenarioStep(
            stepNumber: 2,
            instruction: 'Demandez l\'heure de départ',
            expectedSign: 'Quand',
            feedback: 'Le conducteur vous montre l\'heure sur son téléphone',
          ),
        ],
        difficulty: 1,
      ),
      Scenario(
        id: 4,
        title: 'Taxi',
        description: 'Commander un taxi',
        type: ScenarioType.transport,
        situation: 'Vous devez commander un taxi',
        requiredSigns: ['Bonjour', 'Je veux', 'Où', 'Combien'],
        steps: [],
        difficulty: 2,
      ),
    ];
  }

  static List<Scenario> _getEmergencyScenarios() {
    return [
      Scenario(
        id: 5,
        title: 'Appel d\'Urgence',
        description: 'Appelez les secours en situation d\'urgence',
        type: ScenarioType.emergency,
        situation: 'Une situation d\'urgence nécessite d\'appeler les secours',
        requiredSigns: ['AIDE', 'URGENCE', 'OÙ', 'MAINTENANT'],
        steps: [
          ScenarioStep(
            stepNumber: 1,
            instruction: 'Signalez l\'urgence',
            expectedSign: 'URGENCE',
            feedback: 'Les secours comprennent la situation',
          ),
          ScenarioStep(
            stepNumber: 2,
            instruction: 'Indiquez votre localisation',
            expectedSign: 'OÙ',
            feedback: 'Les secours arrivent rapidement',
          ),
        ],
        difficulty: 3,
      ),
    ];
  }

  static List<Scenario> _getDailyLifeScenarios() {
    return [
      Scenario(
        id: 6,
        title: 'Achat au Marché',
        description: 'Faites vos courses au marché',
        type: ScenarioType.dailyLife,
        situation: 'Vous êtes au marché pour acheter des légumes',
        requiredSigns: ['Bonjour', 'Je veux', 'Combien', 'Merci'],
        steps: [],
        difficulty: 1,
      ),
    ];
  }

  static List<Scenario> _getEducationScenarios() {
    return [
      Scenario(
        id: 7,
        title: 'Cours à l\'École',
        description: 'Participez à un cours en classe',
        type: ScenarioType.education,
        situation: 'Vous êtes en classe et voulez poser une question',
        requiredSigns: ['QUESTION', 'JE NE COMPRENDS PAS', 'RÉPÉTEZ'],
        steps: [],
        difficulty: 2,
      ),
    ];
  }
}

class Scenario {
  final int id;
  final String title;
  final String description;
  final ScenarioType type; // Plus besoin de PracticalScenarios.ScenarioType
  final String situation;
  final List<String> requiredSigns;
  final List<ScenarioStep> steps;
  final int difficulty;

  Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.situation,
    required this.requiredSigns,
    required this.steps,
    required this.difficulty,
  });
}

class ScenarioStep {
  final int stepNumber;
  final String instruction;
  final String expectedSign;
  final String feedback;

  ScenarioStep({
    required this.stepNumber,
    required this.instruction,
    required this.expectedSign,
    required this.feedback,
  });
}