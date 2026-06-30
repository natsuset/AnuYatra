import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/palette_provider.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

/// Debug-only screen for live experimentation with the app's colour palette.
///
/// Mutates [paletteProvider] in real time; changes are persisted to
/// `SharedPreferences` so the chosen palette survives restarts. Gated behind
/// `kDebugMode` at the entry-point (long-press on the app-bar logo).
///
/// Two modes:
/// - **Quick**: a single seed colour → `ColorScheme.fromSeed`.
/// - **Power**: slot-by-slot edits across brand, semantic, feature, neutral.
class ThemeTinkererScreen extends ConsumerStatefulWidget {
  const ThemeTinkererScreen({super.key});

  @override
  ConsumerState<ThemeTinkererScreen> createState() =>
      _ThemeTinkererScreenState();
}

class _ThemeTinkererScreenState extends ConsumerState<ThemeTinkererScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final notifier = ref.read(paletteProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Tinkerer'),
        actions: [
          IconButton(
            tooltip: 'Reset to default',
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.reset(),
          ),
          IconButton(
            tooltip: 'Export as JSON',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _exportJson(palette),
          ),
          IconButton(
            tooltip: 'Import from JSON',
            icon: const Icon(Icons.content_paste_outlined),
            onPressed: () => _importJson(notifier),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Quick'),
            Tab(text: 'Power'),
          ],
        ),
      ),
      body: Column(
        children: [
          _PresetBar(notifier: notifier, palette: palette),
          const Divider(height: 1),
          _PreviewStrip(palette: palette),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _QuickModeTab(palette: palette, notifier: notifier),
                _PowerModeTab(palette: palette, notifier: notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(AppPalette palette) async {
    final raw = palette.toJsonString();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Palette JSON copied to clipboard')),
    );
  }

  Future<void> _importJson(PaletteNotifier notifier) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste palette JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '{"primary": ..., "secondary": ...}',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    final parsed = AppPalette.tryParseJsonString(result);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not parse JSON')),
      );
      return;
    }
    await notifier.setPalette(parsed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Palette applied')),
    );
  }
}

// ─── Presets bar ───────────────────────────────────────────────

class _PresetBar extends StatelessWidget {
  final PaletteNotifier notifier;
  final AppPalette palette;

  const _PresetBar({required this.notifier, required this.palette});

  @override
  Widget build(BuildContext context) {
    final builtIns = AppPalettePresets.all;
    final userSaved = notifier.userPresets;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Presets',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _saveDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Save current'),
              ),
            ],
          ),
          AppSpacing.gapH4,
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in builtIns.entries)
                  _PresetChip(
                    name: entry.key,
                    palette: entry.value,
                    onTap: () => notifier.setPalette(entry.value),
                  ),
                for (final entry in userSaved.entries)
                  _PresetChip(
                    name: entry.key,
                    palette: entry.value,
                    onTap: () => notifier.setPalette(entry.value),
                    onLongPress: () => _deleteDialog(context, entry.key),
                    isUser: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this palette'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Sunset',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await notifier.saveUserPreset(name);
  }

  Future<void> _deleteDialog(BuildContext context, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await notifier.deleteUserPreset(name);
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String name;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isUser;

  const _PresetChip({
    required this.name,
    required this.palette,
    required this.onTap,
    this.onLongPress,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.secondary, width: 2),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(name),
              if (isUser) ...[
                const SizedBox(width: AppSpacing.xxs),
                const Icon(Icons.person_outline, size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live preview strip ────────────────────────────────────────

class _PreviewStrip extends StatelessWidget {
  final AppPalette palette;

  const _PreviewStrip({required this.palette});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Preview', style: theme.textTheme.titleSmall),
                    AppSpacing.gapH4,
                    Text('Sample body text', style: theme.textTheme.bodyMedium),
                    AppSpacing.gapH8,
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Primary'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Filled'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Chip(label: const Text('Chip')),
                      ],
                    ),
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

// ─── Quick mode ────────────────────────────────────────────────

class _QuickModeTab extends StatefulWidget {
  final AppPalette palette;
  final PaletteNotifier notifier;

  const _QuickModeTab({required this.palette, required this.notifier});

  @override
  State<_QuickModeTab> createState() => _QuickModeTabState();
}

class _QuickModeTabState extends State<_QuickModeTab> {
  late Color _seed = widget.palette.primary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pick one seed colour. Material 3 will derive the entire scheme '
            '(primary, secondary, surface, etc.) from it. Semantic + feature '
            'accents keep their defaults.',
          ),
          AppSpacing.gapH16,
          _ColorRow(
            label: 'Seed',
            color: _seed,
            onChanged: (c) => setState(() => _seed = c),
          ),
          AppSpacing.gapH16,
          FilledButton.icon(
            onPressed: () =>
                widget.notifier.setPalette(AppPalette.fromSeed(_seed)),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate from seed'),
          ),
          AppSpacing.gapH8,
          OutlinedButton.icon(
            onPressed: () => widget.notifier.reset(),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to default'),
          ),
        ],
      ),
    );
  }
}

// ─── Power mode ────────────────────────────────────────────────

class _PowerModeTab extends StatelessWidget {
  final AppPalette palette;
  final PaletteNotifier notifier;

  const _PowerModeTab({required this.palette, required this.notifier});

  void _set(AppPalette next) => notifier.setPalette(next);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _SectionLabel('Brand'),
        _ColorRow(
          label: 'Primary',
          color: palette.primary,
          onChanged: (c) => _set(palette.copyWith(primary: c)),
        ),
        _ColorRow(
          label: 'Secondary',
          color: palette.secondary,
          onChanged: (c) => _set(palette.copyWith(secondary: c)),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionLabel('Semantic'),
        _ColorRow(
          label: 'Success',
          color: palette.success,
          onChanged: (c) => _set(palette.copyWith(success: c)),
        ),
        _ColorRow(
          label: 'Error',
          color: palette.error,
          onChanged: (c) => _set(palette.copyWith(error: c)),
        ),
        _ColorRow(
          label: 'Warning',
          color: palette.warning,
          onChanged: (c) => _set(palette.copyWith(warning: c)),
        ),
        _ColorRow(
          label: 'Info',
          color: palette.info,
          onChanged: (c) => _set(palette.copyWith(info: c)),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionLabel('Feature accents'),
        _ColorRow(
          label: 'Trust blue',
          color: palette.trustBlue,
          onChanged: (c) => _set(palette.copyWith(trustBlue: c)),
        ),
        _ColorRow(
          label: 'Meeting purple',
          color: palette.meetingPurple,
          onChanged: (c) => _set(palette.copyWith(meetingPurple: c)),
        ),
        _ColorRow(
          label: 'Financial green',
          color: palette.financialGreen,
          onChanged: (c) => _set(palette.copyWith(financialGreen: c)),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionLabel('Light neutrals'),
        _ColorRow(
          label: 'Background',
          color: palette.lightBackground,
          onChanged: (c) => _set(palette.copyWith(lightBackground: c)),
        ),
        _ColorRow(
          label: 'Surface',
          color: palette.lightSurface,
          onChanged: (c) => _set(palette.copyWith(lightSurface: c)),
        ),
        _ColorRow(
          label: 'Primary text',
          color: palette.lightPrimaryText,
          onChanged: (c) => _set(palette.copyWith(lightPrimaryText: c)),
        ),
        _ColorRow(
          label: 'Secondary text',
          color: palette.lightSecondaryText,
          onChanged: (c) => _set(palette.copyWith(lightSecondaryText: c)),
        ),
        _ColorRow(
          label: 'Divider',
          color: palette.lightDivider,
          onChanged: (c) => _set(palette.copyWith(lightDivider: c)),
        ),
        _ColorRow(
          label: 'Border',
          color: palette.lightBorder,
          onChanged: (c) => _set(palette.copyWith(lightBorder: c)),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SectionLabel('Dark neutrals'),
        _ColorRow(
          label: 'Background',
          color: palette.darkBackground,
          onChanged: (c) => _set(palette.copyWith(darkBackground: c)),
        ),
        _ColorRow(
          label: 'Surface',
          color: palette.darkSurface,
          onChanged: (c) => _set(palette.copyWith(darkSurface: c)),
        ),
        _ColorRow(
          label: 'Primary text',
          color: palette.darkPrimaryText,
          onChanged: (c) => _set(palette.copyWith(darkPrimaryText: c)),
        ),
        _ColorRow(
          label: 'Secondary text',
          color: palette.darkSecondaryText,
          onChanged: (c) => _set(palette.copyWith(darkSecondaryText: c)),
        ),
        _ColorRow(
          label: 'Divider',
          color: palette.darkDivider,
          onChanged: (c) => _set(palette.copyWith(darkDivider: c)),
        ),
        _ColorRow(
          label: 'Border',
          color: palette.darkBorder,
          onChanged: (c) => _set(palette.copyWith(darkBorder: c)),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDialog<Color>(
          context: context,
          builder: (ctx) => _ColorPickerDialog(initial: color),
        );
        if (picked != null) onChanged(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label)),
            Text(
              _hex(color),
              style: TextStyle(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hex(Color c) {
    final argb = c.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

// ─── Hand-rolled HSL picker ────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSLColor _hsl = HSLColor.fromColor(widget.initial);
  late final TextEditingController _hexController =
      TextEditingController(text: _hexOf(widget.initial));

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _update(HSLColor next) {
    setState(() {
      _hsl = next;
      _hexController.text = _hexOf(next.toColor());
    });
  }

  void _applyHex(String text) {
    var t = text.trim().replaceAll('#', '');
    if (t.length == 6) t = 'FF$t';
    if (t.length != 8) return;
    final parsed = int.tryParse(t, radix: 16);
    if (parsed == null) return;
    setState(() {
      _hsl = HSLColor.fromColor(Color(parsed));
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsl.toColor();
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledSlider(
              label: 'Hue',
              value: _hsl.hue,
              max: 360,
              activeColor: HSLColor.fromAHSL(1, _hsl.hue, 1, 0.5).toColor(),
              onChanged: (v) => _update(_hsl.withHue(v)),
              formatValue: (v) => '${v.toInt()}°',
            ),
            _LabeledSlider(
              label: 'Saturation',
              value: _hsl.saturation,
              max: 1,
              onChanged: (v) => _update(_hsl.withSaturation(v)),
              formatValue: (v) => '${(v * 100).toInt()}%',
            ),
            _LabeledSlider(
              label: 'Lightness',
              value: _hsl.lightness,
              max: 1,
              onChanged: (v) => _update(_hsl.withLightness(v)),
              formatValue: (v) => '${(v * 100).toInt()}%',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: 'Hex (#AARRGGBB or RRGGBB)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: _applyHex,
              onEditingComplete: () => _applyHex(_hexController.text),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hsl.toColor()),
          child: const Text('Pick'),
        ),
      ],
    );
  }

  static String _hexOf(Color c) {
    final argb = c.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color? activeColor;
  final ValueChanged<double> onChanged;
  final String Function(double) formatValue;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.formatValue,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 90, child: Text(label)),
              Expanded(
                child: Slider(
                  value: value.clamp(0.0, max),
                  max: max,
                  activeColor: activeColor,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(width: 52, child: Text(formatValue(value))),
            ],
          ),
        ],
      ),
    );
  }
}
