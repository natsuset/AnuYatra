import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/app_user.dart';

/// Bottom sheet that lets a parent forward a shared profile to their linked child.
class ForwardToChildSheet extends ConsumerStatefulWidget {
  /// The shared-profile ID to forward.
  final String sharedProfileId;

  const ForwardToChildSheet({super.key, required this.sharedProfileId});

  @override
  ConsumerState<ForwardToChildSheet> createState() =>
      _ForwardToChildSheetState();
}

class _ForwardToChildSheetState extends ConsumerState<ForwardToChildSheet> {
  AppUser? _childUser;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final parentUserId = authState.user.uid;
    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final childId = await linkRepo.getLinkedChildId(parentUserId);
    final childUser =
        childId != null ? await userRepo.getUser(childId) : null;

    if (!mounted) return;
    setState(() {
      _childUser = childUser;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final childUser = _childUser;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.0,
        24.0,
        24.0,
        24.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText)
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sacredSaffron.withValues(alpha: isDark ? 0.12 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forward_to_inbox,
              size: 36,
              color: AppColors.sacredSaffron.withValues(alpha: isDark ? 0.8 : 0.7),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Forward to Child',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 8),

          if (childUser != null) ...[
            // Child is linked
            Text(
              'Share this profile with your child for their opinion',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Child info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    child: Text(
                      childUser.displayName.isNotEmpty
                          ? childUser.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childUser.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Linked child',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Forward button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(sharedProfileRepositoryProvider)
                      .forwardProfileToChild(widget.sharedProfileId);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.profileForwardedTo(childUser.displayName),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(context.l10n.forwardProfileButton),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sacredSaffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // No child linked
            Text(
              'No child account is linked to your profile yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your child to create an account and link it to yours.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Empty state icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_off, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No child linked',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }
}
