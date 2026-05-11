import '../../../data/models/user_model.dart';

/// Paramètres pour ouvrir l’assistant santé IA (chat + vocal).
class HealthChatLaunch {
  const HealthChatLaunch({
    this.initialMessage,
    this.user,
  });

  final String? initialMessage;
  final UserModel? user;
}
