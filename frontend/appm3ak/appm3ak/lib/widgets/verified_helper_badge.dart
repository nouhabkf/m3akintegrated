import 'package:flutter/material.dart';

/// Palier affiché à partir des `trustPoints` (aligné gamification backend).
enum VerifiedHelperTier {
  none,
  bronze,
  silver,
  gold,
}

VerifiedHelperTier verifiedTierFromPoints(int points) {
  if (points <= 0) return VerifiedHelperTier.none;
  if (points < 25) return VerifiedHelperTier.bronze;
  if (points < 75) return VerifiedHelperTier.silver;
  return VerifiedHelperTier.gold;
}

/// Badge dynamique Bronze / Argent / Or pour les helpers vérifiés.
class VerifiedHelperBadge extends StatelessWidget {
  const VerifiedHelperBadge({
    required this.trustPoints,
    super.key,
    this.compact = true,
  });

  final int trustPoints;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tier = verifiedTierFromPoints(trustPoints);
    if (tier == VerifiedHelperTier.none) return const SizedBox.shrink();

    final (label, color, icon) = switch (tier) {
      VerifiedHelperTier.bronze => ('Bronze', const Color(0xFFCD7F32), Icons.verified_outlined),
      VerifiedHelperTier.silver => ('Argent', const Color(0xFFC0C0C0), Icons.verified),
      VerifiedHelperTier.gold => ('Or', const Color(0xFFFFD700), Icons.verified),
      VerifiedHelperTier.none => ('', Colors.transparent, Icons.circle),
    };

    return Tooltip(
      message: 'Helper vérifié — $label ($trustPoints pts)',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: color),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge « Partenaire » — compte labellisé (association, commerce engagé).
class PartnerOrgBadge extends StatelessWidget {
  const PartnerOrgBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1565C0);
    return Tooltip(
      message: 'Compte partenaire — information vérifiée localement',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined, size: compact ? 14 : 16, color: color),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                'Partenaire',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
