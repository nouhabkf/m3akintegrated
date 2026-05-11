import 'package:flutter/material.dart';

/// Chemin de l'image du logo Ma3ak (à placer dans assets/images/).
const String kAppLogoAsset = 'assets/images/logo.png';

/// Logo de l'application. Affiche l'image si elle existe, sinon un placeholder.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.borderRadius = 16,
    this.backgroundColor,
  });

  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        kAppLogoAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            Icons.accessible,
            size: size * 0.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
