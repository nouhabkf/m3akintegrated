// ai_score_widget.dart
// ─────────────────────────────────────────────────────────────────────────────
// Widget qui affiche les scores IA d'accessibilité par type de handicap.
// Affiche les avis de la communauté utilisés comme source avec lien cliquable.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'accessibility_ai_service.dart';
import '../../data/repositories/community_post_source.dart';

// ── Panel principal ───────────────────────────────────────────────────────────

class AIScorePanel extends StatelessWidget {
  final AIAccessibilityResult? result;
  final bool isLoading;

  const AIScorePanel({super.key, this.result, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (result == null) return const SizedBox.shrink();
    return _buildResult(result!);
  }

  Widget _buildLoading() => Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8D4E8)),
        ),
        child: const Row(children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF0D77A6)),
          ),
          SizedBox(width: 10),
          Text(
            'Analyse IA en cours...',
            style: TextStyle(
                color: Color(0xFF0D77A6),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ]),
      );

  Widget _buildResult(AIAccessibilityResult r) => Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8D4E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D77A6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'IA Accessibilité',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              _confidenceBadge(r.confiance),
              const Spacer(),
              Text(
                '${r.scoreGlobal}/100',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D3A),
                ),
              ),
            ]),
            const SizedBox(height: 8),

            // Résumé IA
            if (r.resumeIA.isNotEmpty)
              Text(
                r.resumeIA,
                style:
                    const TextStyle(color: Color(0xFF4A6174), fontSize: 12),
              ),
            const SizedBox(height: 10),

            // Grille des scores par handicap
            _ScoreGrid(result: r),
            const SizedBox(height: 8),

            // Sources utilisées
            Text(
              'Sources : ${r.sourcesUtilisees.join(", ")}',
              style:
                  const TextStyle(color: Color(0xFF8EA0AD), fontSize: 10),
            ),

            // ── Avis communauté (lieu filtré) ──────────────────────────────
            const SizedBox(height: 10),
            _CommunityPostsSection(posts: r.communityPostsUsed),
          ],
        ),
      );

  Widget _confidenceBadge(String confiance) {
    final colors = {
      'Élevée':  (0xFF2A9F58, 0xFFD9F5DE),
      'Moyenne': (0xFFE69D2A, 0xFFFFF3DC),
      'Faible':  (0xFFD24C4C, 0xFFFDE8E8),
    };
    final c = colors[confiance] ?? (0xFF888888, 0xFFF0F0F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Color(c.$2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Confiance $confiance',
        style: TextStyle(
            color: Color(c.$1), fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Section avis communauté avec liens cliquables ────────────────────────────

class _CommunityPostsSection extends StatefulWidget {
  final List<CommunityPostSource> posts;
  const _CommunityPostsSection({required this.posts});

  @override
  State<_CommunityPostsSection> createState() => _CommunityPostsSectionState();
}

class _CommunityPostsSectionState extends State<_CommunityPostsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Afficher max 3 posts par défaut, tous si expanded
    final displayedPosts =
        _expanded ? widget.posts : widget.posts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête section
          Row(children: [
            const Icon(Icons.people_alt_rounded,
                size: 14, color: Color(0xFF0D77A6)),
            const SizedBox(width: 6),
            Text(
              'Avis communauté (${widget.posts.length} avis)',
              style: const TextStyle(
                color: Color(0xFF0D77A6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
          const SizedBox(height: 8),

          if (widget.posts.isEmpty)
            const Text(
              'Aucun avis communauté pour ce lieu',
              style: TextStyle(
                color: Color(0xFF8EA0AD),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...displayedPosts.map(
              (post) => _CommunityPostCard(post: post),
            ),

          // Bouton "Voir plus / moins"
          if (widget.posts.isNotEmpty && widget.posts.length > 3)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF0D77A6),
                  ),
                  Text(
                    _expanded
                        ? 'Voir moins'
                        : 'Voir ${widget.posts.length - 3} avis de plus',
                    style: const TextStyle(
                      color: Color(0xFF0D77A6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Carte d'un avis communauté avec lien ────────────────────────────────────

class _CommunityPostCard extends StatelessWidget {
  final CommunityPostSource post;
  const _CommunityPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDEEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _typeChip(post.type, post.typeLabel)),
              TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  context.go('/post-detail/${post.postId}');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: Color(0xFF0D77A6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Voir le post',
                      style: TextStyle(
                        color: Color(0xFF0D77A6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Extrait du contenu (max 120 car. via [CommunityPostSource.preview])
          Text(
            post.preview,
            style: const TextStyle(
              color: Color(0xFF3A4F5E),
              fontSize: 11,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          if (post.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _relativeTimeFr(post.createdAt!),
                style: const TextStyle(
                  color: Color(0xFF8EA0AD),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String typeLabel) {
    // handi. moteur=bleu, visuel=orange, auditif=vert, cognitif=violet
    final colors = {
      'handicapMoteur':   (0xFF1565C0, 0xFFE3F2FD),
      'handicapVisuel':   (0xFFE65100, 0xFFFBE9E0),
      'handicapAuditif':  (0xFF2E7D32, 0xFFE8F5E9),
      'handicapCognitif': (0xFF7B1FA2, 0xFFF3E5F5),
      'temoignage':       (0xFF0D77A6, 0xFFDCF0FB),
      'conseil':          (0xFF546E7A, 0xFFECEFF1),
    };

    final c = colors[type] ?? (0xFF888888, 0xFFF0F0F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(c.$2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        typeLabel,
        style: TextStyle(
          color: Color(c.$1),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _relativeTimeFr(DateTime date) {
    final now = DateTime.now();
    final d = date.toLocal();
    final n = now.toLocal();
    var diff = n.difference(d);
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inDays >= 1) {
      return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inHours >= 1) {
      return 'il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    }
    if (diff.inMinutes >= 1) {
      return 'il y a ${diff.inMinutes} min';
    }
    return "à l'instant";
  }
}

// ── Grille 2x3 des scores ─────────────────────────────────────────────────────

class _ScoreGrid extends StatelessWidget {
  final AIAccessibilityResult result;
  const _ScoreGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Fauteuil', Icons.accessible_rounded, result.fauteuilRoulant),
      ('Surdité', Icons.hearing_rounded, result.surdite),
      ('Cécité', Icons.visibility_off_rounded, result.cecite),
      ('Mobilité', Icons.directions_walk_rounded, result.mobiliteReduite),
      ('Cognitif', Icons.psychology_rounded, result.cognitif),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => _ScoreChip(
                label: item.$1,
                icon: item.$2,
                handicapScore: item.$3,
              ))
          .toList(),
    );
  }
}

// ── Chip individuel ───────────────────────────────────────────────────────────

class _ScoreChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final HandicapScore handicapScore;

  const _ScoreChip({
    required this.label,
    required this.icon,
    required this.handicapScore,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(handicapScore.color);
    final bgColor = color.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            '${handicapScore.score}',
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = Color(handicapScore.color);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.analytics_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${handicapScore.score}/100',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              handicapScore.niveau,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Détails',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A6174)),
            ),
            const SizedBox(height: 8),
            ...handicapScore.details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 6, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(d,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF3A4F5E)))),
                      ]),
                )),
            const SizedBox(height: 12),
            Text(
              'Sources : ${handicapScore.sources.join(", ")}',
              style: const TextStyle(
                  color: Color(0xFF8EA0AD), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias : même widget que [AIScorePanel].
typedef AIScoreWidget = AIScorePanel;
