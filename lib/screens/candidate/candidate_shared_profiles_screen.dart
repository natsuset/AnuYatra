import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/candidate_profile.dart';
import 'package:testing_flutter/models/shared_profile.dart';

class CandidateSharedProfilesScreen extends ConsumerStatefulWidget {
  const CandidateSharedProfilesScreen({super.key});

  @override
  ConsumerState<CandidateSharedProfilesScreen> createState() =>
      _CandidateSharedProfilesScreenState();
}

class _CandidateSharedProfilesScreenState
    extends ConsumerState<CandidateSharedProfilesScreen> {
  List<_SharedProfileItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final storage = ref.read(localStorageServiceProvider);
    final uid = authState.user.uid;

    // Get profiles that have been forwarded to the candidate
    final sharedProfiles = storage.getSharedProfilesForUser(uid);

    final items = <_SharedProfileItem>[];
    for (final sp in sharedProfiles) {
      final profile = storage.getCandidateProfile(sp.profileId);
      if (profile != null) {
        items.add(_SharedProfileItem(shared: sp, profile: profile));
      }
    }

    setState(() {
      _items = items;
    });
  }

  Future<void> _respond(SharedProfile shared, SharedProfileResponse response) async {
    final storage = ref.read(localStorageServiceProvider);
    final updated = shared.copyWith(childResponse: response);
    await storage.updateSharedProfile(updated);
    _loadProfiles();

    if (mounted) {
      final label = response == SharedProfileResponse.interested
          ? 'Marked as Interested'
          : 'Marked as Pass';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          backgroundColor: response == SharedProfileResponse.interested
              ? AppColors.success
              : AppColors.lightSecondaryText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Profiles'),
      ),
      body: _items.isEmpty
          ? _buildEmptyState(isDark, theme)
          : RefreshIndicator(
              onRefresh: () async => _loadProfiles(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ProfileCard(
                    item: item,
                    isDark: isDark,
                    theme: theme,
                    onInterested: item.shared.childResponse == null
                        ? () => _respond(
                            item.shared, SharedProfileResponse.interested)
                        : null,
                    onPass: item.shared.childResponse == null
                        ? () =>
                            _respond(item.shared, SharedProfileResponse.pass)
                        : null,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 72,
            color: isDark
                ? AppColors.darkTertiaryText
                : AppColors.lightTertiaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No shared profiles yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Profiles shared by your parent will appear here for your review',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data holder
// ---------------------------------------------------------------------------
class _SharedProfileItem {
  final SharedProfile shared;
  final CandidateProfile profile;
  const _SharedProfileItem({required this.shared, required this.profile});
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------
class _ProfileCard extends StatelessWidget {
  final _SharedProfileItem item;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onInterested;
  final VoidCallback? onPass;

  const _ProfileCard({
    required this.item,
    required this.isDark,
    required this.theme,
    this.onInterested,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final profile = item.profile;
    final response = item.shared.childResponse;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            RouteNames.profileView,
            pathParameters: {'id': item.profile.id},
          );
        },
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile info
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      AppColors.deepMaroon.withValues(alpha: 0.12),
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.deepMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.fullDetails,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (response != null) _buildResponseBadge(response),
              ],
            ),

            // Additional info
            if (profile.aboutMe.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                profile.aboutMe,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action buttons (only when not yet responded)
            if (response == null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPass,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Pass'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onInterested,
                      icon: const Icon(Icons.favorite_outline, size: 18),
                      label: const Text('Interested'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildResponseBadge(SharedProfileResponse response) {
    final isInterested = response == SharedProfileResponse.interested;
    final color = isInterested ? AppColors.success : AppColors.lightSecondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        response.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
