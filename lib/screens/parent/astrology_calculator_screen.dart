import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/services/astrology_matcher.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/screens/astrology/astrology_match_screen.dart';

class AstrologyCalculatorScreen extends ConsumerStatefulWidget {
  const AstrologyCalculatorScreen({
    super.key,
    this.candidateProfile,
  });

  /// When opened from a profile page, the candidate side is pre-filled.
  final CandidateProfile? candidateProfile;

  @override
  ConsumerState<AstrologyCalculatorScreen> createState() =>
      _AstrologyCalculatorScreenState();
}

class _AstrologyCalculatorScreenState
    extends ConsumerState<AstrologyCalculatorScreen> {
  // My child fields
  final _myRashiCtrl = TextEditingController();
  final _myNakshatraCtrl = TextEditingController();
  final _myManglikCtrl = TextEditingController();
  final _myGotraCtrl = TextEditingController();

  // Candidate fields
  final _theirRashiCtrl = TextEditingController();
  final _theirNakshatraCtrl = TextEditingController();
  final _theirManglikCtrl = TextEditingController();
  final _theirGotraCtrl = TextEditingController();

  String _myLabel = 'My child';
  String _theirLabel = 'Candidate';

  bool _loadingAutofill = true;

  @override
  void initState() {
    super.initState();
    _prefillCandidate();
    _loadLinkedChildProfile();
  }

  void _prefillCandidate() {
    final p = widget.candidateProfile;
    if (p == null) return;
    _theirLabel = p.name.isNotEmpty ? p.name : 'Candidate';
    _theirRashiCtrl.text = p.rashi ?? '';
    _theirNakshatraCtrl.text = p.nakshatra ?? '';
    _theirManglikCtrl.text = p.manglikStatus ?? '';
    _theirGotraCtrl.text = p.gotra ?? '';
  }

  Future<void> _loadLinkedChildProfile() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      setState(() => _loadingAutofill = false);
      return;
    }

    try {
      final profileRepo = ref.read(profileRepositoryProvider);

      if (auth.user.role == UserRole.candidate) {
        // For candidates: load their OWN profile for the left panel
        final all = await profileRepo.getAllCandidateProfiles();
        final own = all
            .where((p) => p.candidateUserId == auth.user.uid)
            .firstOrNull;
        if (own != null && mounted) {
          _myLabel = own.name.isNotEmpty ? own.name : 'Myself';
          _theirLabel = 'Match';
          _myRashiCtrl.text = own.rashi ?? '';
          _myNakshatraCtrl.text = own.nakshatra ?? '';
          _myManglikCtrl.text = own.manglikStatus ?? '';
          _myGotraCtrl.text = own.gotra ?? '';
        } else if (mounted) {
          _myLabel = auth.user.displayName.isNotEmpty
              ? auth.user.displayName
              : 'Myself';
          _theirLabel = 'Match';
        }
      } else {
        // For parents/brokers: load their linked child's profile
        final linkRepo = ref.read(linkRepositoryProvider);
        final childId = await linkRepo.getLinkedChildId(auth.user.uid);
        if (childId != null) {
          final childProfile = await profileRepo.getCandidateProfile(childId);
          if (childProfile != null && mounted) {
            _myLabel =
                childProfile.name.isNotEmpty ? childProfile.name : 'My child';
            _myRashiCtrl.text = childProfile.rashi ?? '';
            _myNakshatraCtrl.text = childProfile.nakshatra ?? '';
            _myManglikCtrl.text = childProfile.manglikStatus ?? '';
            _myGotraCtrl.text = childProfile.gotra ?? '';
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingAutofill = false);
  }

  void _calculate() {
    final subject = AstrologyDetails(
      rashi: _myRashiCtrl.text.trim().isNotEmpty
          ? _myRashiCtrl.text.trim()
          : null,
      nakshatra: _myNakshatraCtrl.text.trim().isNotEmpty
          ? _myNakshatraCtrl.text.trim()
          : null,
      manglikStatus: _myManglikCtrl.text.trim().isNotEmpty
          ? _myManglikCtrl.text.trim()
          : null,
      gotra: _myGotraCtrl.text.trim().isNotEmpty
          ? _myGotraCtrl.text.trim()
          : null,
    );

    final candidate = AstrologyDetails(
      rashi: _theirRashiCtrl.text.trim().isNotEmpty
          ? _theirRashiCtrl.text.trim()
          : null,
      nakshatra: _theirNakshatraCtrl.text.trim().isNotEmpty
          ? _theirNakshatraCtrl.text.trim()
          : null,
      manglikStatus: _theirManglikCtrl.text.trim().isNotEmpty
          ? _theirManglikCtrl.text.trim()
          : null,
      gotra: _theirGotraCtrl.text.trim().isNotEmpty
          ? _theirGotraCtrl.text.trim()
          : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AstrologyMatchScreen(
          subject: subject,
          candidate: candidate,
          subjectLabel: _myLabel,
          candidateLabel: _theirLabel,
          onEditDetails: () => Navigator.pop(context),
        ),
      ),
    );
  }

  bool get _canCalculate {
    final myFilled = _myRashiCtrl.text.trim().isNotEmpty ||
        _myNakshatraCtrl.text.trim().isNotEmpty ||
        _myManglikCtrl.text.trim().isNotEmpty;
    final theirFilled = _theirRashiCtrl.text.trim().isNotEmpty ||
        _theirNakshatraCtrl.text.trim().isNotEmpty ||
        _theirManglikCtrl.text.trim().isNotEmpty;
    return myFilled && theirFilled;
  }

  @override
  void dispose() {
    _myRashiCtrl.dispose();
    _myNakshatraCtrl.dispose();
    _myManglikCtrl.dispose();
    _myGotraCtrl.dispose();
    _theirRashiCtrl.dispose();
    _theirNakshatraCtrl.dispose();
    _theirManglikCtrl.dispose();
    _theirGotraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Astrology Match'),
      ),
      body: _loadingAutofill
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.allMd,
              children: [
                // ── Info banner ──────────────────────────────────────────────
                Container(
                  padding: AppSpacing.allMd,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 18, color: colors.primary),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Enter at least rashi or nakshatra for both sides to calculate compatibility.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapH24,

                // ── My child panel ───────────────────────────────────────────
                _PanelCard(
                  title: _myLabel,
                  accent: colors.primary,
                  icon: Icons.child_care_rounded,
                  theme: theme,
                  colors: colors,
                  child: _AstrologyFields(
                    rashiCtrl: _myRashiCtrl,
                    nakshatraCtrl: _myNakshatraCtrl,
                    manglikCtrl: _myManglikCtrl,
                    gotraCtrl: _myGotraCtrl,
                    onChanged: () => setState(() {}),
                    colors: colors,
                    theme: theme,
                  ),
                ),

                AppSpacing.gapH16,

                // ── Candidate panel ──────────────────────────────────────────
                _PanelCard(
                  title: _theirLabel,
                  accent: palette.meetingPurple,
                  icon: Icons.person_outline_rounded,
                  theme: theme,
                  colors: colors,
                  child: _AstrologyFields(
                    rashiCtrl: _theirRashiCtrl,
                    nakshatraCtrl: _theirNakshatraCtrl,
                    manglikCtrl: _theirManglikCtrl,
                    gotraCtrl: _theirGotraCtrl,
                    onChanged: () => setState(() {}),
                    colors: colors,
                    theme: theme,
                  ),
                ),

                AppSpacing.gapH32,

                // ── Calculate button ─────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _canCalculate ? _calculate : null,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate Match'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                    ),
                  ),
                ),

                if (!_canCalculate) ...[
                  AppSpacing.gapH8,
                  Text(
                    'Fill at least one field in each panel to proceed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                AppSpacing.gapH32,
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.accent,
    required this.icon,
    required this.theme,
    required this.colors,
    required this.child,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                AppSpacing.gapW8,
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _AstrologyFields extends StatelessWidget {
  const _AstrologyFields({
    required this.rashiCtrl,
    required this.nakshatraCtrl,
    required this.manglikCtrl,
    required this.gotraCtrl,
    required this.onChanged,
    required this.colors,
    required this.theme,
  });

  final TextEditingController rashiCtrl;
  final TextEditingController nakshatraCtrl;
  final TextEditingController manglikCtrl;
  final TextEditingController gotraCtrl;
  final VoidCallback onChanged;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AstroTextField(
                ctrl: rashiCtrl,
                label: 'Rashi',
                onChanged: onChanged,
                colors: colors,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _AstroTextField(
                ctrl: nakshatraCtrl,
                label: 'Nakshatra',
                onChanged: onChanged,
                colors: colors,
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        Row(
          children: [
            Expanded(
              child: _AstroTextField(
                ctrl: manglikCtrl,
                label: 'Manglik status',
                onChanged: onChanged,
                colors: colors,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _AstroTextField(
                ctrl: gotraCtrl,
                label: 'Gotra',
                onChanged: onChanged,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AstroTextField extends StatelessWidget {
  const _AstroTextField({
    required this.ctrl,
    required this.label,
    required this.onChanged,
    required this.colors,
  });

  final TextEditingController ctrl;
  final String label;
  final VoidCallback onChanged;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }
}
