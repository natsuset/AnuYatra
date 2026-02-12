import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/common/widgets/molecules/detail_tile.dart';

/// A responsive two-column grid of [DetailTile] widgets.
/// Follows atomic design principles — MOLECULE level.
///
/// Filters out entries where the value is empty. If [title] is provided,
/// renders a section header above the grid.
///
/// Example:
/// ```dart
/// DetailsGrid(
///   title: 'Personal Details',
///   details: [
///     MapEntry('Height', profile.height),
///     MapEntry('Religion', profile.religion),
///   ],
/// )
/// ```
class DetailsGrid extends StatelessWidget {
  /// Key-value pairs to display. Entries with empty values are filtered out.
  final List<MapEntry<String, String>> details;

  /// Optional section title displayed above the grid.
  final String? title;

  /// Optional title text style override.
  /// When null and [title] is provided, defaults to `titleSmall` with `w700`.
  final TextStyle? titleStyle;

  /// Optional background color passed through to each [DetailTile].
  final Color? tileBackgroundColor;

  /// Horizontal gap between tiles. Defaults to 12.
  final double spacing;

  /// Vertical gap between tile rows. Defaults to 8.
  final double runSpacing;

  const DetailsGrid({
    super.key,
    required this.details,
    this.title,
    this.titleStyle,
    this.tileBackgroundColor,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.xs,
  });

  @override
  Widget build(BuildContext context) {
    final filteredDetails =
        details.where((e) => e.value.trim().isNotEmpty).toList(growable: false);

    if (filteredDetails.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveTitleStyle = titleStyle ??
        Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              fontWeight: FontWeight.w700,
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: effectiveTitleStyle),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: filteredDetails.map((e) {
                return SizedBox(
                  width: itemWidth,
                  child: DetailTile(
                    label: e.key,
                    value: e.value,
                    backgroundColor: tileBackgroundColor,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
