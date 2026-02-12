import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';


/// Universal candidate profile detail viewer.
/// Shows all details of a candidate profile in a beautiful card layout.
class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = ref.watch(localStorageServiceProvider);

    // Get profile ID from route params
    final profileId = GoRouterState.of(context).pathParameters['id'];
    final profile = profileId != null
        ? storage.getCandidateProfile(profileId)
        : null;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sacredSaffron,
                      AppColors.deepMaroon,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.snippet,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.cake, label: '${profile.age} yrs'),
                      _InfoChip(icon: Icons.height, label: profile.height),
                      _InfoChip(icon: Icons.location_on, label: profile.city),
                      if (profile.religion.isNotEmpty)
                        _InfoChip(icon: Icons.temple_hindu, label: profile.religion),
                      if (profile.motherTongue.isNotEmpty)
                        _InfoChip(icon: Icons.language, label: profile.motherTongue),
                      _InfoChip(
                        icon: Icons.ring_volume,
                        label: profile.maritalStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Me
                  if (profile.aboutMe.isNotEmpty) ...[
                    _SectionTitle('About Me'),
                    const SizedBox(height: 8),
                    Text(
                      profile.aboutMe,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Professional & Education
                  _SectionTitle('Professional & Education'),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.work_outline,
                    label: 'Profession',
                    value: profile.profession,
                    isDark: isDark,
                  ),
                  _DetailRow(
                    icon: Icons.school_outlined,
                    label: 'Education',
                    value: profile.education,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Community & Background
                  _SectionTitle('Community & Background'),
                  const SizedBox(height: 12),
                  if (profile.community.isNotEmpty)
                    _DetailRow(
                      icon: Icons.group_outlined,
                      label: 'Community',
                      value: profile.community,
                      isDark: isDark,
                    ),
                  if (profile.caste.isNotEmpty)
                    _DetailRow(
                      icon: Icons.account_tree_outlined,
                      label: 'Caste',
                      value: profile.caste,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 24),

                  // Family
                  if (profile.familyBackground.isNotEmpty) ...[
                    _SectionTitle('Family Background'),
                    const SizedBox(height: 8),
                    Text(
                      profile.familyBackground,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (profile.fatherOccupation.isNotEmpty)
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: "Father's Occupation",
                      value: profile.fatherOccupation,
                      isDark: isDark,
                    ),
                  if (profile.motherOccupation.isNotEmpty)
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: "Mother's Occupation",
                      value: profile.motherOccupation,
                      isDark: isDark,
                    ),
                  if (profile.siblings.isNotEmpty)
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: 'Siblings',
                      value: profile.siblings,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 24),

                  // Interests
                  if (profile.interests.isNotEmpty) ...[
                    _SectionTitle('Interests & Hobbies'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: AppColors.sacredSaffron
                              .withValues(alpha: 0.1),
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.sacredSaffron,
                          ),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Visibility badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Profile visibility: ${profile.visibility.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
