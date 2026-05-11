import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/volume/android_volume_hub.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../../../widgets/verified_helper_badge.dart';

/// Écran de liste des posts de la communauté.
class CommunityPostsScreen extends ConsumerStatefulWidget {
  const CommunityPostsScreen({super.key});

  @override
  ConsumerState<CommunityPostsScreen> createState() =>
      _CommunityPostsScreenState();
}

enum _PostsOwnerSegment {
  mine,
  others,
}

class _CommunityPostsScreenState extends ConsumerState<CommunityPostsScreen> {
  int _currentPage = 1;
  final int _limit = 20;
  PostType? _selectedType;
  _PostsOwnerSegment _ownerSegment = _PostsOwnerSegment.others;
  /// Filtre backend selon `role` + `typeHandicap` (endpoint `GET /community/posts/for-me`).
  bool _smartProfileFilter = false;
  bool _filtersExpanded = false;
  final FlutterTts _audioTts = FlutterTts();
  String? _audioMode;
  bool _audioPaused = false;
  bool _audioStopRequested = false;
  bool _audioStartedForCurrentList = false;
  int _currentAudioSelectedPost = -1;
  List<PostModel> _audioPosts = const [];
  Timer? _audioNextTimer;
  Future<bool> Function()? _previousVolumeUpPriority;

  @override
  void initState() {
    super.initState();
    _initAudioTts();
    _bindVolumeShortcut();
  }

  void _bindVolumeShortcut() {
    AndroidVolumeHub.ensureInitialized();
    _previousVolumeUpPriority = AndroidVolumeHub.onVolumeUpPriority;
    AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpForAudioSelect;
  }

  Future<bool> _onVolumeUpForAudioSelect() async {
    if (!mounted || _audioMode == null) return false;
    _selectAudioPost(fallbackPosts: _audioPosts);
    return true;
  }

  Future<void> _initAudioTts() async {
    await _audioTts.awaitSpeakCompletion(true);
    await _audioTts.setLanguage('fr-FR');
    await _audioTts.setSpeechRate(0.45);
    await _audioTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _audioNextTimer?.cancel();
    _audioStopRequested = true;
    _audioTts.stop();
    if (AndroidVolumeHub.onVolumeUpPriority == _onVolumeUpForAudioSelect) {
      AndroidVolumeHub.onVolumeUpPriority = _previousVolumeUpPriority;
    }
    super.dispose();
  }

  Future<void> _speakAudioModeIntro() async {
    await _audioTts.stop();
    await _audioTts.speak(
      'Je vais lire les posts. Appuyez sur volume plus pour choisir.',
    );
  }

  String _audioPreview(PostModel post) {
    final content = post.contenu.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (content.isEmpty) return 'Sans description.';
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}.';
  }

  Future<void> _speakPostsOneByOne(List<PostModel> posts) async {
    _audioStopRequested = false;
    _audioPosts = List<PostModel>.from(posts);
    _currentAudioSelectedPost = _audioPosts.isEmpty ? -1 : 0;
    await _speakAudioModeIntro();
    if (!mounted || _audioStopRequested) return;

    for (var i = 0; i < _audioPosts.length; i++) {
      if (!mounted || _audioStopRequested) return;
      while (_audioPaused && mounted && !_audioStopRequested) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted || _audioStopRequested) return;
      final post = _audioPosts[i];
      setState(() => _currentAudioSelectedPost = i);
      final author = post.userName.trim().isEmpty ? 'Utilisateur inconnu' : post.userName.trim();
      final actionHint = _audioMode == 'voiceComment'
          ? 'Appuyez sur volume plus pour commenter ce post avec la voix.'
          : 'Appuyez sur volume plus pour choisir ce post.';
      final message = 'Post ${i + 1} de $author. ${_audioPreview(post)} $actionHint';
      await _audioTts.stop();
      await _audioTts.speak(message);
      if (!mounted || _audioStopRequested) return;
      final wait = Completer<void>();
      _audioNextTimer?.cancel();
      _audioNextTimer = Timer(const Duration(milliseconds: 900), () {
        if (!wait.isCompleted) wait.complete();
      });
      await wait.future;
    }
  }

  Future<void> _restartAudioMode(List<PostModel> posts) async {
    _audioNextTimer?.cancel();
    _audioStopRequested = true;
    await _audioTts.stop();
    _audioStopRequested = false;
    if (!mounted) return;
    setState(() {
      _audioPaused = false;
      _audioStartedForCurrentList = true;
    });
    await _speakPostsOneByOne(posts);
  }

  Future<void> _quitAudioMode() async {
    _audioNextTimer?.cancel();
    _audioStopRequested = true;
    await _audioTts.stop();
    if (!mounted) return;
    setState(() {
      _audioMode = null;
      _audioPaused = false;
      _audioStartedForCurrentList = false;
      _currentAudioSelectedPost = -1;
      _audioPosts = const [];
    });
  }

  /// Sélection du post en cours de lecture, ou [preferredIndex] dans [fallbackPosts]
  /// quand la file audio interne n’est pas encore prête.
  void _selectAudioPost({
    int? preferredIndex,
    List<PostModel>? fallbackPosts,
  }) {
    if (_audioMode == null) return;
    final source = _audioPosts.isNotEmpty
        ? _audioPosts
        : (fallbackPosts ?? const <PostModel>[]);
    if (source.isEmpty) return;
    final idx = preferredIndex != null &&
            preferredIndex >= 0 &&
            preferredIndex < source.length
        ? preferredIndex
        : (_currentAudioSelectedPost < 0 ||
                _currentAudioSelectedPost >= source.length)
            ? 0
            : _currentAudioSelectedPost;
    final post = source[idx];
    _audioStopRequested = true;
    _audioNextTimer?.cancel();
    _audioTts.stop();
    context.push('/post-detail/${post.id}?mode=$_audioMode');
  }

  Future<void> _openCreatePost(BuildContext context) async {
    // Le + doit toujours ouvrir l’écran “Créer un post” (formulaire complet).
    // Les modes accessibilité restent accessibles depuis cet écran.
    await context.push('/create-post');
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final mode = uri.queryParameters['mode'];
    final owner = uri.queryParameters['owner'];
    final normalizedOwner = owner == 'mine'
        ? _PostsOwnerSegment.mine
        : owner == 'others'
            ? _PostsOwnerSegment.others
            : null;
    if (normalizedOwner != null && _ownerSegment != normalizedOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _ownerSegment = normalizedOwner);
      });
    }
    final normalizedMode = (mode == 'readPost' || mode == 'readComments' || mode == 'voiceComment')
        ? mode
        : (mode == 'readCommentsAudio' ? 'readComments' : null);
    if (_audioMode != normalizedMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() {
          _audioMode = normalizedMode;
          _audioStartedForCurrentList = false;
          _audioPaused = false;
          _currentAudioSelectedPost = -1;
        });
      });
    }
    final user = ref.watch(authStateProvider).valueOrNull;
    final currentUserId = user?.id.trim();
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    final useSmart = _smartProfileFilter && user != null;
    final postsAsync = ref.watch(communityFeedProvider((
      page: _currentPage,
      limit: _limit,
      smart: useSmart,
    )));

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Barre d'actions (remplace AppBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.communityPosts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!compact)
                      TextButton.icon(
                        onPressed: () => context.push('/community-live?host=1'),
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('Lancer un live'),
                      )
                    else
                      IconButton(
                        onPressed: () => context.push('/community-live?host=1'),
                        icon: const Icon(Icons.wifi_tethering),
                        tooltip: 'Lancer un live',
                      ),
                    IconButton(
                      onPressed: () => context.push('/messages'),
                      icon: const Icon(Icons.chat_outlined),
                      tooltip: 'Messages',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _openCreatePost(context),
                      tooltip: strings.createPost,
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SegmentedButton<_PostsOwnerSegment>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<_PostsOwnerSegment>(
                  value: _PostsOwnerSegment.mine,
                  label: Text('Mes posts'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment<_PostsOwnerSegment>(
                  value: _PostsOwnerSegment.others,
                  label: Text('Posts des autres'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: {_ownerSegment},
              onSelectionChanged: (selection) {
                final next = selection.first;
                if (next == _ownerSegment) return;
                setState(() {
                  _ownerSegment = next;
                  _currentPage = 1;
                });
              },
            ),
          ),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            initiallyExpanded: _filtersExpanded,
            onExpansionChanged: (v) => setState(() => _filtersExpanded = v),
            title: const Text('Filtres'),
            subtitle: Text(
              _selectedType == null
                  ? strings.allTypes
                  : _selectedType!.displayName,
            ),
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TypeChip(
                          label: 'Smart (mon profil)',
                          selected: _smartProfileFilter,
                          onTap: () {
                            setState(() {
                              _smartProfileFilter = !_smartProfileFilter;
                              _currentPage = 1;
                            });
                          },
                        ),
                      ),
                    _TypeChip(
                      label: strings.allTypes,
                      selected: _selectedType == null,
                      onTap: () => setState(() => _selectedType = null),
                    ),
                    const SizedBox(width: 8),
                    ...PostType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TypeChip(
                          label: type.displayName,
                          selected: _selectedType == type,
                          onTap: () => setState(() => _selectedType = type),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          // (Supprimé) Ancienne bannière d'aide FALC/Ollama.
          // Liste des posts
          Expanded(
            child: postsAsync.when(
              data: (data) {
                final posts = data.posts;
                final totalPages = data.totalPages;
                final matchedTypes = data.matchedTypes;

                // Filtrer par type si sélectionné
                var filtered = posts;
                if (_selectedType != null) {
                  filtered = posts
                      .where((post) => post.type == _selectedType)
                      .toList();
                }

                final hasCurrentUser = currentUserId != null && currentUserId.isNotEmpty;
                filtered = filtered.where((post) {
                  if (!hasCurrentUser) {
                    // Fallback sûr: sans utilisateur courant, "Mes posts" vide,
                    // "Posts des autres" affiche la liste.
                    return _ownerSegment == _PostsOwnerSegment.others;
                  }
                  final authorId = post.userId.trim();
                  final isMine = authorId.isNotEmpty && authorId == currentUserId;
                  return _ownerSegment == _PostsOwnerSegment.mine ? isMine : !isMine;
                }).toList();

                if (filtered.isEmpty) {
                  final emptyTitle = _ownerSegment == _PostsOwnerSegment.mine
                      ? 'Vous n’avez pas encore publié.'
                      : 'Aucune publication des autres pour le moment.';
                  final emptySubtitle = _ownerSegment == _PostsOwnerSegment.mine
                      ? strings.beFirstToPost
                      : 'Revenez plus tard ou publiez votre premier post.';
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emptySubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _openCreatePost(context),
                          icon: const Icon(Icons.add),
                          label: Text(strings.createPost),
                        ),
                      ],
                    ),
                  );
                }

                if (_audioMode != null &&
                    filtered.isNotEmpty &&
                    !_audioStartedForCurrentList) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _audioStartedForCurrentList = true);
                    unawaited(_speakPostsOneByOne(filtered));
                  });
                }

                final listView = RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityFeedProvider((
                      page: _currentPage,
                      limit: _limit,
                      smart: useSmart,
                    )));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_audioMode != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Material(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Mode audio : écoutez les posts puis appuyez sur Volume+ pour choisir.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (useSmart && matchedTypes.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Filtre profil : ${matchedTypes.join(", ")}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final post = filtered[index];
                            return _PostCard(
                              post: post,
                              isMine: hasCurrentUser &&
                                  post.userId.trim().isNotEmpty &&
                                  post.userId.trim() == currentUserId,
                              onTap: _audioMode != null
                                  ? () => _selectAudioPost(
                                        preferredIndex: index,
                                        fallbackPosts: filtered,
                                      )
                                  : () => context.push(
                                        '/post-detail/${post.id}',
                                      ),
                              onJoinLive: () => context.push(
                                '/community-live?postId=${post.id}',
                              ),
                            );
                          },
                        ),
                      ),
                      if (totalPages > 1)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() => _currentPage--);
                                          ref.invalidate(
                                            communityFeedProvider((
                                              page: _currentPage,
                                              limit: _limit,
                                              smart: useSmart,
                                            )),
                                          );
                                        }
                                      : null,
                                ),
                                Text(
                                  '${strings.page} $_currentPage / $totalPages',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages
                                      ? () {
                                          setState(() => _currentPage++);
                                          ref.invalidate(
                                            communityFeedProvider((
                                              page: _currentPage,
                                              limit: _limit,
                                              smart: useSmart,
                                            )),
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                if (_audioMode == null) return listView;
                return Stack(
                  children: [
                    listView,
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectAudioPost(fallbackPosts: filtered),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: theme.colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _audioPaused = !_audioPaused);
                                },
                                icon: Icon(_audioPaused ? Icons.play_arrow : Icons.pause),
                                label: Text(_audioPaused ? 'Reprendre' : 'Pause lecture'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _restartAudioMode(filtered),
                                icon: const Icon(Icons.replay),
                                label: const Text('Recommencer'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _quitAudioMode,
                                icon: const Icon(Icons.close),
                                label: const Text('Quitter mode audio'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.errorLoadingPosts,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(communityFeedProvider((
                        page: _currentPage,
                        limit: _limit,
                        smart: useSmart,
                      ))),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton.extended(
                heroTag: 'community_add_post_fab',
                onPressed: () => _openCreatePost(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter post'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isMine,
    required this.onTap,
    required this.onJoinLive,
  });

  final PostModel post;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback onJoinLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Couleur selon le type
    Color typeColor;
    IconData typeIcon;
    switch (post.type) {
      case PostType.handicapMoteur:
        typeColor = Colors.blue;
        typeIcon = Icons.accessible;
        break;
      case PostType.handicapVisuel:
        typeColor = Colors.orange;
        typeIcon = Icons.visibility;
        break;
      case PostType.handicapAuditif:
        typeColor = Colors.purple;
        typeIcon = Icons.hearing;
        break;
      case PostType.handicapCognitif:
        typeColor = Colors.teal;
        typeIcon = Icons.psychology;
        break;
      case PostType.conseil:
        typeColor = Colors.green;
        typeIcon = Icons.lightbulb;
        break;
      case PostType.temoignage:
        typeColor = Colors.red;
        typeIcon = Icons.favorite;
        break;
      default:
        typeColor = primary;
        typeIcon = Icons.forum;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : utilisateur et type
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeColor.withValues(alpha: 0.12),
                    child: Icon(
                      typeIcon,
                      size: 20,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isMine ? '${post.userName} (vous)' : post.userName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (post.user?.partenaire == true)
                              const PartnerOrgBadge(compact: true),
                            VerifiedHelperBadge(
                              trustPoints: post.user?.trustPoints ?? 0,
                            ),
                          ],
                        ),
                        if (post.createdAt != null)
                          Text(
                            _formatDate(post.createdAt!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.type.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (post.isActiveLive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Contenu
              Text(
                post.contenu,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.images != null && post.images!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    CommunityRepository.uploadUrl(post.images!.first),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (post.isActiveLive)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('${post.viewersCount} spectateurs'),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: onJoinLive,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Rejoindre le live'),
                      ),
                    ],
                  ),
                ),
              if (post.isActiveLive) const SizedBox(height: 2),
              // Footer : commentaires
              Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.merciCount} merci',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.commentsCount != null
                        ? '${post.commentsCount} ${post.commentsCount! > 1 ? "commentaires" : "commentaire"}'
                        : 'Commenter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}

