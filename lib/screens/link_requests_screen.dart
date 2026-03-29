import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/link_request.dart';

class LinkRequestsScreen extends ConsumerWidget {
  const LinkRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseLogIn)),
      );
    }

    final user = authState.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.linkRequests),
          bottom: TabBar(
            indicatorColor: AppColors.sacredSaffron,
            labelColor: AppColors.sacredSaffron,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: [
              Tab(text: context.l10n.received),
              Tab(text: context.l10n.sent),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReceivedTab(userId: user.uid),
            _SentTab(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Received tab
// ---------------------------------------------------------------------------
class _ReceivedTab extends ConsumerStatefulWidget {
  final String userId;
  const _ReceivedTab({required this.userId});

  @override
  ConsumerState<_ReceivedTab> createState() => _ReceivedTabState();
}

class _ReceivedTabState extends ConsumerState<_ReceivedTab> {
  late List<LinkRequest> _requests;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final linkRepo = ref.read(linkRepositoryProvider);
    final requests = await linkRepo.getLinkRequestsReceivedBy(widget.userId);
    if (!mounted) return;
    setState(() {
      _requests = requests;
    });
  }

  Future<void> _acceptRequest(String requestId) async {
    final linkRepo = ref.read(linkRepositoryProvider);
    await linkRepo.acceptLinkRequest(requestId);
    await _loadRequests();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.requestAccepted),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _declineRequest(String requestId) async {
    final linkRepo = ref.read(linkRepositoryProvider);
    await linkRepo.declineLinkRequest(requestId);
    await _loadRequests();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.requestDeclined),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.inbox_outlined,
        title: context.l10n.noReceivedRequests,
        subtitle: 'Link requests from others will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRequests(),
      child: ListView.separated(
        padding: AppSpacing.allMd,
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            isReceived: true,
            onAccept:
                request.isPending ? () => _acceptRequest(request.id) : null,
            onDecline:
                request.isPending ? () => _declineRequest(request.id) : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sent tab
// ---------------------------------------------------------------------------
class _SentTab extends ConsumerStatefulWidget {
  final String userId;
  const _SentTab({required this.userId});

  @override
  ConsumerState<_SentTab> createState() => _SentTabState();
}

class _SentTabState extends ConsumerState<_SentTab> {
  List<LinkRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final linkRepo = ref.read(linkRepositoryProvider);
    final requests = await linkRepo.getLinkRequestsSentBy(widget.userId);
    if (!mounted) return;
    setState(() {
      _requests = requests;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.send_outlined,
        title: context.l10n.noSentRequests,
        subtitle: 'Requests you send will appear here',
      );
    }

    return ListView.separated(
      padding: AppSpacing.allMd,
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _RequestCard(
          request: request,
          isReceived: false,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Request card
// ---------------------------------------------------------------------------
class _RequestCard extends StatelessWidget {
  final LinkRequest request;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _RequestCard({
    required this.request,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + type badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColors.sacredSaffron.withValues(alpha: 0.15),
                  child: Icon(
                    _iconForType(request.type),
                    color: AppColors.sacredSaffron,
                    size: 20,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived
                            ? 'From: ${request.fromUserName}'
                            : 'To: ${request.toUserName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, y \u2022 h:mm a')
                            .format(request.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTertiaryText
                              : AppColors.lightTertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _TypeBadge(type: request.type),
              ],
            ),

            AppSpacing.gapH12,

            // Status + optional note
            Row(
              children: [
                _StatusBadge(status: request.status),
                if (request.note != null && request.note!.isNotEmpty) ...[
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      request.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // Accept / Decline buttons
            if (isReceived && request.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(context.l10n.decline),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(context.l10n.accept),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
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
    );
  }

  IconData _iconForType(LinkRequestType type) {
    switch (type) {
      case LinkRequestType.parentToBroker:
        return Icons.handshake_outlined;
      case LinkRequestType.parentToAgency:
        return Icons.business_outlined;
      case LinkRequestType.agencyToBroker:
        return Icons.group_add_outlined;
      case LinkRequestType.childToParent:
        return Icons.family_restroom;
    }
  }
}

// ---------------------------------------------------------------------------
// Type badge
// ---------------------------------------------------------------------------
class _TypeBadge extends StatelessWidget {
  final LinkRequestType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.displayName,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.info,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final LinkRequestStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case LinkRequestStatus.pending:
        return AppColors.warning;
      case LinkRequestStatus.accepted:
        return AppColors.success;
      case LinkRequestStatus.declined:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state helper
// ---------------------------------------------------------------------------
Widget _buildEmptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: isDark
              ? AppColors.darkTertiaryText
              : AppColors.lightTertiaryText,
        ),
        AppSpacing.gapH16,
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
        ),
      ],
    ),
  );
}
