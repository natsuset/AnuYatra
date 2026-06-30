import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ParentNoteType {
  general,
  meetingNote,
  reminder;

  String get displayName => switch (this) {
        ParentNoteType.general => 'General',
        ParentNoteType.meetingNote => 'Meeting Note',
        ParentNoteType.reminder => 'Reminder',
      };

  /// Single-word label for tight chip/badge contexts where wrapping would
  /// cause uneven heights across the three chips.
  String get chipLabel => switch (this) {
        ParentNoteType.general => 'General',
        ParentNoteType.meetingNote => 'Meeting',
        ParentNoteType.reminder => 'Reminder',
      };

  IconData get icon => switch (this) {
        ParentNoteType.general => Icons.notes_rounded,
        ParentNoteType.meetingNote => Icons.event_note_rounded,
        ParentNoteType.reminder => Icons.alarm_rounded,
      };
}

/// A private note a parent writes on a specific candidate profile.
///
/// Multiple notes can exist per (parentUserId, candidateProfileId) pair.
/// Notes are never visible to the broker or candidate (private workspace).
class ParentNote {
  final String id;
  final String parentUserId;
  final String candidateProfileId;
  final String title;
  final String body;
  final ParentNoteType type;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParentNote({
    required this.id,
    required this.parentUserId,
    required this.candidateProfileId,
    required this.title,
    required this.body,
    required this.type,
    this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentNote.create({
    required String parentUserId,
    required String candidateProfileId,
    required String body,
    String title = '',
    ParentNoteType type = ParentNoteType.general,
    DateTime? reminderAt,
  }) {
    final now = DateTime.now();
    return ParentNote(
      id: const Uuid().v4(),
      parentUserId: parentUserId,
      candidateProfileId: candidateProfileId,
      title: title,
      body: body,
      type: type,
      reminderAt: reminderAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  ParentNote copyWith({
    String? title,
    String? body,
    ParentNoteType? type,
    DateTime? reminderAt,
    DateTime? updatedAt,
    bool clearReminder = false,
  }) {
    return ParentNote(
      id: id,
      parentUserId: parentUserId,
      candidateProfileId: candidateProfileId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentUserId': parentUserId,
        'candidateProfileId': candidateProfileId,
        'title': title,
        'body': body,
        'type': type.name,
        'reminderAt': reminderAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ParentNote.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final createdAtRaw = json['createdAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;

    return ParentNote(
      id: id.isEmpty ? const Uuid().v4() : id,
      parentUserId: json['parentUserId'] as String? ?? '',
      candidateProfileId: json['candidateProfileId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: ParentNoteType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => ParentNoteType.general,
      ),
      reminderAt: json['reminderAt'] != null
          ? DateTime.tryParse(json['reminderAt'] as String)
          : null,
      createdAt: createdAtRaw != null
          ? (DateTime.tryParse(createdAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAtRaw != null
          ? (DateTime.tryParse(updatedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Migrate a legacy single-note record (old format: body only, id was
  /// "{parentId}_{profileId}") into the new multi-note format.
  static ParentNote fromLegacy(Map<String, dynamic> json) {
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ParentNote(
      id: const Uuid().v4(),
      parentUserId: json['parentUserId'] as String? ?? '',
      candidateProfileId: json['candidateProfileId'] as String? ?? '',
      title: '',
      body: json['body'] as String? ?? '',
      type: ParentNoteType.general,
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
  }
}
