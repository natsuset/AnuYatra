import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/parent_profile.dart';

class BrokerClientsScreen extends ConsumerStatefulWidget {
  const BrokerClientsScreen({super.key});

  @override
  ConsumerState<BrokerClientsScreen> createState() =>
      _BrokerClientsScreenState();
}

class _ClientData {
  final ParentProfile? profile;
  final String name;
  const _ClientData({this.profile, required this.name});
}

class _BrokerClientsScreenState extends ConsumerState<BrokerClientsScreen> {
  List<LinkRequest> _pendingRequests = [];
  List<String> _connectedParentIds = [];
  Map<String, _ClientData> _clientDataMap = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final uid = authState.user.uid;
    _currentUserId = uid;

    final pending = (await linkRepo.getPendingRequestsFor(uid))
        .where((r) => r.type == LinkRequestType.parentToBroker)
        .toList();
    final parentIds = await linkRepo.getConnectedParentIds(uid);

    final clientData = <String, _ClientData>{};
    for (final parentId in parentIds) {
      final parentProfile = await profileRepo.getParentProfile(parentId);
      final parentUser = await userRepo.getUser(parentId);
      clientData[parentId] = _ClientData(
        profile: parentProfile,
        name: parentUser?.displayName ?? parentProfile?.name ?? 'Unknown',
      );
    }

    if (!mounted) return;
    setState(() {
      _pendingRequests = pending;
      _connectedParentIds = parentIds;
      _clientDataMap = clientData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasContent =
        _pendingRequests.isNotEmpty || _connectedParentIds.isNotEmpty;

    return Scaffold(
      body: hasContent
          ? CustomScrollView(
              slivers: [
                if (_pendingRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.warning
                                  .withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: AppSpacing.roundedSm,
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
                          AppSpacing.gapW8,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: AppSpacing.roundedMd,
                            ),
                            child: Text(
                              '${_pendingRequests.length}',
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
                    padding: AppSpacing.horizontalMd,
                    sliver: SliverList.builder(
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final request = _pendingRequests[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingRequestCard(
                            request: request,
                            isDark: isDark,
                            onAccept: () => _handleAccept(request),
                            onDecline: () => _handleDecline(request),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      20,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: AppSpacing.roundedSm,
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
                        AppSpacing.gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.2 : 0.15),
                            borderRadius: AppSpacing.roundedMd,
                          ),
                          child: Text(
                            '${_connectedParentIds.length}',
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
                if (_connectedParentIds.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
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
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                    sliver: SliverList.builder(
                      itemCount: _connectedParentIds.length,
                      itemBuilder: (context, index) {
                        final parentId = _connectedParentIds[index];
                        final data = _clientDataMap[parentId];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ConnectedClientCard(
                            parentProfile: data?.profile,
                            parentName: data?.name ?? 'Unknown',
                            isDark: isDark,
                            onChat: () => _openChat(parentId),
                          ),
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: AppSpacing.gapH24,
                ),
              ],
            )
          : _EmptyState(isDark: isDark),
    );
  }

  Future<void> _openChat(String parentId) async {
    if (_currentUserId == null) return;
    final messagingRepo = ref.read(messagingRepositoryProvider);
    final conversationId =
        await messagingRepo.getOrCreateConversation(_currentUserId!, parentId);
    if (!mounted) return;
    context.pushNamed(
      RouteNames.chat,
      pathParameters: {'conversationId': conversationId},
    );
  }

  Future<void> _handleAccept(LinkRequest request) async {
    try {
      final linkRepo = ref.read(linkRepositoryProvider);
      await linkRepo.acceptLinkRequest(request.id);
      await _loadData();
      if (mounted) {
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

  Future<void> _handleDecline(LinkRequest request) async {
    try {
      final linkRepo = ref.read(linkRepositoryProvider);
      await linkRepo.declineLinkRequest(request.id);
      await _loadData();
      if (mounted) {
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
              padding: AppSpacing.allLg,
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
            AppSpacing.gapH24,
            Text(
              AppStrings.noClientsYet,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            AppSpacing.gapH8,
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
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedLg,
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
              AppSpacing.gapW12,
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  AppStrings.pending,
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
            AppSpacing.gapH12,
            Container(
              width: double.infinity,
              padding: AppSpacing.allSm,
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
                  label: const Text(AppStrings.decline),
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
              AppSpacing.gapW12,
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(AppStrings.accept),
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
                AppSpacing.gapH4,
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
          AppSpacing.gapW8,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onChat,
              borderRadius: AppSpacing.roundedMd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sacredSaffron
                      .withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: AppSpacing.roundedMd,
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
          AppSpacing.gapW4,
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
