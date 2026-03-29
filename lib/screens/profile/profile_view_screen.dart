import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/candidate_profile.dart';


/// Universal candidate profile detail viewer.
/// Shows all details of a candidate profile in a beautiful card layout.
class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  CandidateProfile? _profile;
  bool _loading = true;

  bool _hasLifestyleInfo(CandidateProfile p) =>
      p.diet != null ||
      (p.annualIncome != null && p.annualIncome!.isNotEmpty) ||
      (p.complexion != null && p.complexion!.isNotEmpty) ||
      p.smokes != null ||
      p.drinks != null ||
      p.ownHouse != null ||
      p.ownCar != null ||
      p.willingToRelocate != null;

  bool _hasHoroscopeInfo(CandidateProfile p) =>
      (p.rashi != null && p.rashi!.isNotEmpty) ||
      (p.nakshatra != null && p.nakshatra!.isNotEmpty) ||
      (p.birthPlace != null && p.birthPlace!.isNotEmpty) ||
      (p.birthTime != null && p.birthTime!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final profileId = GoRouterState.of(context).pathParameters['id'];
    if (profileId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = await profileRepo.getCandidateProfile(profileId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = _profile;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: Center(child: Text(context.l10n.profileNotFound)),
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
                      AppSpacing.gapH12,
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapH4,
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
              padding: AppSpacing.allMd,
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
                  AppSpacing.gapH16,

                  // Profile completeness indicator
                  _ProfileCompletenessBar(
                    completeness: profile.profileCompleteness,
                    isDark: isDark,
                  ),
                  AppSpacing.gapH24,

                  // About Me
                  if (profile.aboutMe.isNotEmpty) ...[
                    _SectionTitle('About Me'),
                    AppSpacing.gapH8,
                    Text(
                      profile.aboutMe,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapH24,
                  ],

                  // Professional & Education
                  _SectionTitle('Professional & Education'),
                  AppSpacing.gapH12,
                  _DetailRow(
                    icon: Icons.work_outline,
                    label: context.l10n.professionLabel,
                    value: profile.profession,
                    isDark: isDark,
                  ),
                  _DetailRow(
                    icon: Icons.school_outlined,
                    label: context.l10n.educationLabel,
                    value: profile.education,
                    isDark: isDark,
                  ),
                  AppSpacing.gapH24,

                  // Community & Background
                  _SectionTitle('Community & Background'),
                  AppSpacing.gapH12,
                  if (profile.community.isNotEmpty)
                    _DetailRow(
                      icon: Icons.group_outlined,
                      label: context.l10n.community,
                      value: profile.community,
                      isDark: isDark,
                    ),
                  if (profile.caste.isNotEmpty)
                    _DetailRow(
                      icon: Icons.account_tree_outlined,
                      label: context.l10n.caste,
                      value: profile.caste,
                      isDark: isDark,
                    ),
                  if (profile.gotra != null && profile.gotra!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.family_restroom,
                      label: context.l10n.gotra,
                      value: profile.gotra!,
                      isDark: isDark,
                    ),
                  if (profile.manglikStatus != null && profile.manglikStatus!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.auto_awesome,
                      label: context.l10n.manglikStatus,
                      value: profile.manglikStatus!,
                      isDark: isDark,
                    ),
                  AppSpacing.gapH24,

                  // Lifestyle & Personal
                  if (_hasLifestyleInfo(profile)) ...[
                    _SectionTitle('Lifestyle & Personal'),
                    AppSpacing.gapH12,
                    if (profile.diet != null)
                      _DetailRow(
                        icon: Icons.restaurant,
                        label: context.l10n.dietLabel,
                        value: profile.diet!.name[0].toUpperCase() +
                            profile.diet!.name.substring(1),
                        isDark: isDark,
                      ),
                    if (profile.annualIncome != null && profile.annualIncome!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.currency_rupee,
                        label: context.l10n.annualIncome,
                        value: profile.annualIncome!,
                        isDark: isDark,
                      ),
                    if (profile.complexion != null && profile.complexion!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.face,
                        label: context.l10n.complexion,
                        value: profile.complexion!,
                        isDark: isDark,
                      ),
                    if (profile.smokes != null)
                      _DetailRow(
                        icon: Icons.smoking_rooms,
                        label: context.l10n.smoking,
                        value: profile.smokes! ? context.l10n.yes : context.l10n.no,
                        isDark: isDark,
                      ),
                    if (profile.drinks != null)
                      _DetailRow(
                        icon: Icons.local_bar,
                        label: context.l10n.drinking,
                        value: profile.drinks! ? context.l10n.yes : context.l10n.no,
                        isDark: isDark,
                      ),
                    if (profile.ownHouse != null)
                      _DetailRow(
                        icon: Icons.home,
                        label: context.l10n.ownHouse,
                        value: profile.ownHouse! ? context.l10n.yes : context.l10n.no,
                        isDark: isDark,
                      ),
                    if (profile.ownCar != null)
                      _DetailRow(
                        icon: Icons.directions_car,
                        label: context.l10n.ownCar,
                        value: profile.ownCar! ? context.l10n.yes : context.l10n.no,
                        isDark: isDark,
                      ),
                    if (profile.willingToRelocate != null)
                      _DetailRow(
                        icon: Icons.flight,
                        label: context.l10n.willingToRelocate,
                        value: profile.willingToRelocate! ? context.l10n.yes : context.l10n.no,
                        isDark: isDark,
                      ),
                    AppSpacing.gapH24,
                  ],

                  // Horoscope
                  if (_hasHoroscopeInfo(profile)) ...[
                    _SectionTitle('Horoscope Details'),
                    AppSpacing.gapH12,
                    if (profile.rashi != null && profile.rashi!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.auto_awesome,
                        label: context.l10n.rashi,
                        value: profile.rashi!,
                        isDark: isDark,
                      ),
                    if (profile.nakshatra != null && profile.nakshatra!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.star_outline,
                        label: context.l10n.nakshatra,
                        value: profile.nakshatra!,
                        isDark: isDark,
                      ),
                    if (profile.birthPlace != null && profile.birthPlace!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: context.l10n.birthPlace,
                        value: profile.birthPlace!,
                        isDark: isDark,
                      ),
                    if (profile.birthTime != null && profile.birthTime!.isNotEmpty)
                      _DetailRow(
                        icon: Icons.access_time,
                        label: context.l10n.birthTime,
                        value: profile.birthTime!,
                        isDark: isDark,
                      ),
                    AppSpacing.gapH24,
                  ],

                  // Family
                  if (profile.familyBackground.isNotEmpty) ...[
                    _SectionTitle('Family Background'),
                    AppSpacing.gapH8,
                    Text(
                      profile.familyBackground,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapH12,
                  ],
                  if (profile.familyType != null)
                    _DetailRow(
                      icon: Icons.family_restroom,
                      label: context.l10n.familyTypeLabel,
                      value: profile.familyType!.name[0].toUpperCase() +
                          profile.familyType!.name.substring(1),
                      isDark: isDark,
                    ),
                  if (profile.familyValues != null)
                    _DetailRow(
                      icon: Icons.balance,
                      label: context.l10n.familyValues,
                      value: profile.familyValues!.name[0].toUpperCase() +
                          profile.familyValues!.name.substring(1),
                      isDark: isDark,
                    ),
                  if (profile.fatherOccupation.isNotEmpty)
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: context.l10n.fatherOccupationLabel,
                      value: profile.fatherOccupation,
                      isDark: isDark,
                    ),
                  if (profile.motherOccupation.isNotEmpty)
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: context.l10n.motherOccupationLabel,
                      value: profile.motherOccupation,
                      isDark: isDark,
                    ),
                  if (profile.siblings.isNotEmpty)
                    _DetailRow(
                      icon: Icons.people_outline,
                      label: context.l10n.siblings,
                      value: profile.siblings,
                      isDark: isDark,
                    ),
                  if (profile.numberOfBrothers != null)
                    _DetailRow(
                      icon: Icons.boy,
                      label: context.l10n.brothers,
                      value: '${profile.numberOfBrothers}',
                      isDark: isDark,
                    ),
                  if (profile.numberOfSisters != null)
                    _DetailRow(
                      icon: Icons.girl,
                      label: context.l10n.sisters,
                      value: '${profile.numberOfSisters}',
                      isDark: isDark,
                    ),
                  AppSpacing.gapH24,

                  // Interests
                  if (profile.interests.isNotEmpty) ...[
                    _SectionTitle('Interests & Hobbies'),
                    AppSpacing.gapH12,
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                        );
                      }).toList(),
                    ),
                    AppSpacing.gapH24,
                  ],

                  // Visibility badge
                  Container(
                    padding: AppSpacing.allSm,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: AppSpacing.roundedMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Text(
                            'Profile visibility: ${profile.visibility.displayName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH32,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.gapW12,
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
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppSpacing.roundedXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.gapW4,
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletenessBar extends StatelessWidget {
  final int completeness;
  final bool isDark;

  const _ProfileCompletenessBar({
    required this.completeness,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completeness >= 80
        ? AppColors.success
        : completeness >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: AppSpacing.allSm,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completeness',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '$completeness%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          ClipRRect(
            borderRadius: AppSpacing.roundedXs,
            child: LinearProgressIndicator(
              value: completeness / 100.0,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
