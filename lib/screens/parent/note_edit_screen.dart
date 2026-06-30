import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/parent_note.dart';

/// Full-screen note editor — used for both creating and editing a [ParentNote].
///
/// Pass [existingNote] to edit; omit it (with [profileId]) to create new.
/// The screen pushes itself via [Navigator.push] (not GoRouter) since it is
/// always presented on top of a profile detail page.
class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({
    super.key,
    required this.candidateProfileId,
    this.existingNote,
  });

  final String candidateProfileId;
  final ParentNote? existingNote;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late ParentNoteType _type;
  DateTime? _reminderAt;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _bodyController = TextEditingController(text: note?.body ?? '');
    _type = note?.type ?? ParentNoteType.general;
    _reminderAt = note?.reminderAt;

    _titleController.addListener(_markDirty);
    _bodyController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note body cannot be empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    setState(() => _saving = true);

    final repo = ref.read(parentNoteRepositoryProvider);
    final now = DateTime.now();
    final note = widget.existingNote != null
        ? widget.existingNote!.copyWith(
            title: _titleController.text.trim(),
            body: body,
            type: _type,
            reminderAt: _reminderAt,
            clearReminder: _reminderAt == null,
            updatedAt: now,
          )
        : ParentNote.create(
            parentUserId: auth.user.uid,
            candidateProfileId: widget.candidateProfileId,
            title: _titleController.text.trim(),
            body: body,
            type: _type,
            reminderAt: _reminderAt,
          );

    await repo.saveNote(note);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(note);
  }

  Future<void> _delete() async {
    final note = widget.existingNote;
    if (note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(parentNoteRepositoryProvider);
    await repo.deleteNote(note.id);

    if (!mounted) return;
    Navigator.of(context).pop('deleted');
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;
    final isEditing = widget.existingNote != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Delete note',
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type selector ───────────────────────────────────────────────
            _SectionLabel('Type'),
            AppSpacing.gapH8,
            Row(
              children: ParentNoteType.values.map((t) {
                final selected = _type == t;
                final color = _typeColor(t, palette, colors);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _TypeChip(
                      type: t,
                      selected: selected,
                      color: color,
                      onTap: () => setState(() {
                        _type = t;
                        _dirty = true;
                        if (t != ParentNoteType.reminder) _reminderAt = null;
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),

            AppSpacing.gapH24,

            // ── Title ───────────────────────────────────────────────────────
            _SectionLabel('Title (optional)'),
            AppSpacing.gapH8,
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: _titleHint(_type),
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
            ),

            AppSpacing.gapH16,

            // ── Body ────────────────────────────────────────────────────────
            _SectionLabel('Note'),
            AppSpacing.gapH8,
            TextField(
              controller: _bodyController,
              minLines: 5,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              decoration: InputDecoration(
                hintText: _bodyHint(_type),
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
                contentPadding: AppSpacing.allMd,
              ),
            ),

            AppSpacing.gapH24,

            // ── Reminder (shown for reminder + meeting note types) ──────────
            if (_type == ParentNoteType.reminder ||
                _type == ParentNoteType.meetingNote) ...[
              _SectionLabel(
                _type == ParentNoteType.meetingNote
                    ? 'Meeting date & time'
                    : 'Remind me at',
              ),
              AppSpacing.gapH8,
              _ReminderPicker(
                value: _reminderAt,
                type: _type,
                palette: palette,
                colors: colors,
                theme: theme,
                onPick: _pickReminder,
                onClear: () => setState(() {
                  _reminderAt = null;
                  _dirty = true;
                }),
              ),
              AppSpacing.gapH24,
            ],

            // ── Meeting extras ──────────────────────────────────────────────
            if (_type == ParentNoteType.meetingNote) ...[
              _SectionLabel('Meeting details'),
              AppSpacing.gapH8,
              Container(
                padding: AppSpacing.allMd,
                decoration: BoxDecoration(
                  color: palette.meetingPurple.withValues(alpha: 0.06),
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                    color: palette.meetingPurple.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: palette.meetingPurple),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        'Add venue or call details in the note body above.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.meetingPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,
            ],

            AppSpacing.gapH32,
          ],
        ),
      ),
    );
  }

  Color _typeColor(ParentNoteType t, AppPalette p, ColorScheme c) =>
      switch (t) {
        ParentNoteType.general => c.primary,
        ParentNoteType.meetingNote => p.meetingPurple,
        ParentNoteType.reminder => p.warning,
      };

  String _titleHint(ParentNoteType t) => switch (t) {
        ParentNoteType.general => 'e.g. Family background impression',
        ParentNoteType.meetingNote => 'e.g. First meeting at Coffee House',
        ParentNoteType.reminder => 'e.g. Call back after festival',
      };

  String _bodyHint(ParentNoteType t) => switch (t) {
        ParentNoteType.general =>
          'Add your thoughts, family feedback, points to discuss…',
        ParentNoteType.meetingNote =>
          'What happened? Who attended? Key takeaways…',
        ParentNoteType.reminder => 'What do you need to do or follow up on?',
      };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final ParentNoteType type;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 20, color: selected ? color : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                type.chipLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({
    required this.value,
    required this.type,
    required this.palette,
    required this.colors,
    required this.theme,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final ParentNoteType type;
  final AppPalette palette;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final accent = type == ParentNoteType.meetingNote
        ? palette.meetingPurple
        : palette.warning;

    if (value != null) {
      return Container(
        padding: AppSpacing.allMd,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_on_rounded, color: accent, size: 20),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(value!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(value!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Change',
              icon: Icon(Icons.edit_outlined, size: 18, color: accent),
              onPressed: onPick,
            ),
            IconButton(
              tooltip: 'Remove',
              icon: Icon(Icons.close, size: 18, color: colors.onSurfaceVariant),
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPick,
      icon: Icon(Icons.add_alarm_rounded, size: 18, color: accent),
      label: Text(
        type == ParentNoteType.meetingNote
            ? 'Set meeting date & time'
            : 'Set reminder',
        style: TextStyle(color: accent),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: accent.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
      ),
    );
  }
}

