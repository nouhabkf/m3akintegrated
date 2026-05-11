import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../accessibility/accessibility_post_prefs.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';

/// Onglet Mon Profil : design maquette (photo, infos, cartes, sécurité, déconnexion).
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _isLoadingPhoto = false;
  PostCreationShortcut? _postCreationShortcut;

  @override
  void initState() {
    super.initState();
    AccessibilityPostPrefs.getPostCreationShortcut().then((v) {
      if (mounted) setState(() => _postCreationShortcut = v);
    });
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppStrings strings) {
    final notifier = ref.read(themeModeProvider.notifier);
    final current = ref.read(themeModeProvider);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(strings.themeLight),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) {
                if (v != null) notifier.setThemeMode(v);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(strings.themeDark),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) {
                if (v != null) notifier.setThemeMode(v);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(strings.themeSystem),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) {
                if (v != null) notifier.setThemeMode(v);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _isLoadingPhoto = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.updateProfilePhoto(x);
      ref.read(authStateProvider.notifier).setUser(user);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final strings =
        AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final imageUrl = UserRepository.photoUrl(user.photoProfil);

    String memberSince = strings.memberSince;
    if (user.createdAt != null) {
      const months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      final m = user.createdAt!.month;
      final y = user.createdAt!.year;
      memberSince = '${strings.memberSince} ${months[m - 1]} $y';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Titre
                  Text(
                    strings.myProfile,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Photo + nom + badge + date
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _changePhoto,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.shade100,
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: _isLoadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(32),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : imageUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 64,
                                            color: Colors.orange.shade700,
                                          ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _changePhoto,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 18, color: primary),
                              const SizedBox(width: 6),
                              Text(
                                strings.verifiedUser,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberSince,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cartes stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '12',
                          label: strings.assistedTrips,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '4.9',
                          label: strings.communityRating,
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // INFORMATIONS PERSONNELLES
                  Text(
                    strings.personalInfo,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: 'E-mail',
                    value: user.email,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.phoneNumber,
                    value: user.contact,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.event_note_rounded,
                    iconBg: const Color(0xFF1A237E).withValues(alpha: 0.12),
                    label: 'Mes réservations',
                    value: 'Accès adaptés enregistrés sur cet appareil',
                    onTap: () => context.push('/reservations-history'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.postShortcutSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accessibilité — raccourci + (vibrations fixes : onglet Demandes d’aide)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<PostCreationShortcut>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.postShortcutFormTitle),
                    subtitle: Text(strings.postShortcutFormSubtitle),
                    value: PostCreationShortcut.form,
                    groupValue: _postCreationShortcut,
                    onChanged: _postCreationShortcut == null
                        ? null
                        : (PostCreationShortcut? v) async {
                            if (v == null) return;
                            await AccessibilityPostPrefs.setPostCreationShortcut(v);
                            if (mounted) {
                              setState(() => _postCreationShortcut = v);
                            }
                          },
                  ),
                  RadioListTile<PostCreationShortcut>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.postShortcutHeadTitle),
                    subtitle: Text(strings.postShortcutHeadSubtitle),
                    value: PostCreationShortcut.headGesture,
                    groupValue: _postCreationShortcut,
                    onChanged: _postCreationShortcut == null
                        ? null
                        : (PostCreationShortcut? v) async {
                            if (v == null) return;
                            await AccessibilityPostPrefs.setPostCreationShortcut(v);
                            if (mounted) {
                              setState(() => _postCreationShortcut = v);
                            }
                          },
                  ),
                  RadioListTile<PostCreationShortcut>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.postShortcutVibrationTitle),
                    subtitle: Text(strings.postShortcutVibrationSubtitle),
                    value: PostCreationShortcut.vibration,
                    groupValue: _postCreationShortcut,
                    onChanged: _postCreationShortcut == null
                        ? null
                        : (PostCreationShortcut? v) async {
                            if (v == null) return;
                            await AccessibilityPostPrefs.setPostCreationShortcut(v);
                            if (mounted) {
                              setState(() => _postCreationShortcut = v);
                            }
                          },
                  ),
                  RadioListTile<PostCreationShortcut>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.postShortcutVoiceVibTitle),
                    subtitle: Text(strings.postShortcutVoiceVibSubtitle),
                    value: PostCreationShortcut.voiceVibration,
                    groupValue: _postCreationShortcut,
                    onChanged: _postCreationShortcut == null
                        ? null
                        : (PostCreationShortcut? v) async {
                            if (v == null) return;
                            await AccessibilityPostPrefs.setPostCreationShortcut(v);
                            if (mounted) {
                              setState(() => _postCreationShortcut = v);
                            }
                          },
                  ),
                  const SizedBox(height: 24),
                  // SÉCURITÉ ET SUPPORT
                  Text(
                    strings.securitySupport,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.dark_mode_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.theme,
                    onTap: () => _showThemeDialog(context, ref, strings),
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.emergency_outlined,
                    iconBg: Colors.red.withValues(alpha: 0.12),
                    label: strings.emergencyContacts,
                    onTap: () => context.push('/accompagnants'),
                  ),
                  if (user.isBeneficiary) ...[
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.medical_services_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: 'Dossier médical',
                      onTap: () => context.push('/medical-record'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.history,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.assistanceHistory,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.settings_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.settings,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 24),
                  // Déconnexion
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 22),
                      label: Text(
                        strings.logout,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MA3AK V2.4.0 (TUNISIE)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.primary,
  });

  final String value;
  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (value != null && value!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
