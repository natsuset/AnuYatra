import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:testing_flutter/common/widgets/molecules/profile_photo_carousel.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/services/astrology_matcher.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/screens/astrology/astrology_match_screen.dart';
import 'package:testing_flutter/screens/parent/note_edit_screen.dart';
import 'package:testing_flutter/models/broker_note.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/meeting.dart';
import 'package:testing_flutter/models/parent_note.dart';
import 'package:testing_flutter/models/profile_activity.dart';
import 'package:testing_flutter/models/shared_profile.dart';

/// Universal candidate profile detail viewer.
///
/// For parents viewing a broker-shared profile, this screen is the
/// "completion-feeling" surface: photo carousel header, switchable
/// response control (Interested · Pass · Reset), key detail sections,
/// astrology preview, conversation & meetings, activity timeline,
/// broker notes, and the parent's own private notes.
///
/// For other viewers (broker viewing their own profile, candidate
/// viewing themself, admin browsing) the parent-only sections are
/// hidden and the screen renders as a read-only profile card.
class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  CandidateProfile? _profile;
  SharedProfile? _shared;
  bool _isSaved = false;
  List<ProfileActivity> _activity = const [];
  BrokerNote? _brokerNote;
  Meeting? _nextMeeting;
  bool _loading = true;

  List<ParentNote> _parentNotes = const [];
  Timer? _noteDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final profileId = GoRouterState.of(context).pathParameters['id'];
    if (profileId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final auth = ref.read(authProvider);
    final viewerId = auth is AuthAuthenticated ? auth.user.uid : null;

    final profileRepo = ref.read(profileRepositoryProvider);
    final sharedRepo = ref.read(sharedProfileRepositoryProvider);
    final savedRepo = ref.read(savedProfileRepositoryProvider);
    final activityRepo = ref.read(activityRepositoryProvider);
    final viewedRepo = ref.read(viewedProfileRepositoryProvider);
    final parentNoteRepo = ref.read(parentNoteRepositoryProvider);
    final brokerNoteRepo = ref.read(brokerNoteRepositoryProvider);
    final meetingRepo = ref.read(meetingRepositoryProvider);

    final profile = await profileRepo.getCandidateProfile(profileId);
    if (profile == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Find the SharedProfile linking this viewer (if parent) to the candidate.
    SharedProfile? shared;
    if (viewerId != null) {
      final shares = await sharedRepo.getSharedProfilesForUser(viewerId);
      shared = shares.firstWhere(
        (s) => s.profileId == profileId,
        orElse: () => SharedProfile(
          id: '',
          profileId: profileId,
          sharedByUserId: '',
          sharedWithUserId: '',
          sharedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      if (shared.id.isEmpty) shared = null;
    }

    // Saved bookmark (parent-only).
    var isSaved = false;
    if (viewerId != null) {
      isSaved = await savedRepo.isSaved(
        userId: viewerId,
        profileId: profileId,
      );
    }

    // Record the view (parent-only flow — viewing your own profile shouldn't
    // pollute the recently-viewed list).
    if (viewerId != null && viewerId != profile.candidateUserId) {
      await viewedRepo.recordView(
        userId: viewerId,
        profileId: profileId,
      );
    }

    // Activity log.
    final activity = await activityRepo.getActivityForProfile(profileId);

    // Parent + broker notes (parent flow only — both keyed on parent + profile).
    List<ParentNote> parentNotes = const [];
    BrokerNote? brokerNote;
    Meeting? nextMeeting;
    if (viewerId != null && shared != null) {
      parentNotes = await parentNoteRepo.getNotesForProfile(
        parentUserId: viewerId,
        candidateProfileId: profileId,
      );
      brokerNote = await brokerNoteRepo.get(
        brokerUserId: shared.sharedByUserId,
        candidateProfileId: profileId,
        forParentUserId: viewerId,
      );
      nextMeeting = await meetingRepo.getNextMeeting(
        parentUserId: viewerId,
        candidateProfileId: profileId,
        viewerUserId: viewerId,
      );
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _shared = shared;
      _isSaved = isSaved;
      _activity = activity;
      _brokerNote = brokerNote;
      _nextMeeting = nextMeeting;
      _parentNotes = parentNotes;
      _loading = false;
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _toggleSave() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final repo = ref.read(savedProfileRepositoryProvider);
    final now = await repo.toggle(
      userId: auth.user.uid,
      profileId: _profile!.id,
    );
    if (!mounted) return;
    setState(() => _isSaved = now);
  }

  /// Response is never final — the segmented control on this screen lets the
  /// parent flip Interested → Pass → Reset at any time. Each tap persists
  /// immediately and re-loads the activity log.
  Future<void> _setResponse(SharedProfileResponse next) async {
    final shared = _shared;
    if (shared == null) return;
    final repo = ref.read(sharedProfileRepositoryProvider);
    await repo.updateSharedProfile(shared.copyWith(parentResponse: next));
    await _loadAll();
  }

  Future<void> _openNoteEditor({ParentNote? existing}) async {
    final profile = _profile;
    if (profile == null) return;
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          candidateProfileId: profile.id,
          existingNote: existing,
        ),
      ),
    );
    if (result != null && mounted) _loadAll();
  }

  // ── Build ───────────────────────────────────────────────────────────────

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

    final isParentViewer = _shared != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: null,
      ),
      body: CustomScrollView(
        slivers: [
          _PhotoHeroSliver(profile: profile),
          SliverPadding(
            padding: AppSpacing.allMd,
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _IdentityHeader(profile: profile),
                AppSpacing.gapH12,
                if (isParentViewer)
                  _QuickActionsRow(
                    isSaved: _isSaved,
                    response: _shared!.parentResponse,
                    onToggleSave: _toggleSave,
                    onSetResponse: _setResponse,
                  ),
                if (isParentViewer) AppSpacing.gapH16,
                _quickInfoChips(context, profile),
                AppSpacing.gapH16,
                _ProfileCompletenessBar(
                  completeness: profile.profileCompleteness,
                  isDark: isDark,
                ),
                AppSpacing.gapH24,

                // ── About ───────────────────────────────────────────────
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

                // ── Professional & Education ───────────────────────────
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

                // ── Community & Background ─────────────────────────────
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
                if (profile.manglikStatus != null &&
                    profile.manglikStatus!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.auto_awesome,
                    label: context.l10n.manglikStatus,
                    value: profile.manglikStatus!,
                    isDark: isDark,
                  ),
                AppSpacing.gapH24,

                // ── Lifestyle ──────────────────────────────────────────
                if (_hasLifestyleInfo(profile)) ...[
                  _SectionTitle('Lifestyle & Personal'),
                  AppSpacing.gapH12,
                  if (profile.diet != null)
                    _DetailRow(
                      icon: Icons.restaurant,
                      label: context.l10n.dietLabel,
                      value: _titleCase(profile.diet!.name),
                      isDark: isDark,
                    ),
                  if (profile.annualIncome != null &&
                      profile.annualIncome!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.currency_rupee,
                      label: context.l10n.annualIncome,
                      value: profile.annualIncome!,
                      isDark: isDark,
                    ),
                  if (profile.complexion != null &&
                      profile.complexion!.isNotEmpty)
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
                      value: profile.smokes!
                          ? context.l10n.yes
                          : context.l10n.no,
                      isDark: isDark,
                    ),
                  if (profile.drinks != null)
                    _DetailRow(
                      icon: Icons.local_bar,
                      label: context.l10n.drinking,
                      value: profile.drinks!
                          ? context.l10n.yes
                          : context.l10n.no,
                      isDark: isDark,
                    ),
                  if (profile.ownHouse != null)
                    _DetailRow(
                      icon: Icons.home,
                      label: context.l10n.ownHouse,
                      value: profile.ownHouse!
                          ? context.l10n.yes
                          : context.l10n.no,
                      isDark: isDark,
                    ),
                  if (profile.ownCar != null)
                    _DetailRow(
                      icon: Icons.directions_car,
                      label: context.l10n.ownCar,
                      value: profile.ownCar!
                          ? context.l10n.yes
                          : context.l10n.no,
                      isDark: isDark,
                    ),
                  if (profile.willingToRelocate != null)
                    _DetailRow(
                      icon: Icons.flight,
                      label: context.l10n.willingToRelocate,
                      value: profile.willingToRelocate!
                          ? context.l10n.yes
                          : context.l10n.no,
                      isDark: isDark,
                    ),
                  AppSpacing.gapH24,
                ],

                // ── Horoscope ──────────────────────────────────────────
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
                  if (profile.birthPlace != null &&
                      profile.birthPlace!.isNotEmpty)
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
                  _AstrologyMatchTeaser(profile: profile),
                  AppSpacing.gapH24,
                ],

                // ── Family ─────────────────────────────────────────────
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
                    value: _titleCase(profile.familyType!.name),
                    isDark: isDark,
                  ),
                if (profile.familyValues != null)
                  _DetailRow(
                    icon: Icons.balance,
                    label: context.l10n.familyValues,
                    value: _titleCase(profile.familyValues!.name),
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

                // ── Interests ──────────────────────────────────────────
                if (profile.interests.isNotEmpty) ...[
                  _SectionTitle('Interests & Hobbies'),
                  AppSpacing.gapH12,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests
                        .map((i) => Chip(
                              label: Text(i),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              labelStyle: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxs),
                            ))
                        .toList(),
                  ),
                  AppSpacing.gapH24,
                ],

                // ── Parent-only sections ───────────────────────────────
                if (isParentViewer) ...[
                  _MeetingsSection(
                    nextMeeting: _nextMeeting,
                    onSchedule: () => _openNoteEditor(),
                  ),
                  AppSpacing.gapH24,
                  _BrokerNoteSection(note: _brokerNote),
                  AppSpacing.gapH24,
                  _ParentNoteSection(
                    notes: _parentNotes,
                    onAddNote: () => _openNoteEditor(),
                    onEditNote: (n) => _openNoteEditor(existing: n),
                  ),
                  AppSpacing.gapH24,
                  _ActivityTimelineSection(events: _activity),
                  AppSpacing.gapH24,
                ],

                // ── Visibility badge (always) ─────────────────────────
                Container(
                  padding: AppSpacing.allSm,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfoChips(BuildContext context, CandidateProfile p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.cake, label: '${p.age} yrs'),
        _InfoChip(icon: Icons.height, label: p.height),
        _InfoChip(icon: Icons.location_on, label: p.city),
        if (p.religion.isNotEmpty)
          _InfoChip(icon: Icons.temple_hindu, label: p.religion),
        if (p.motherTongue.isNotEmpty)
          _InfoChip(icon: Icons.language, label: p.motherTongue),
        _InfoChip(icon: Icons.ring_volume, label: p.maritalStatus),
      ],
    );
  }


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

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ────────────────────────────────────────────────────────────────────────────
// Photo hero sliver — pinned app bar with the photo carousel as background.
// ────────────────────────────────────────────────────────────────────────────
class _PhotoHeroSliver extends StatelessWidget {
  final CandidateProfile profile;
  const _PhotoHeroSliver({required this.profile});

  @override
  Widget build(BuildContext context) {
    // PageView inside FlexibleSpaceBar/SliverAppBar fights the SliverAppBar's
    // stretch gesture handling — horizontal swipes are never claimed by PageView.
    // Fix: plain SliverToBoxAdapter so PageView owns horizontal drags freely.
    // The back button is supplied by the transparent Scaffold.appBar above.
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          ProfilePhotoCarousel(
            photos: profile.photos,
            fallbackInitial: profile.name,
            height: 320,
            borderRadius: BorderRadius.zero,
          ),
          // Top scrim so the back arrow stays legible over bright photos.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Identity header
// ────────────────────────────────────────────────────────────────────────────
class _IdentityHeader extends StatelessWidget {
  final CandidateProfile profile;
  const _IdentityHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.gapH4,
        Text(
          profile.fullDetails,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Quick actions row: Save toggle + segmented response control
//
// The response control is always visible (response is never final per §1.2
// item 6 — parents can flip Interested → Pass → Reset whenever).
// ────────────────────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final bool isSaved;
  final SharedProfileResponse response;
  final VoidCallback onToggleSave;
  final ValueChanged<SharedProfileResponse> onSetResponse;

  const _QuickActionsRow({
    required this.isSaved,
    required this.response,
    required this.onToggleSave,
    required this.onSetResponse,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;

    // Two-row layout avoids the classic "text wraps inside Expanded" problem.
    // Row 1: Save bookmark toggle (natural width, left-aligned).
    // Row 2: Three response chips share the full width equally.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save toggle — natural size so it doesn't crowd the response chips.
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onToggleSave,
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 16,
            ),
            label: Text(isSaved ? 'Saved' : 'Save'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isSaved ? palette.info : colors.onSurfaceVariant,
              side: BorderSide(
                color: isSaved ? palette.info : colors.outline,
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        AppSpacing.gapH8,
        // Response row: full width divided equally among 3 chips.
        Row(
          children: [
            Expanded(
              child: _ResponseChip(
                label: 'Interested',
                icon: Icons.favorite_rounded,
                active: _normaliseResponse(response) == SharedProfileResponse.interested,
                activeColor: colors.error,
                onTap: () => onSetResponse(SharedProfileResponse.interested),
              ),
            ),
            AppSpacing.gapW8,
            Expanded(
              child: _ResponseChip(
                label: 'Pass',
                icon: Icons.close_rounded,
                active: _normaliseResponse(response) == SharedProfileResponse.pass,
                activeColor: colors.onSurfaceVariant,
                onTap: () => onSetResponse(SharedProfileResponse.pass),
              ),
            ),
            AppSpacing.gapW8,
            Expanded(
              child: _ResponseChip(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                active: false,
                activeColor: colors.primary,
                onTap: () => onSetResponse(SharedProfileResponse.pending),
              ),
            ),
          ],
        ),
      ],
    );
  }

  SharedProfileResponse _normaliseResponse(SharedProfileResponse r) {
    // ignore: deprecated_member_use_from_same_package
    if (r == SharedProfileResponse.maybe) return SharedProfileResponse.pending;
    return r;
  }
}

/// Vertical chip: icon on top, single-line label below.
/// Icon + text are stacked so text never competes with the icon for width.
class _ResponseChip extends StatelessWidget {
  const _ResponseChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final fg = active ? activeColor : colors.onSurfaceVariant;

    return Material(
      color: active ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: active ? activeColor : colors.outlineVariant,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(height: 3),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Astrology Match teaser — taps through to AstrologyMatchScreen.
// ────────────────────────────────────────────────────────────────────────────
class _AstrologyMatchTeaser extends ConsumerWidget {
  const _AstrologyMatchTeaser({required this.profile});
  final CandidateProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: palette.meetingPurple.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border:
            Border.all(color: palette.meetingPurple.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: () => _open(context, ref),
          child: Padding(
            padding: AppSpacing.allMd,
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: palette.meetingPurple, size: 20),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Astrology Quick Match',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.meetingPurple,
                            ),
                      ),
                      Text(
                        'Compare rashi, nakshatra and manglik status.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: palette.meetingPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    AstrologyDetails subject = const AstrologyDetails();
    String subjectLabel = 'Your details';

    if (auth is AuthAuthenticated) {
      final viewerId = auth.user.uid;
      final profileRepo = ref.read(profileRepositoryProvider);
      final parentProfile = await profileRepo.getParentProfile(viewerId);
      if (parentProfile != null) {
        subject = AstrologyDetails(
          rashi: parentProfile.childRashi,
          nakshatra: parentProfile.childNakshatra,
          manglikStatus: parentProfile.childManglikStatus,
          gotra: parentProfile.childGotra,
        );
        subjectLabel = (parentProfile.childName?.isNotEmpty ?? false)
            ? parentProfile.childName!
            : 'Your child';
      }
    }

    final candidate = AstrologyDetails(
      rashi: profile.rashi,
      nakshatra: profile.nakshatra,
      manglikStatus: profile.manglikStatus,
      gotra: profile.gotra,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AstrologyMatchScreen(
          subject: subject,
          candidate: candidate,
          subjectLabel: subjectLabel,
          candidateLabel: profile.name,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Meetings section
// ────────────────────────────────────────────────────────────────────────────
class _MeetingsSection extends StatelessWidget {
  final Meeting? nextMeeting;
  final VoidCallback onSchedule;

  const _MeetingsSection({required this.nextMeeting, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final m = nextMeeting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Conversations & Meetings'),
        AppSpacing.gapH12,
        Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_outlined, color: colors.primary, size: 18),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      m == null
                          ? 'No meeting scheduled'
                          : 'Next meeting: ${DateFormat('EEE d MMM, h:mm a').format(m.when)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (m != null) ...[
                AppSpacing.gapH4,
                Row(
                  children: [
                    Icon(
                      _typeIcon(m.type),
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    AppSpacing.gapW4,
                    Text(
                      '${_typeLabel(m.type)} · ${m.location.isEmpty ? "—" : m.location}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              AppSpacing.gapH12,
              OutlinedButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  m == null ? 'Schedule meeting' : 'Schedule another',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(MeetingType t) => switch (t) {
        MeetingType.virtual => Icons.video_call_outlined,
        MeetingType.inPerson => Icons.location_on_outlined,
        MeetingType.phone => Icons.phone_outlined,
      };

  String _typeLabel(MeetingType t) => switch (t) {
        MeetingType.virtual => 'Virtual',
        MeetingType.inPerson => 'In-person',
        MeetingType.phone => 'Phone',
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Broker note — read-only display of the broker's remark for this parent.
// ────────────────────────────────────────────────────────────────────────────
class _BrokerNoteSection extends StatelessWidget {
  final BrokerNote? note;
  const _BrokerNoteSection({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle("Broker's Note"),
        AppSpacing.gapH12,
        Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.05),
            borderRadius: AppSpacing.roundedMd,
            border:
                Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded,
                  color: colors.primary, size: 22),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  note?.body.isNotEmpty == true
                      ? note!.body
                      : 'Your broker hasn\'t added a note for this profile yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: note == null
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                    height: 1.45,
                    fontStyle: note == null ? FontStyle.italic : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Parent note — editable textarea, autosaves on edit (800ms debounce).
// ────────────────────────────────────────────────────────────────────────────
class _ParentNoteSection extends StatelessWidget {
  final List<ParentNote> notes;
  final VoidCallback onAddNote;
  final ValueChanged<ParentNote> onEditNote;

  const _ParentNoteSection({
    required this.notes,
    required this.onAddNote,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: colors.onSurfaceVariant),
            AppSpacing.gapW4,
            Expanded(
              child: Text(
                'My Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'No notes yet. Tap Add to write your thoughts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...notes.map((note) {
            final accent = switch (note.type) {
              ParentNoteType.general => colors.primary,
              ParentNoteType.meetingNote => palette.meetingPurple,
              ParentNoteType.reminder => palette.warning,
            };
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedMd,
                side: BorderSide(color: accent.withValues(alpha: 0.2)),
              ),
              child: InkWell(
                borderRadius: AppSpacing.roundedMd,
                onTap: () => onEditNote(note),
                child: Padding(
                  padding: AppSpacing.allMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(note.type.icon, size: 13, color: accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note.type.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.edit_outlined,
                              size: 14, color: colors.onSurfaceVariant),
                        ],
                      ),
                      if (note.title.isNotEmpty) ...[
                        AppSpacing.gapH4,
                        Text(
                          note.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      AppSpacing.gapH4,
                      Text(
                        note.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Activity timeline — chronological feed of events for this profile.
// ────────────────────────────────────────────────────────────────────────────
class _ActivityTimelineSection extends StatelessWidget {
  final List<ProfileActivity> events;
  const _ActivityTimelineSection({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Activity'),
          AppSpacing.gapH8,
          Text(
            'No activity yet. Events on this profile will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final visible = events.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Activity'),
        AppSpacing.gapH12,
        ...visible.map((e) => _ActivityRow(event: e)),
        if (events.length > visible.length)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+ ${events.length - visible.length} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ProfileActivity event;
  const _ActivityRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    final (icon, color, label) = _describe(event, colors, palette);
    final relative = _relativeTime(event.at);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.actorName != null)
                  Text(
                    'by ${event.actorName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            relative,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _describe(
    ProfileActivity e,
    ColorScheme colors,
    dynamic palette,
  ) {
    switch (e.kind) {
      case ProfileActivityKind.brokerSharedProfile:
        return (Icons.share_outlined, colors.primary, 'Profile shared');
      case ProfileActivityKind.brokerSentMessage:
        return (
          Icons.chat_bubble_outline,
          colors.primary,
          'Broker sent a message',
        );
      case ProfileActivityKind.parentMarkedInterested:
        return (Icons.favorite, palette.success, 'You marked Interested');
      case ProfileActivityKind.parentMarkedPass:
        return (Icons.close, colors.onSurfaceVariant, 'You marked Pass');
      case ProfileActivityKind.parentMarkedPending:
        return (Icons.refresh, colors.onSurfaceVariant, 'You reset response');
      case ProfileActivityKind.parentSavedProfile:
        return (Icons.bookmark_rounded, palette.info, 'You saved the profile');
      case ProfileActivityKind.parentUnsavedProfile:
        return (
          Icons.bookmark_border_rounded,
          colors.onSurfaceVariant,
          'You removed from saved',
        );
      case ProfileActivityKind.parentForwardedToChild:
        return (Icons.forward_to_inbox, palette.info, 'Forwarded to child');
      case ProfileActivityKind.childMarkedInterested:
        return (Icons.favorite, palette.success, 'Child marked Interested');
      case ProfileActivityKind.childMarkedPass:
        return (Icons.close, colors.onSurfaceVariant, 'Child marked Pass');
      case ProfileActivityKind.meetingScheduled:
        return (Icons.event, palette.meetingPurple, 'Meeting scheduled');
      case ProfileActivityKind.meetingCompleted:
        return (Icons.event_available, palette.success, 'Meeting completed');
      case ProfileActivityKind.meetingCancelled:
        return (Icons.event_busy, colors.error, 'Meeting cancelled');
      case ProfileActivityKind.brokerNoteAdded:
        return (Icons.note_alt_outlined, colors.primary, 'Broker added a note');
      case ProfileActivityKind.parentNoteAdded:
        return (Icons.note_alt_outlined, palette.info, 'You added a note');
      case ProfileActivityKind.profileViewed:
        return (Icons.remove_red_eye_outlined, colors.onSurfaceVariant,
            'Profile viewed');
    }
  }

  String _relativeTime(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w';
    return DateFormat('d MMM').format(at);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Preserved helpers
// ────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          AppSpacing.gapW12,
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primary,
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
    final palette = context.palette;
    final color = completeness >= 80
        ? palette.success
        : completeness >= 50
            ? palette.warning
            : palette.error;

    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment_outlined, size: 18, color: color),
              AppSpacing.gapW8,
              Text(
                'Profile completeness',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '$completeness%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completeness / 100.0,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
