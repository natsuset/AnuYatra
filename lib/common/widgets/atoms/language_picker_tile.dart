import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/locale_provider.dart';

/// Settings tile that lets the user pick an app language.
///
/// Shows the current language name in its native script and opens a dialog
/// with four options: System Default, English, Hindi (हिन्दी), Telugu (తెలుగు).
class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  static const _options = [
    (code: null, native: 'System Default', flag: '🌐'),
    (code: 'en', native: 'English', flag: '🇬🇧'),
    (code: 'hi', native: 'हिन्दी', flag: '🇮🇳'),
    (code: 'te', native: 'తెలుగు', flag: '🇮🇳'),
  ];

  String _currentLabel(Locale? locale) {
    if (locale == null) return 'System Default';
    return switch (locale.languageCode) {
      'en' => 'English',
      'hi' => 'हिन्दी',
      'te' => 'తెలుగు',
      _ => 'System Default',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.sacredSaffron),
      title: Text(l10n.language),
      subtitle: Text(_currentLabel(locale)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showPicker(context, ref, locale),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref, Locale? current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.language),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options.map((opt) {
            final isSelected = opt.code == null
                ? current == null
                : current?.languageCode == opt.code;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.sacredSaffron : null,
              ),
              title: Text('${opt.flag}  ${opt.native}'),
              onTap: () {
                Navigator.pop(ctx);
                if (opt.code == null) {
                  ref.read(localeProvider.notifier).useSystemLocale();
                } else {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(opt.code!));
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}
