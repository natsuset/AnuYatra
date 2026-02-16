import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/parent_profile.dart';

class BrokerClientsScreen extends ConsumerStatefulWidget {
  const BrokerClientsScreen({super.key});

  @override
  ConsumerState<BrokerClientsScreen> createState() =>
      _BrokerClientsScreenState();
}

class _BrokerClientsScreenState extends ConsumerState<BrokerClientsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final storage = ref.watch(localStorageServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final pendingRequests = storage
        .getPendingRequestsFor(user.uid)
        .where((r) => r.type == LinkRequestType.parentToBroker)
        .toList();
    final connectedParentIds = storage.getConnectedParentIds(user.uid);

    final hasContent = pendingRequests.isNotEmpty || connectedParentIds.isNotEmpty;

    return Scaffold(
      body: hasContent
          ? CustomScrollView(
              slivers: [
                // -- Pending Requests Section --
                if (pendingRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.warning
                                  .withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.pending_actions_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Pending Requests',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${pendingRequests.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: pendingRequests.length,
                      itemBuilder: (context, index) {
                        final request = pendingRequests[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingRequestCard(
                            request: request,
                            isDark: isDark,
                            onAccept: () => _handleAccept(request, storage),
                            onDecline: () => _handleDecline(request, storage),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // -- Connected Clients Section --
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Connected Clients',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.2 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${connectedParentIds.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (connectedParentIds.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Center(
                        child: Text(
                          'No connected clients yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTertiaryText
                                : AppColors.lightTertiaryText,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList.builder(
                      itemCount: connectedParentIds.length,
                      itemBuilder: (context, index) {
                        final parentId = connectedParentIds[index];
                        final parentProfile =
                            storage.getParentProfile(parentId);
                        final parentUser = storage.getUser(parentId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ConnectedClientCard(
                            parentProfile: parentProfile,
                            parentName: parentUser?.displayName ??
                                parentProfile?.name ??
                                'Unknown',
                            isDark: isDark,
                            onChat: () {
                              final conversationId =
                                  storage.getOrCreateConversation(
                                      user.uid, parentId);
                              context.pushNamed(
                                RouteNames.chat,
                                pathParameters: {
                                  'conversationId': conversationId
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            )
          : _EmptyState(isDark: isDark),
    );
  }

  Future<void> _handleAccept(
      LinkRequest request, LocalStorageService storage) async {
    try {
      await storage.acceptLinkRequest(request.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted request from ${request.fromUserName}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline(
      LinkRequest request, LocalStorageService storage) async {
    try {
      await storage.declineLinkRequest(request.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined request from ${request.fromUserName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.sacredSaffron
                    .withValues(alpha: isDark ? 0.1 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: AppColors.sacredSaffron
                    .withValues(alpha: isDark ? 0.6 : 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Clients Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When parents connect with you, they\nwill appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Request Card ────────────────────────────────────────

class _PendingRequestCard extends StatelessWidget {
  final LinkRequest request;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingRequestCard({
    required this.request,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.sacredSaffron
                    .withValues(alpha: isDark ? 0.2 : 0.12),
                child: Text(
                  request.fromUserName.isNotEmpty
                      ? request.fromUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sacredSaffron,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fromUserName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.type.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                request.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Connected Client Card ───────────────────────────────────────

class _ConnectedClientCard extends StatelessWidget {
  final ParentProfile? parentProfile;
  final String parentName;
  final bool isDark;
  final VoidCallback onChat;

  const _ConnectedClientCard({
    required this.parentProfile,
    required this.parentName,
    required this.isDark,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookingFor = parentProfile?.lookingForDisplay ?? 'N/A';
    final city = parentProfile?.city ?? '';
    final state = parentProfile?.state ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                AppColors.info.withValues(alpha: isDark ? 0.15 : 0.1),
            child: Text(
              parentName.isNotEmpty ? parentName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.search_rounded,
                      label: 'Looking for $lookingFor',
                      isDark: isDark,
                    ),
                    if (location.isNotEmpty)
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: location,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onChat,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sacredSaffron
                      .withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.sacredSaffron,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ──────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark
                ? AppColors.darkTertiaryText
                : AppColors.lightTertiaryText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
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
