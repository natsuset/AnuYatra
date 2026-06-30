import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';

/// A compact label-value tile used in profile detail grids.
/// Follows atomic design principles — MOLECULE level.
///
/// The tile adapts to dark/light mode automatically. The background
/// color can be overridden via [backgroundColor] for cases where
/// the tile sits inside a tinted parent (e.g., a green-tinted
/// chat bubble for user-sent messages).
///
/// Example:
/// ```dart
/// DetailTile(label: 'Height', value: '5\'8"')
/// DetailTile(label: 'Religion', value: 'Hindu', backgroundColor: Color(0xFF003D32))
/// ```
class DetailTile extends StatelessWidget {
  /// The label shown above the value (e.g., "Height", "Religion").
  final String label;

  /// The value displayed below the label (e.g., "5'8\"", "Hindu").
  final String value;

  /// Optional override for the tile background color.
  /// When null, defaults to:
  ///   - Dark mode: `Color(0xFF0F1B22)`
  ///   - Light mode: `Color(0xFFF5F5F5)`
  final Color? backgroundColor;

  const DetailTile({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? const Color(0xFF0F1B22) : const Color(0xFFF5F5F5));

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : AppTheme.whatsAppGray.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            value,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
