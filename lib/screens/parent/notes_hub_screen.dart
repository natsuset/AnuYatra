import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/parent_note.dart';
import 'package:testing_flutter/screens/parent/note_edit_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _allNotesProvider =
    FutureProvider.autoDispose<List<ParentNote>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return [];
  final repo = ref.read(parentNoteRepositoryProvider);
  return repo.getAllNotesForParent(auth.user.uid);
});

final _profileCacheProvider =
    FutureProvider.autoDispose<Map<String, CandidateProfile?>>((ref) async {
  final notes = await ref.watch(_allNotesProvider.future);
  if (notes.isEmpty) return {};
  final profileIds = notes.map((n) => n.candidateProfileId).toSet();
  final profileRepo = ref.read(profileRepositoryProvider);
  final Map<String, CandidateProfile?> cache = {};
  for (final id in profileIds) {
    cache[id] = await profileRepo.getCandidateProfile(id);
  }
  return cache;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NotesHubScreen extends ConsumerStatefulWidget {
  const NotesHubScreen({super.key});

  @override
  ConsumerState<NotesHubScreen> createState() => _NotesHubScreenState();
}

class _NotesHubScreenState extends ConsumerState<NotesHubScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ParentNoteType? _filterType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    final notesAsync = ref.watch(_allNotesProvider);
    final profilesAsync = ref.watch(_profileCacheProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56 + 48),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedLg,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ),
              // Type filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    _FilterChip(
                      label: 'All',
                      icon: Icons.notes_rounded,
                      selected: _filterType == null,
                      color: colors.primary,
                      onTap: () => setState(() => _filterType = null),
                    ),
                    AppSpacing.gapW8,
                    ...ParentNoteType.values.map((t) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: _FilterChip(
                            label: t.chipLabel,
                            icon: t.icon,
                            selected: _filterType == t,
                            color: _typeColor(t, palette, colors),
                            onTap: () => setState(() =>
                                _filterType = _filterType == t ? null : t),
                          ),
                        )),
                  ],
                ),
              ),
              AppSpacing.gapH8,
            ],
          ),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allNotes) {
          final profiles = profilesAsync.valueOrNull ?? {};
          return _NotesBody(
            allNotes: allNotes,
            profiles: profiles,
            query: _query,
            filterType: _filterType,
            palette: palette,
            colors: colors,
            theme: theme,
            onNoteChanged: () => ref.invalidate(_allNotesProvider),
          );
        },
      ),
    );
  }

  Color _typeColor(ParentNoteType t, AppPalette p, ColorScheme c) =>
      switch (t) {
        ParentNoteType.general => c.primary,
        ParentNoteType.meetingNote => p.meetingPurple,
        ParentNoteType.reminder => p.warning,
      };
}

// ── Body (stateless for clean rebuild) ────────────────────────────────────────

class _NotesBody extends StatelessWidget {
  const _NotesBody({
    required this.allNotes,
    required this.profiles,
    required this.query,
    required this.filterType,
    required this.palette,
    required this.colors,
    required this.theme,
    required this.onNoteChanged,
  });

  final List<ParentNote> allNotes;
  final Map<String, CandidateProfile?> profiles;
  final String query;
  final ParentNoteType? filterType;
  final AppPalette palette;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onNoteChanged;

  List<ParentNote> get _filtered {
    var notes = allNotes;
    if (filterType != null) notes = notes.where((n) => n.type == filterType).toList();
    if (query.isNotEmpty) {
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(query) ||
              n.body.toLowerCase().contains(query) ||
              (profiles[n.candidateProfileId]?.name.toLowerCase().contains(query) ??
                  false))
          .toList();
    }
    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes_rounded, size: 56, color: colors.outlineVariant),
            AppSpacing.gapH12,
            Text(
              query.isNotEmpty || filterType != null
                  ? 'No notes match your filter'
                  : 'No notes yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Split upcoming reminders vs rest
    final now = DateTime.now();
    final upcomingReminders = filtered
        .where((n) =>
            n.reminderAt != null && n.reminderAt!.isAfter(now))
        .toList()
      ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));

    final restNotes = filtered
        .where((n) => !(n.reminderAt != null && n.reminderAt!.isAfter(now)))
        .toList();

    // Group rest by profile
    final Map<String, List<ParentNote>> grouped = {};
    for (final note in restNotes) {
      grouped.putIfAbsent(note.candidateProfileId, () => []).add(note);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (upcomingReminders.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.alarm_on_rounded,
            label: 'Upcoming',
            color: palette.warning,
          ),
          ...upcomingReminders.map((n) => _NoteCard(
                note: n,
                profile: profiles[n.candidateProfileId],
                showProfile: true,
                palette: palette,
                colors: colors,
                theme: theme,
                onTap: () => _openNote(context, n),
              )),
        ],
        ...grouped.entries.map((entry) {
          final profile = profiles[entry.key];
          final profileName = profile?.name ?? 'Unknown';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                label: profileName,
                color: colors.onSurfaceVariant,
                trailing: '${entry.value.length} note${entry.value.length == 1 ? '' : 's'}',
              ),
              ...entry.value.map((n) => _NoteCard(
                    note: n,
                    profile: profile,
                    showProfile: false,
                    palette: palette,
                    colors: colors,
                    theme: theme,
                    onTap: () => _openNote(context, n),
                  )),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _openNote(BuildContext context, ParentNote note) async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(
          candidateProfileId: note.candidateProfileId,
          existingNote: note,
        ),
      ),
    );
    if (result != null) onNoteChanged();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.color,
    this.icon,
    this.trailing,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            AppSpacing.gapW8,
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.profile,
    required this.showProfile,
    required this.palette,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final ParentNote note;
  final CandidateProfile? profile;
  final bool showProfile;
  final AppPalette palette;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onTap;

  Color get _accent => switch (note.type) {
        ParentNoteType.general => colors.primary,
        ParentNoteType.meetingNote => palette.meetingPurple,
        ParentNoteType.reminder => palette.warning,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final hasReminder = note.reminderAt != null;
    final isOverdue =
        hasReminder && note.reminderAt!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(note.type.icon, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          note.type.chipLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (hasReminder)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                          size: 13,
                          color: isOverdue ? colors.error : palette.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('d MMM, h:mm a').format(note.reminderAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOverdue ? colors.error : palette.warning,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _relativeDate(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (note.title.isNotEmpty) ...[
                AppSpacing.gapH8,
                Text(
                  note.title,
                  style: theme.textTheme.titleSmall?.copyWith(
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
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showProfile && profile != null) ...[
                AppSpacing.gapH8,
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      profile!.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
