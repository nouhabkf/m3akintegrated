import 'package:flutter/material.dart';

/// Bouton accessible : cible tactile min 44x44, semantics pour TalkBack/VoiceOver.
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minimumSize = const Size(88, 48),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Size minimumSize;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: minimumSize.width >= 88 ? null : 88,
        height: minimumSize.height >= 48 ? 48 : minimumSize.height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 48),
          ),
          child: child,
        ),
      ),
    );
  }
}
