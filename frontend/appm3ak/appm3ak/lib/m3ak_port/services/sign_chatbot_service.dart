class SignChatbotReply {
  final String text;
  final List<String> gestures;

  const SignChatbotReply({
    required this.text,
    required this.gestures,
  });
}

class SignChatbotService {
  const SignChatbotService();

  SignChatbotReply replyTo(String userMessage) {
    final msg = userMessage.toLowerCase().trim();

    if (msg.isEmpty) {
      return const SignChatbotReply(
        text: 'Je suis pret. Ecris une question et je te reponds en signes.',
        gestures: ['Bonjour'],
      );
    }

    if (_containsAny(msg, ['bonjour', 'salut', 'hello', 'salam'])) {
      return const SignChatbotReply(
        text: 'Bonjour ! Comment puis-je t aider aujourd hui ?',
        gestures: ['Bonjour', 'Merci'],
      );
    }

    if (_containsAny(msg, ['merci', 'thanks'])) {
      return const SignChatbotReply(
        text: 'Avec plaisir. Continue comme ca, tu progresses bien.',
        gestures: ['Merci', 'Au revoir'],
      );
    }

    if (_containsAny(msg, ['medecin', 'médecin', 'hopital', 'hôpital', 'douleur'])) {
      return const SignChatbotReply(
        text: 'En situation medicale: utilise d abord "Médecin", puis "Douleur".',
        gestures: ['Médecin', 'Douleur', 'Au secours'],
      );
    }

    if (_containsAny(msg, ['urgence', 'secours', 'aide'])) {
      return const SignChatbotReply(
        text: 'En urgence: signe "Au secours" avec de grands mouvements, puis "Urgence".',
        gestures: ['Au secours', 'Urgence', 'Ambulance'],
      );
    }

    if (_containsAny(msg, ['bus', 'taxi', 'transport', 'gare', 'arret', 'arrêt', 'billet'])) {
      return const SignChatbotReply(
        text: 'Pour le transport: commence par "Taxi" ou "Bus", puis "Arrêt" ou "Billet".',
        gestures: ['Taxi', 'Bus', 'Arrêt', 'Billet'],
      );
    }

    if (_containsAny(msg, ['pharmacie', 'medicament', 'médicament', 'ordonnance'])) {
      return const SignChatbotReply(
        text: 'A la pharmacie, montre "Médicament", puis precise ton besoin.',
        gestures: ['Médicament', 'Merci'],
      );
    }

    if (_containsAny(msg, ['rendez', 'operation', 'opération', 'infirmier'])) {
      return const SignChatbotReply(
        text: 'Dans ce cas, utilise "Rendez-vous", puis "Infirmier" ou "Opération".',
        gestures: ['Rendez-vous', 'Infirmier', 'Opération'],
      );
    }

    return const SignChatbotReply(
      text: 'Je te propose une sequence de base: Bonjour, puis explique avec un geste du contexte.',
      gestures: ['Bonjour', 'Merci', 'Au revoir'],
    );
  }

  bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) return true;
    }
    return false;
  }
}

