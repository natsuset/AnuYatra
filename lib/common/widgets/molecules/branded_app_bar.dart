import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/common/widgets/atoms/theme_toggle_button.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/screens/debug/theme_tinkerer_screen.dart';
import 'package:testing_flutter/screens/design_system_demo_screen.dart';

/// Reusable branded AppBar with Anuyātrā branding, theme toggle,
/// search, and menu. Used across all role home/dashboard screens.
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Optional callback for search icon. If null, defaults to no-op.
  final VoidCallback? onSearch;

  const BrandedAppBar({super.key, this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      title: Row(
        children: [
          // Long-press on the logo opens the debug-only ThemeTinkererScreen
          // in debug builds. Release builds: tap-only, no-op.
          GestureDetector(
            onLongPress: kDebugMode
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ThemeTinkererScreen(),
                      ),
                    )
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.favorite, color: colors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Anuy\u0101tr\u0101',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ],
      ),
      actions: [
        if (onSearch != null)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
          ),
        const ThemeToggleButton(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'design_demo',
              child: Text('Design System Demo'),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Text('Settings'),
            ),
            PopupMenuItem(
              value: 'help',
              child: Text('Help'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'design_demo':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DesignSystemDemoScreen(),
                  ),
                );
              case 'settings':
                context.pushNamed(RouteNames.appSettings);
              case 'help':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Support coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
        ),
      ],
    );
  }
}
