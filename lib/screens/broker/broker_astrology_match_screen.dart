import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/services/astrology_matcher.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/screens/astrology/astrology_match_screen.dart';

/// Broker tool: pick any two managed profiles and instantly run a Guna Milan
/// (Ashtakoota) compatibility analysis. Astrology details are read straight
/// from each profile — no manual entry.
class BrokerAstrologyMatchScreen extends ConsumerStatefulWidget {
  const BrokerAstrologyMatchScreen({super.key});

  @override
  ConsumerState<BrokerAstrologyMatchScreen> createState() =>
      _BrokerAstrologyMatchScreenState();
}

class _BrokerAstrologyMatchScreenState
    extends ConsumerState<BrokerAstrologyMatchScreen> {
  List<CandidateProfile> _profiles = [];
  CandidateProfile? _a;
  CandidateProfile? _b;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final profiles = await ref
        .read(profileRepositoryProvider)
        .getCandidatesByBroker(auth.user.uid);
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  AstrologyDetails _detailsOf(CandidateProfile p) => AstrologyDetails(
        rashi: p.rashi,
        nakshatra: p.nakshatra,
        manglikStatus: p.manglikStatus,
        gotra: p.gotra,
      );

  Future<void> _pick(bool isA) async {
    final exclude = isA ? _b : _a;
    final selectable =
        _profiles.where((p) => p.id != exclude?.id).toList();
    final picked = await showModalBottomSheet<CandidateProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ProfilePickSheet(profiles: selectable),
    );
    if (picked == null) return;
    setState(() {
      if (isA) {
        _a = picked;
      } else {
        _b = picked;
      }
    });
  }

  void _analyze() {
    final a = _a, b = _b;
    if (a == null || b == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AstrologyMatchScreen(
          subject: _detailsOf(a),
          candidate: _detailsOf(b),
          subjectLabel: a.name,
          candidateLabel: b.name,
          onEditDetails: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;
    final canAnalyze = _a != null && _b != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Kundali Match')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.allMd,
              children: [
                Container(
                  padding: AppSpacing.allMd,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.06),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                        color: const Color(0xFF7B2FBE).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 18, color: Color(0xFF7B2FBE)),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Pick two profiles to compare horoscopes — '
                          'we read rashi, nakshatra, manglik & gotra automatically.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF7B2FBE)),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Slot(
                        label: 'Profile A',
                        profile: _a,
                        accent: colors.primary,
                        onTap: () => _pick(true),
                        theme: theme,
                        colors: colors,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: palette.meetingPurple.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.favorite_rounded,
                              size: 18, color: palette.meetingPurple),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Slot(
                        label: 'Profile B',
                        profile: _b,
                        accent: palette.meetingPurple,
                        onTap: () => _pick(false),
                        theme: theme,
                        colors: colors,
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapH32,
                FilledButton.icon(
                  onPressed: canAnalyze ? _analyze : null,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Analyze Match'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF7B2FBE),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMd),
                  ),
                ),
                if (!canAnalyze) ...[
                  AppSpacing.gapH8,
                  Text(
                    'Select both profiles to run the analysis.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    required this.profile,
    required this.accent,
    required this.onTap,
    required this.theme,
    required this.colors,
  });

  final String label;
  final CandidateProfile? profile;
  final Color accent;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: colors.onSurfaceVariant)),
        AppSpacing.gapH8,
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppSpacing.roundedLg,
            onTap: onTap,
            child: Container(
              height: 180,
              padding: AppSpacing.allSm,
              decoration: BoxDecoration(
                color: p == null ? colors.surface : accent.withValues(alpha: 0.06),
                borderRadius: AppSpacing.roundedLg,
                border: Border.all(
                  color: p == null
                      ? colors.outlineVariant
                      : accent.withValues(alpha: 0.4),
                  width: p == null ? 1 : 1.5,
                ),
              ),
              child: p == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 32, color: colors.outline),
                        AppSpacing.gapH8,
                        Text('Tap to select',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colors.surfaceContainerHighest,
                          backgroundImage: p.photos.isNotEmpty &&
                                  p.photos.first.startsWith('http')
                              ? NetworkImage(p.photos.first)
                              : null,
                          child: p.photos.isEmpty
                              ? Text(p.name.isNotEmpty ? p.name[0] : '?',
                                  style: theme.textTheme.titleLarge)
                              : null,
                        ),
                        AppSpacing.gapH8,
                        Text('${p.name}, ${p.age}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(p.rashi?.isNotEmpty == true
                            ? p.rashi!
                            : 'No rashi set',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePickSheet extends StatelessWidget {
  const _ProfilePickSheet({required this.profiles});
  final List<CandidateProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a profile',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            AppSpacing.gapH12,
            if (profiles.isEmpty)
              Padding(
                padding: AppSpacing.allMd,
                child: Text('No profiles available.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: profiles.length,
                  itemBuilder: (ctx, i) {
                    final p = profiles[i];
                    final hasAstro = (p.rashi?.isNotEmpty ?? false) ||
                        (p.nakshatra?.isNotEmpty ?? false);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.surfaceContainerHighest,
                        backgroundImage: p.photos.isNotEmpty &&
                                p.photos.first.startsWith('http')
                            ? NetworkImage(p.photos.first)
                            : null,
                        child: p.photos.isEmpty
                            ? Text(p.name.isNotEmpty ? p.name[0] : '?')
                            : null,
                      ),
                      title: Text('${p.name}, ${p.age}'),
                      subtitle: Text(
                        hasAstro
                            ? [p.rashi, p.nakshatra]
                                .where((s) => s?.isNotEmpty ?? false)
                                .join(' · ')
                            : 'No horoscope details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hasAstro
                            ? null
                            : TextStyle(color: colors.error),
                      ),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
