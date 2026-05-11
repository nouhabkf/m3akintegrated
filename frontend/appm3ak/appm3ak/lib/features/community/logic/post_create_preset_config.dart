// Presets for the inclusive create-post flow: map to API fields and generated text.

/// Identifiers for quick suggestion chips (local only).
enum PostCreatePresetId {
  blocked,
  difficultAccess,
  inaccessibleEntrance,
  missingRamp,
  stairsWithoutHelp,
  needOrientation,
  usefulAdvice,
  personalTestimony,
}

/// Default values applied when the user picks a preset (replaces nature, audience, needs).
class PostCreatePresetMapping {
  const PostCreatePresetMapping({
    required this.id,
    required this.postNature,
    required this.targetAudience,
    this.needsAudio = false,
    this.needsVisual = false,
    this.needsPhysical = false,
    this.needsSimpleLanguage = false,
  });

  final PostCreatePresetId id;

  /// API string: signalement | conseil | temoignage | information | alerte
  final String postNature;

  /// API string: all | motor | visual | hearing | cognitive | caregiver
  final String targetAudience;

  final bool needsAudio;
  final bool needsVisual;
  final bool needsPhysical;
  final bool needsSimpleLanguage;

  static const List<PostCreatePresetMapping> ordered = [
    PostCreatePresetMapping(
      id: PostCreatePresetId.blocked,
      postNature: 'signalement',
      targetAudience: 'motor',
      needsAudio: true,
      needsPhysical: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.difficultAccess,
      postNature: 'signalement',
      targetAudience: 'motor',
      needsVisual: true,
      needsPhysical: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.inaccessibleEntrance,
      postNature: 'signalement',
      targetAudience: 'motor',
      needsPhysical: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.missingRamp,
      postNature: 'signalement',
      targetAudience: 'motor',
      needsPhysical: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.stairsWithoutHelp,
      postNature: 'signalement',
      targetAudience: 'motor',
      needsPhysical: true,
      needsAudio: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.needOrientation,
      postNature: 'information',
      targetAudience: 'all',
      needsAudio: true,
      needsVisual: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.usefulAdvice,
      postNature: 'conseil',
      targetAudience: 'all',
      needsSimpleLanguage: true,
    ),
    PostCreatePresetMapping(
      id: PostCreatePresetId.personalTestimony,
      postNature: 'temoignage',
      targetAudience: 'all',
    ),
  ];
}
