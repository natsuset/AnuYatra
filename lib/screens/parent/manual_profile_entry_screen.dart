import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:testing_flutter/common/widgets/molecules/photo_manager_widget.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

class ManualProfileEntryScreen extends ConsumerStatefulWidget {
  const ManualProfileEntryScreen({super.key});

  @override
  ConsumerState<ManualProfileEntryScreen> createState() =>
      _ManualProfileEntryScreenState();
}

class _ManualProfileEntryScreenState
    extends ConsumerState<ManualProfileEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Required fields ────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  Gender _gender = Gender.groom;

  // ── Basic info ─────────────────────────────────────────────────────────────
  final _professionCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _casteCtrl = TextEditingController();
  final _communityCtrl = TextEditingController();
  final _motherTongueCtrl = TextEditingController();
  final _aboutMeCtrl = TextEditingController();

  // ── Family info ────────────────────────────────────────────────────────────
  final _familyBackgroundCtrl = TextEditingController();
  final _fatherOccCtrl = TextEditingController();
  final _motherOccCtrl = TextEditingController();
  FamilyType? _familyType;
  FamilyValues? _familyValues;

  // ── Lifestyle ──────────────────────────────────────────────────────────────
  Diet? _diet;
  bool? _smokes;
  bool? _drinks;

  // ── Astrology ──────────────────────────────────────────────────────────────
  final _rashiCtrl = TextEditingController();
  final _nakshatraCtrl = TextEditingController();
  final _manglikCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _birthTimeCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();

  // ── Photos ─────────────────────────────────────────────────────────────────
  List<String> _photos = [];

  bool _saving = false;

  bool get _isDirty =>
      _nameCtrl.text.isNotEmpty ||
      _ageCtrl.text.isNotEmpty ||
      _professionCtrl.text.isNotEmpty ||
      _cityCtrl.text.isNotEmpty ||
      _photos.isNotEmpty;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!_isDirty) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard profile?'),
        content: const Text('The information you entered will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _professionCtrl.dispose();
    _educationCtrl.dispose();
    _cityCtrl.dispose();
    _heightCtrl.dispose();
    _religionCtrl.dispose();
    _casteCtrl.dispose();
    _communityCtrl.dispose();
    _motherTongueCtrl.dispose();
    _aboutMeCtrl.dispose();
    _familyBackgroundCtrl.dispose();
    _fatherOccCtrl.dispose();
    _motherOccCtrl.dispose();
    _rashiCtrl.dispose();
    _nakshatraCtrl.dispose();
    _manglikCtrl.dispose();
    _gotraCtrl.dispose();
    _birthTimeCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final profile = CandidateProfile(
      id: const Uuid().v4(),
      createdByUserId: auth.user.uid,
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
      gender: _gender,
      profession: _professionCtrl.text.trim(),
      education: _educationCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      height: _heightCtrl.text.trim(),
      religion: _religionCtrl.text.trim(),
      caste: _casteCtrl.text.trim(),
      community: _communityCtrl.text.trim(),
      motherTongue: _motherTongueCtrl.text.trim(),
      aboutMe: _aboutMeCtrl.text.trim(),
      familyBackground: _familyBackgroundCtrl.text.trim(),
      fatherOccupation: _fatherOccCtrl.text.trim(),
      motherOccupation: _motherOccCtrl.text.trim(),
      familyType: _familyType,
      familyValues: _familyValues,
      diet: _diet,
      smokes: _smokes,
      drinks: _drinks,
      rashi: _rashiCtrl.text.trim().isEmpty ? null : _rashiCtrl.text.trim(),
      nakshatra: _nakshatraCtrl.text.trim().isEmpty
          ? null
          : _nakshatraCtrl.text.trim(),
      manglikStatus: _manglikCtrl.text.trim().isEmpty
          ? null
          : _manglikCtrl.text.trim(),
      gotra: _gotraCtrl.text.trim().isEmpty ? null : _gotraCtrl.text.trim(),
      birthTime: _birthTimeCtrl.text.trim().isEmpty
          ? null
          : _birthTimeCtrl.text.trim(),
      birthPlace: _birthPlaceCtrl.text.trim().isEmpty
          ? null
          : _birthPlaceCtrl.text.trim(),
      photos: _photos,
      source: ProfileSource.manual,
      createdAt: now,
      updatedAt: now,
    );

    final repo = ref.read(profileRepositoryProvider);
    await repo.saveCandidateProfile(profile);

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context);
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Profile'),
        leading: IconButton(
          tooltip: 'Discard',
          icon: const Icon(Icons.close),
          onPressed: () async {
            final ok = await _confirmDiscard(context);
            if (ok && context.mounted) context.pop();
          },
        ),
        actions: [
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.allMd,
          children: [
            // ── Photos ──────────────────────────────────────────────────────
            _SectionHeader('Photos', icons: Icons.photo_library_outlined),
            AppSpacing.gapH8,
            PhotoManagerWidget(
              initialPhotos: _photos,
              onPhotosChanged: (p) => setState(() => _photos = p),
            ),

            AppSpacing.gapH24,

            // ── Basic info ───────────────────────────────────────────────────
            _SectionHeader('Basic Info', icons: Icons.person_outline_rounded),
            AppSpacing.gapH12,

            _Field(
              controller: _nameCtrl,
              label: 'Full name',
              required: true,
              capitalization: TextCapitalization.words,
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _ageCtrl,
                    label: 'Age',
                    required: true,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 18 || n > 80) {
                        return 'Enter 18–80';
                      }
                      return null;
                    },
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _DropdownField<Gender>(
                    label: 'Looking for',
                    value: _gender,
                    items: Gender.values,
                    labelOf: (g) => g.displayName,
                    onChanged: (g) => setState(() => _gender = g!),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            _Field(
              controller: _professionCtrl,
              label: 'Profession',
              required: true,
              capitalization: TextCapitalization.sentences,
            ),
            AppSpacing.gapH12,

            _Field(
              controller: _educationCtrl,
              label: 'Education',
              required: true,
              capitalization: TextCapitalization.sentences,
            ),
            AppSpacing.gapH12,

            _Field(
              controller: _cityCtrl,
              label: 'City',
              required: true,
              capitalization: TextCapitalization.words,
            ),
            AppSpacing.gapH12,

            _Field(
              controller: _heightCtrl,
              label: 'Height (e.g. 5\'7")',
              capitalization: TextCapitalization.none,
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _religionCtrl,
                    label: 'Religion',
                    capitalization: TextCapitalization.words,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _casteCtrl,
                    label: 'Caste',
                    capitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _communityCtrl,
                    label: 'Community',
                    capitalization: TextCapitalization.words,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _motherTongueCtrl,
                    label: 'Mother tongue',
                    capitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            _Field(
              controller: _aboutMeCtrl,
              label: 'About',
              minLines: 3,
              capitalization: TextCapitalization.sentences,
            ),

            AppSpacing.gapH24,

            // ── Family ───────────────────────────────────────────────────────
            _SectionHeader('Family', icons: Icons.family_restroom_rounded),
            AppSpacing.gapH12,

            _Field(
              controller: _familyBackgroundCtrl,
              label: 'Family background',
              minLines: 2,
              capitalization: TextCapitalization.sentences,
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _fatherOccCtrl,
                    label: "Father's occupation",
                    capitalization: TextCapitalization.sentences,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _motherOccCtrl,
                    label: "Mother's occupation",
                    capitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _DropdownField<FamilyType>(
                    label: 'Family type',
                    value: _familyType,
                    items: FamilyType.values,
                    labelOf: (f) => f.name[0].toUpperCase() + f.name.substring(1),
                    onChanged: (f) => setState(() => _familyType = f),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _DropdownField<FamilyValues>(
                    label: 'Family values',
                    value: _familyValues,
                    items: FamilyValues.values,
                    labelOf: (f) => f.name[0].toUpperCase() + f.name.substring(1),
                    onChanged: (f) => setState(() => _familyValues = f),
                  ),
                ),
              ],
            ),

            AppSpacing.gapH24,

            // ── Lifestyle ────────────────────────────────────────────────────
            _SectionHeader('Lifestyle', icons: Icons.spa_outlined),
            AppSpacing.gapH12,

            _DropdownField<Diet>(
              label: 'Diet',
              value: _diet,
              items: Diet.values,
              labelOf: (d) => d.name[0].toUpperCase() + d.name.substring(1),
              onChanged: (d) => setState(() => _diet = d),
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _NullableBoolField(
                    label: 'Smokes',
                    value: _smokes,
                    onChanged: (v) => setState(() => _smokes = v),
                    colors: colors,
                    theme: theme,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _NullableBoolField(
                    label: 'Drinks',
                    value: _drinks,
                    onChanged: (v) => setState(() => _drinks = v),
                    colors: colors,
                    theme: theme,
                  ),
                ),
              ],
            ),

            AppSpacing.gapH24,

            // ── Astrology ────────────────────────────────────────────────────
            _SectionHeader('Astrology', icons: Icons.auto_awesome_outlined),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _rashiCtrl,
                    label: 'Rashi',
                    capitalization: TextCapitalization.words,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _nakshatraCtrl,
                    label: 'Nakshatra',
                    capitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _manglikCtrl,
                    label: 'Manglik status',
                    capitalization: TextCapitalization.sentences,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _gotraCtrl,
                    label: 'Gotra',
                    capitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _birthTimeCtrl,
                    label: 'Birth time',
                    capitalization: TextCapitalization.none,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _Field(
                    controller: _birthPlaceCtrl,
                    label: 'Birth place',
                    capitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),

            AppSpacing.gapH48,
          ],
        ),
      ),
    ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.icons});
  final String title;
  final IconData icons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Icon(icons, size: 16, color: colors.primary),
        AppSpacing.gapW8,
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
        AppSpacing.gapW8,
        Expanded(child: Divider(color: colors.outlineVariant)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.minLines = 1,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final int minLines;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : null,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
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
        isDense: true,
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value, // ignore: deprecated_member_use
      decoration: InputDecoration(
        labelText: label,
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
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem<T>(value: null, child: const Text('—')),
        ...items.map(
          (t) => DropdownMenuItem<T>(value: t, child: Text(labelOf(t))),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _NullableBoolField extends StatelessWidget {
  const _NullableBoolField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.theme,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapH4,
        Row(
          children: [
            _BoolChip(
              label: 'Yes',
              selected: value == true,
              colors: colors,
              theme: theme,
              onTap: () => onChanged(value == true ? null : true),
            ),
            AppSpacing.gapW8,
            _BoolChip(
              label: 'No',
              selected: value == false,
              colors: colors,
              theme: theme,
              onTap: () => onChanged(value == false ? null : false),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoolChip extends StatelessWidget {
  const _BoolChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? colors.primary : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
