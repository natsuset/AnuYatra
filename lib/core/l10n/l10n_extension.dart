import 'package:flutter/widgets.dart';
import 'package:testing_flutter/l10n/app_localizations.dart';

/// Shorthand for AppLocalizations.of(context).
///
/// MUST only be called within the localized MaterialApp widget tree.
/// Calling outside (e.g. in the error-fallback MaterialApp in main.dart)
/// will throw because no AppLocalizations ancestor exists.
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
