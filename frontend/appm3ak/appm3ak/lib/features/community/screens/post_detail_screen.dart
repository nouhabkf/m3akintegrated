import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/enums/type_handicap.dart';
import '../../../core/l10n/app_strings.dart';
import '../../accessibility/accessibility_post_prefs.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../../../providers/post_detail_assistance_provider.dart';
import '../../../widgets/verified_helper_badge.dart';
import '../logic/post_detail_danger_hint.dart';

/// Écran de détails d'un post avec commentaires.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    required this.postId,
    this.autoReadPost = false,
    this.autoReadComments = false,
    this.autoReadSummary = false,
    this.audioSelectionMode,
    super.key,
  });

  final String postId;
  final bool autoReadPost;
  final bool autoReadComments;
  final bool autoReadSummary;
  final String? audioSelectionMode;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _commentSpeech = stt.SpeechToText();
  bool _isSubmittingComment = false;
  bool _speechReady = false;
  bool _isCommentListening = false;
  bool _commentDictationStarted = false;
  String _commentLocaleId = 'fr_FR';
  List<CommentModel> _ttsCommentsContext = const [];
  int _ttsCommentIndex = -1;
  bool _deletePostBusy = false;
  String? _deletingCommentId;
  /// Évite une double lecture auto si le widget rebuild avant la fin du TTS.
  String? _lastAutoSpeakDedupKey;
  /// Une seule planification auto par chargement de post (évite les callbacks empilés).
  String? _autoSpeakScheduledPostId;
  bool _isTtsSpeaking = false;
  bool _autoReadPrefLoaded = false;
  bool _autoReadSwitchOn = false;
  /// 0 lent, 1 normal, 2 rapide — [AccessibilityPostPrefs.postDetailTtsRateIndex].
  int _ttsRateIndex = 1;
  bool _simplifiedUi = false;
  bool _ttsPaused = false;
  String? _ttsResumeText;
  String? _autoActionDedupKey;

  void _safePopPostDetail() {
    if (!mounted) return;
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        try {
          context.go('/home');
        } catch (_) {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTts());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPostDetailAccessibilityPrefs());
  }

  @override
  void didUpdateWidget(PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _lastAutoSpeakDedupKey = null;
      _autoSpeakScheduledPostId = null;
      _autoActionDedupKey = null;
    }
  }

  Future<void> _runRouteAutoActions(PostModel post) async {
    final dedup =
        '${post.id}|${widget.autoReadPost}|${widget.autoReadComments}|${widget.autoReadSummary}|${widget.audioSelectionMode ?? ''}';
    if (_autoActionDedupKey == dedup) return;
    _autoActionDedupKey = dedup;
    if (widget.audioSelectionMode == 'readPost') {
      final imageCount = post.images?.length ?? 0;
      final imageInfo = imageCount > 0
          ? 'Ce post contient $imageCount image${imageCount > 1 ? 's' : ''}.'
          : 'Ce post ne contient pas d image.';
      await _speakDescription('${_ttsReadableForPost(post)} $imageInfo');
      await _speakDescription('Voulez-vous commenter avec la voix ?');
      return;
    }
    if (widget.audioSelectionMode == 'readComments') {
      final comments = await ref.read(postCommentsProvider(widget.postId).future);
      if (comments.isEmpty) {
        await _speakDescription('Aucun commentaire');
        await _speakDescription('Voulez-vous commenter avec la voix ?');
        return;
      }
      final text = comments
          .asMap()
          .entries
          .map((e) => _commentReadableLine(e.value, e.key, comments.length))
          .join(' ');
      await _speakDescription(text);
      await _speakDescription('Voulez-vous commenter avec la voix ?');
      return;
    }
    if (widget.audioSelectionMode == 'voiceComment') {
      await _speakDescription('Vous pouvez commenter avec votre voix');
      if (!_isCommentListening) {
        await _toggleCommentVoiceInput();
      }
      return;
    }
    if (widget.autoReadPost) {
      await _speakDescription(_ttsReadableForPost(post));
    }
    if (widget.autoReadComments) {
      final comments = await ref.read(postCommentsProvider(widget.postId).future);
      if (comments.isNotEmpty) {
        await _readAllComments(comments);
      }
    }
    if (widget.autoReadSummary) {
      final r = await ref.read(
        postDetailAssistancePostSummaryProvider(widget.postId).future,
      );
      final summary = r.summary.trim();
      if (summary.isNotEmpty) {
        await _speakDescription(summary);
      }
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isTtsSpeaking = false;
        if (!_ttsPaused) _ttsResumeText = null;
      });
    });
    _flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isTtsSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isTtsSpeaking = false);
    });
  }

  Future<void> _loadPostDetailAccessibilityPrefs() async {
    if (_autoReadPrefLoaded) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final visual =
        TypeHandicap.fromApiString(user?.typeHandicap) == TypeHandicap.visuel;
    final on = await AccessibilityPostPrefs.effectivePostDetailAutoRead(
      visualProfileDefault: visual,
    );
    final rateIdx = await AccessibilityPostPrefs.postDetailTtsRateIndex();
    final simple = await AccessibilityPostPrefs.postDetailSimplifiedUi();
    if (!mounted) return;
    setState(() {
      _autoReadPrefLoaded = true;
      _autoReadSwitchOn = on;
      _ttsRateIndex = rateIdx;
      _simplifiedUi = simple;
    });
    await _applySpeechRate();
  }

  Future<void> _setSimplifiedUi(bool value) async {
    await AccessibilityPostPrefs.setPostDetailSimplifiedUi(value);
    if (!mounted) return;
    setState(() => _simplifiedUi = value);
  }

  Future<void> _applySpeechRate() async {
    final r = AccessibilityPostPrefs.speechRateForTtsIndex(_ttsRateIndex);
    await _flutterTts.setSpeechRate(r);
  }

  Future<void> _setTtsRateIndex(int index) async {
    final i = index.clamp(0, 2);
    await AccessibilityPostPrefs.setPostDetailTtsRateIndex(i);
    if (!mounted) return;
    setState(() => _ttsRateIndex = i);
    await _applySpeechRate();
  }

  Future<void> _setAutoReadEnabled(bool value) async {
    await AccessibilityPostPrefs.setPostDetailAutoReadEnabled(value);
    if (!mounted) return;
    setState(() {
      _autoReadSwitchOn = value;
      _autoReadPrefLoaded = true;
    });
  }

  @override
  void dispose() {
    unawaited(_commentSpeech.stop());
    _flutterTts.stop();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _ensureCommentSpeechReady() async {
    if (_speechReady) return;
    if (kIsWeb) return;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autorisez le micro pour dicter un commentaire.')),
      );
      return;
    }
    final ok = await _commentSpeech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _speechReady = false;
          _isCommentListening = false;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isCommentListening = false);
        }
      },
    );
    var localeId = 'fr_FR';
    try {
      final locales = await _commentSpeech.locales();
      final fr = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('fr'),
        orElse: () => locales.isNotEmpty
            ? locales.first
            : stt.LocaleName('fr_FR', 'French'),
      );
      localeId = fr.localeId;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _speechReady = ok;
      _commentLocaleId = localeId;
    });
  }

  Future<void> _toggleCommentVoiceInput() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La dictée commentaire nécessite l’application mobile.')),
      );
      return;
    }
    if (_isCommentListening) {
      await _commentSpeech.stop();
      if (mounted) setState(() => _isCommentListening = false);
      return;
    }
    await _ensureCommentSpeechReady();
    if (!_speechReady || !mounted) return;
    setState(() {
      _isCommentListening = true;
      _commentDictationStarted = true;
    });
    await _speakDescription('Dictée du commentaire démarrée. Parlez maintenant.');
    try {
      await _commentSpeech.listen(
        localeId: _commentLocaleId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
        onResult: (r) {
          if (!mounted) return;
          final text = r.recognizedWords.trim();
          if (text.isEmpty) return;
          setState(() {
            _commentController.text = text;
            _commentController.selection = TextSelection.fromPosition(
              TextPosition(offset: _commentController.text.length),
            );
          });
          if (r.finalResult) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Votre commentaire vocal est prêt.')),
            );
            unawaited(
              _speakDescription(
                'Commentaire prêt. Vous pouvez publier ou réessayer.',
              ),
            );
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCommentListening = false);
    }
  }

  Future<void> _retryCommentVoiceInput() async {
    if (_isCommentListening) {
      await _commentSpeech.stop();
      if (mounted) setState(() => _isCommentListening = false);
    }
    if (!mounted) return;
    _commentController.clear();
    await _toggleCommentVoiceInput();
  }

  Future<void> _cancelCommentVoiceInput() async {
    if (_isCommentListening) {
      await _commentSpeech.stop();
    }
    if (!mounted) return;
    setState(() {
      _isCommentListening = false;
      _commentController.clear();
    });
  }

  String _commentReadableLine(CommentModel c, int idx, int total) {
    final name = c.userName.trim().isEmpty ? 'Utilisateur' : c.userName.trim();
    return 'Commentaire ${idx + 1} sur $total. $name. ${c.contenu.trim()}';
  }

  Future<void> _readCommentAtIndex(List<CommentModel> comments, int index) async {
    if (comments.isEmpty) return;
    final safe = index.clamp(0, comments.length - 1);
    if (_ttsCommentIndex == -1 || _ttsCommentsContext.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Lecture des commentaires commencée.')),
      );
    }
    setState(() {
      _ttsCommentsContext = List<CommentModel>.from(comments);
      _ttsCommentIndex = safe;
    });
    await _speakDescription(_commentReadableLine(
      comments[safe],
      safe,
      comments.length,
    ));
  }

  Future<void> _readAllComments(List<CommentModel> comments) async {
    if (comments.isEmpty) return;
    setState(() {
      _ttsCommentsContext = List<CommentModel>.from(comments);
      _ttsCommentIndex = 0;
    });
    final text = comments
        .asMap()
        .entries
        .map((e) => _commentReadableLine(e.value, e.key, comments.length))
        .join(' ');
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Lecture des commentaires commencée.')),
    );
    await _speakDescription(text);
    await _speakDescription(
      'Lecture des commentaires terminée. '
      'Voulez-vous commenter par voix ? Touchez la grande zone en bas de l’écran.',
    );
  }

  Future<void> _readPreviousComment() async {
    if (_ttsCommentsContext.isEmpty) return;
    final prev = (_ttsCommentIndex <= 0) ? 0 : _ttsCommentIndex - 1;
    await _readCommentAtIndex(_ttsCommentsContext, prev);
  }

  Future<void> _readNextComment() async {
    if (_ttsCommentsContext.isEmpty) return;
    final next = (_ttsCommentIndex < 0)
        ? 0
        : (_ttsCommentIndex >= _ttsCommentsContext.length - 1)
            ? _ttsCommentsContext.length - 1
            : _ttsCommentIndex + 1;
    await _readCommentAtIndex(_ttsCommentsContext, next);
  }

  Future<void> _replayCurrentComment() async {
    if (_ttsCommentsContext.isEmpty || _ttsCommentIndex < 0) return;
    await _readCommentAtIndex(_ttsCommentsContext, _ttsCommentIndex);
  }

  String _ttsReadableForPost(PostModel post) {
    return ref.read(postDetailAssistanceProvider).buildTtsReadablePost(post);
  }

  Future<void> _runAutoSpeakIfEligible(PostModel post) async {
    await _loadPostDetailAccessibilityPrefs();
    if (!mounted || !_autoReadSwitchOn) return;
    final t = _ttsReadableForPost(post).trim();
    if (t.isEmpty) return;
    final dedupKey = '${post.id}|${t.hashCode}';
    if (_lastAutoSpeakDedupKey == dedupKey) return;
    _lastAutoSpeakDedupKey = dedupKey;
    await _speakDescription(t);
  }

  Future<void> _speakDescription(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      _ttsResumeText = t;
      _ttsPaused = false;
      // Langue TTS selon préférence utilisateur (FR/AR).
      final user = ref.read(authStateProvider).valueOrNull;
      final lang = (user?.preferredLanguage?.name ?? '').toLowerCase();
      final ttsLang = lang == 'ar' ? 'ar' : 'fr-FR';
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isTtsSpeaking = true;
          _ttsPaused = false;
        });
      }
      await _applySpeechRate();
      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.speak(t);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTtsSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Synthèse vocale (web) indisponible : essayez la voix du navigateur.'
                : 'Synthèse vocale indisponible.',
          ),
        ),
      );
    }
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isTtsSpeaking = false;
        _ttsPaused = false;
        _ttsResumeText = null;
      });
    }
  }

  Future<void> _pauseTts() async {
    if (!_isTtsSpeaking) return;
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isTtsSpeaking = false;
        _ttsPaused = true;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await ref.read(createCommentProvider((
        postId: widget.postId,
        contenu: _commentController.text.trim(),
      )).future);

      _commentController.clear();
      await ref.read(authStateProvider.notifier).refreshUser();
      ref.invalidate(postCommentsProvider(widget.postId));
      // Rafraîchir le post pour mettre à jour le nombre de commentaires
      ref.invalidate(postByIdProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _confirmDeletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce post'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce post ? Cette action est définitive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletePostBusy = true);
    try {
      await ref.read(communityRepositoryProvider).deletePost(widget.postId);
      ref.invalidate(communityFeedProvider((page: 1, limit: 20, smart: false)));
      ref.invalidate(communityFeedProvider((page: 1, limit: 20, smart: true)));
      ref.invalidate(postByIdProvider(widget.postId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _deletePostBusy = false);
    }
  }

  bool _canDeleteComment({
    required PostModel post,
    required CommentModel comment,
    required dynamic user,
  }) {
    if (user == null) return false;
    return user.isAdmin == true ||
        comment.userId == user.id ||
        post.userId == user.id;
  }

  Future<void> _confirmDeleteComment({
    required PostModel post,
    required CommentModel comment,
  }) async {
    if (_deletingCommentId != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce commentaire'),
        content: const Text('Confirmer la suppression de ce commentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingCommentId = comment.id);
    try {
      await ref.read(communityRepositoryProvider).deleteComment(
            postId: post.id,
            commentId: comment.id,
          );
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(postByIdProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingCommentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    final postAsync = ref.watch(postByIdProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final assistedSummaryAsync =
        ref.watch(postDetailAssistancePostSummaryProvider(widget.postId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: _safePopPostDetail),
        title: Text(strings.postDetails),
        actions: [
          IconButton(
            tooltip: _simplifiedUi
                ? 'Affichage habituel'
                : 'Interface simplifiée (gros texte, moins de détail)',
            icon: Icon(
              _simplifiedUi
                  ? Icons.view_compact_alt_outlined
                  : Icons.accessibility_new,
            ),
            onPressed: () => _setSimplifiedUi(!_simplifiedUi),
          ),
          if (user?.isAdmin == true)
            PopupMenuButton<String>(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Modération',
              onSelected: (v) {
                if (v == 'delete') _confirmDeletePost();
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Supprimer ce post'),
                    subtitle: Text('Spam ou photo inappropriée'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          final hasContent = post.contenu.trim().isNotEmpty;
          final canDeletePost = user != null &&
              (user.isAdmin == true || post.userId == user.id);
          final dangerMsg = postDetailDangerBannerMessage(post);
          final dl = post.dangerLevel?.toLowerCase().trim() ?? '';
          final showRedDangerBanner =
              dl == 'critical' || dl == 'high';
          final pad = _simplifiedUi ? 20.0 : 16.0;
          final sectionTitleStyle = _simplifiedUi
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                )
              : theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                );
          final bodyStyle = _simplifiedUi
              ? theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                )
              : theme.textTheme.bodyLarge?.copyWith(height: 1.45);

          /// Lecture auto une fois les données disponibles (préférence profil ou réglage).
          if (hasContent && _autoSpeakScheduledPostId != post.id) {
            _autoSpeakScheduledPostId = post.id;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _runAutoSpeakIfEligible(post);
            });
          }
          if ((widget.autoReadPost ||
                  widget.autoReadComments ||
                  widget.autoReadSummary ||
                  widget.audioSelectionMode != null) &&
              _autoActionDedupKey == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              await _runRouteAutoActions(post);
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PostHeader(post: post),
                      if (showRedDangerBanner) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: Material(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      dangerMsg ??
                                          'Ce signalement est marqué comme à risque élevé ou critique. '
                                          'Restez prudent et demandez de l’aide si nécessaire.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: _simplifiedUi ? 1.5 : 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.28),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(_simplifiedUi ? 18 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  _simplifiedUi ? 'Texte du post' : 'Contenu du post',
                                  style: sectionTitleStyle,
                                ),
                              ),
                              const SizedBox(height: 10),
                      Text(
                        post.contenu,
                                style: bodyStyle,
                                softWrap: true,
                      ),
                      if (post.images != null && post.images!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                        ...post.images!.map((path) {
                          final url = CommunityRepository.uploadUrl(path);
                          return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return SizedBox(
                                            height: 180,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                                value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                        errorBuilder: (_, _, _) => Container(
                                  height: 120,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                              const SizedBox(height: 12),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Semantics(
                                  hint:
                                      'Active ou désactive la lecture vocale automatique '
                                      'du post à l\'ouverture.',
                                  child: Text(
                                    'Lecture automatique à l\'ouverture',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  _autoReadPrefLoaded
                                      ? 'Une fois le post affiché. Par défaut actif '
                                          'pour les profils malvoyants jusqu’à votre choix.'
                                      : 'Chargement du réglage…',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: _autoReadSwitchOn,
                                onChanged: !_autoReadPrefLoaded || !hasContent
                                    ? null
                                    : _setAutoReadEnabled,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      label: hasContent
                                          ? 'Lire le post avec la synthèse vocale'
                                          : 'Contenu vide',
                                      child: FilledButton.tonalIcon(
                                        onPressed: !hasContent ||
                                                (_isTtsSpeaking && !_ttsPaused)
                                            ? null
                                            : () {
                                                if (_ttsPaused &&
                                                    _ttsResumeText != null) {
                                                  _speakDescription(
                                                    _ttsResumeText!,
                                                  );
                                                } else {
                                                  _speakDescription(
                                                    _ttsReadableForPost(post),
                                                  );
                                                }
                                              },
                                        style: FilledButton.styleFrom(
                                          minimumSize: Size(
                                            double.infinity,
                                            _simplifiedUi ? 54 : 48,
                                          ),
                                        ),
                                        icon: Icon(
                                          _ttsPaused
                                              ? Icons.play_arrow_rounded
                                              : Icons.volume_up_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                        label: Text(
                                          _ttsPaused
                                              ? 'Reprendre'
                                              : '\u{1F50A} Lire le post',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Semantics(
                                    button: true,
                                    label: 'Pause lecture vocale',
                                    child: IconButton.filledTonal(
                                      tooltip: 'Pause',
                                      icon: const Icon(Icons.pause_rounded),
                                      style: IconButton.styleFrom(
                                        minimumSize: Size(
                                          52,
                                          _simplifiedUi ? 54 : 48,
                                        ),
                                      ),
                                      onPressed: (_isTtsSpeaking && !_ttsPaused)
                                          ? _pauseTts
                                          : null,
                                    ),
                                  ),
                                  Semantics(
                                    button: true,
                                    label: 'Arrêter la synthèse vocale',
                                    child: IconButton.filledTonal(
                                      tooltip: 'Arrêter',
                                      icon: const Icon(Icons.stop_circle_outlined),
                                      style: IconButton.styleFrom(
                                        minimumSize: Size(
                                          52,
                                          _simplifiedUi ? 54 : 48,
                                        ),
                                      ),
                                      onPressed: (_isTtsSpeaking || _ttsPaused)
                                          ? _stopTts
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Semantics(
                                button: true,
                                label: 'Contacter l auteur de ce post',
                                child: FilledButton.icon(
                                  onPressed: post.userId.trim().isEmpty
                                      ? null
                                      : () => context.push(
                                            '/chat/${post.userId}?name=${Uri.encodeComponent(post.userName)}',
                                          ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: Size(
                                      double.infinity,
                                      _simplifiedUi ? 56 : 50,
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('💬 Contacter l’auteur'),
                                ),
                              ),
                              if (_autoReadPrefLoaded) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Vitesse de la voix',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  label:
                                      'Choisir la vitesse de lecture : lent, normal ou rapide',
                                  child: SegmentedButton<int>(
                                    segments: const [
                                      ButtonSegment<int>(
                                        value: 0,
                                        label: Text('Lent'),
                                        icon: Icon(Icons.slow_motion_video_outlined),
                                      ),
                                      ButtonSegment<int>(
                                        value: 1,
                                        label: Text('Normal'),
                                      ),
                                      ButtonSegment<int>(
                                        value: 2,
                                        label: Text('Rapide'),
                                        icon: Icon(Icons.fast_forward_outlined),
                                      ),
                                    ],
                                    selected: {_ttsRateIndex},
                                    onSelectionChanged: (s) {
                                      final v = s.first;
                                      _setTtsRateIndex(v);
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      assistedSummaryAsync.when(
                        data: (r) {
                          if (r.summary.trim().isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: _simplifiedUi ? 1.5 : 0.5,
                            color: theme.colorScheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(_simplifiedUi ? 18 : 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.psychology_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Résumé assisté',
                                          style: sectionTitleStyle?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    r.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: (_simplifiedUi
                                            ? theme.textTheme.bodyLarge
                                            : theme.textTheme.bodyMedium)
                                        ?.copyWith(height: 1.35),
                                  ),
                                  ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    childrenPadding: EdgeInsets.zero,
                                    title: const Text('Voir plus'),
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Text(
                                            r.summary,
                                            style: (_simplifiedUi
                                                    ? theme.textTheme.bodyLarge
                                                    : theme.textTheme.bodyMedium)
                                                ?.copyWith(height: 1.45),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton.icon(
                                          onPressed: !_isTtsSpeaking
                                              ? () => _speakDescription(r.summary)
                                              : null,
                                          icon: const Icon(Icons.volume_up_outlined),
                                          label: const Text('Écouter ce résumé'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Préparation du résumé assisté…',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      if (canDeletePost) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _deletePostBusy ? null : _confirmDeletePost,
                            icon: _deletePostBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.delete_outline),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            label: const Text('Supprimer ce post'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Commentaires directement après le post.
                      // Commentaires
                      Text(
                        strings.comments,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Liste des commentaires
                      commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 34,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                  strings.noComments,
                                      textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Semantics(
                                    button: true,
                                    label: 'Lire les commentaires un par un',
                                    child: FilledButton.tonalIcon(
                                      onPressed: !_isTtsSpeaking
                                          ? () => _readCommentAtIndex(comments, 0)
                                          : null,
                                      icon: const Icon(Icons.record_voice_over_outlined),
                                      label: const Text('Lire les commentaires'),
                                    ),
                                  ),
                                  Semantics(
                                    button: true,
                                    label: 'Lire tout les commentaires',
                                    child: OutlinedButton.icon(
                                      onPressed: !_isTtsSpeaking
                                          ? () => _readAllComments(comments)
                                          : null,
                                      icon: const Icon(Icons.forum_outlined),
                                      label: const Text('Lire tout'),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (!_isTtsSpeaking && _ttsCommentsContext.isNotEmpty)
                                        ? _readPreviousComment
                                        : null,
                                    icon: const Icon(Icons.skip_previous),
                                    label: const Text('Précédent'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (!_isTtsSpeaking && _ttsCommentsContext.isNotEmpty)
                                        ? _readNextComment
                                        : null,
                                    icon: const Icon(Icons.skip_next),
                                    label: const Text('Suivant'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (!_isTtsSpeaking &&
                                            _ttsCommentsContext.isNotEmpty &&
                                            _ttsCommentIndex >= 0)
                                        ? _replayCurrentComment
                                        : null,
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Replay'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (_isTtsSpeaking && !_ttsPaused)
                                        ? _pauseTts
                                        : null,
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Pause'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: (_isTtsSpeaking || _ttsPaused)
                                        ? _stopTts
                                        : null,
                                    icon: const Icon(Icons.stop_circle_outlined),
                                    label: const Text('Stop'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                            children: comments.map((comment) {
                                      return _CommentCard(
                                        comment: comment,
                                        canDelete: _canDeleteComment(
                                          post: post,
                                          comment: comment,
                                          user: user,
                                        ),
                                        deleting: _deletingCommentId == comment.id,
                                        onDelete: () => _confirmDeleteComment(
                                          post: post,
                                          comment: comment,
                                        ),
                                      );
                            }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Text(
                            strings.errorLoadingComments,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                child: SafeArea(
                  child: Semantics(
                    container: true,
                    label: 'Saisie de commentaire',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: strings.writeComment,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                        ),
                        const SizedBox(height: 10),
                        Semantics(
                          button: true,
                          label:
                              'Commenter avec la voix. Touchez ici pour dicter votre commentaire.',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _isSubmittingComment
                                ? null
                                : () => _toggleCommentVoiceInput(),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isCommentListening
                                      ? const [Color(0xFF0EA5E9), Color(0xFF1D4ED8)]
                                      : const [Color(0xFF6366F1), Color(0xFF7C3AED)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isCommentListening ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isCommentListening
                                                ? 'Arrêter la dictée vocale'
                                                : 'Commenter avec la voix',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isCommentListening
                                                ? 'Écoute en cours... touchez pour arrêter'
                                                : 'Touchez ici pour dicter votre commentaire',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.95),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            FilledButton.icon(
                        onPressed: _isSubmittingComment ? null : _submitComment,
                        icon: _isSubmittingComment
                            ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Publier'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isSubmittingComment ? null : _retryCommentVoiceInput,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isSubmittingComment ? null : _cancelCommentVoiceInput,
                              icon: const Icon(Icons.close),
                              label: const Text('Annuler'),
                            ),
                          ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                strings.errorLoadingPost,
                  textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(strings.goBack),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: typeColor.withValues(alpha: 0.12),
          child: Icon(typeIcon, size: 24, color: typeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                if (post.user?.partenaire == true)
                  const PartnerOrgBadge(compact: true),
                VerifiedHelperBadge(
                  trustPoints: post.user?.trustPoints ?? 0,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.badge_outlined,
                  label: post.type.displayName,
              color: typeColor,
                ),
                if ((post.targetAudience ?? '').trim().isNotEmpty)
                  _MetaChip(
                    icon: Icons.groups_2_outlined,
                    label: post.targetAudience!,
                  ),
                if ((post.postNature ?? '').trim().isNotEmpty)
                  _MetaChip(
                    icon: Icons.category_outlined,
                    label: post.postNature!,
                  ),
                if (post.obstaclePresent)
                  _MetaChip(
                    icon: Icons.warning_amber_outlined,
                    label: 'Obstacle signalé',
                    color: primary,
                  ),
              ],
            ),
          ],
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

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.canDelete,
    required this.deleting,
    required this.onDelete,
  });

  final CommentModel comment;
  final bool canDelete;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.person,
                size: 18,
                color: primary,
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
                    comment.userName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                        ),
                      ),
                      if (comment.user?.partenaire == true)
                        const PartnerOrgBadge(compact: true),
                      VerifiedHelperBadge(
                        trustPoints: comment.user?.trustPoints ?? 0,
                      ),
                      if (canDelete)
                        IconButton(
                          tooltip: 'Supprimer le commentaire',
                          onPressed: deleting ? null : onDelete,
                          icon: deleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  if (comment.createdAt != null)
                    Text(
                      _formatDate(comment.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    comment.contenu,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


