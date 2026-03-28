import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class MyBrokersScreen extends ConsumerStatefulWidget {
  const MyBrokersScreen({super.key});

  @override
  ConsumerState<MyBrokersScreen> createState() => _MyBrokersScreenState();
}

class _MyBrokersScreenState extends ConsumerState<MyBrokersScreen> {
  List<LinkRequest> _incomingPending = [];
  List<LinkRequest> _sentPending = [];
  List<BrokerProfile> _connectedBrokers = [];
  Map<String, String> _displayNamesByUserId = {};
  Map<String, String> _agencyNamesByBrokerId = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final uid = authState.user.uid;
    final linkRepo = ref.read(linkRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final agencyRepo = ref.read(agencyRepositoryProvider);

    final allPending = await linkRepo.getPendingRequestsFor(uid);
    final incomingPending = allPending
        .where((r) =>
            r.type == LinkRequestType.parentToBroker ||
            r.type == LinkRequestType.parentToAgency)
        .toList();

    final allSent = await linkRepo.getLinkRequestsSentBy(uid);
    final sentPending = allSent
        .where((r) =>
            r.status == LinkRequestStatus.pending &&
            (r.type == LinkRequestType.parentToBroker ||
                r.type == LinkRequestType.parentToAgency))
        .toList();

    final connectedBrokerIds = await linkRepo.getConnectedBrokerIds(uid);
    final connectedBrokers = <BrokerProfile>[];
    final displayNamesByUserId = <String, String>{};
    final agencyNamesByBrokerId = <String, String>{};

    for (final id in connectedBrokerIds) {
      final profile = await brokerRepo.getBrokerProfile(id);
      if (profile != null) {
        connectedBrokers.add(profile);
        if (profile.agencyId != null) {
          final agency = await agencyRepo.getAgency(profile.agencyId!);
          if (agency != null) {
            agencyNamesByBrokerId[profile.userId] = agency.name;
          }
        }
      }
    }

    for (final r in incomingPending) {
      final user = await userRepo.getUser(r.fromUserId);
      if (user != null) {
        displayNamesByUserId[r.fromUserId] = user.displayName;
      }
    }
    for (final r in sentPending) {
      final user = await userRepo.getUser(r.toUserId);
      if (user != null) {
        displayNamesByUserId[r.toUserId] = user.displayName;
      }
    }

    if (!mounted) return;
    setState(() {
      _incomingPending = incomingPending;
      _sentPending = sentPending;
      _connectedBrokers = connectedBrokers;
      _displayNamesByUserId = displayNamesByUserId;
      _agencyNamesByBrokerId = agencyNamesByBrokerId;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = AppTheme.isDark(context);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark, _connectedBrokers.length),

          if (_incomingPending.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildIncomingRequestsSection(
                context, isDark, _incomingPending,
              ),
            ),

          if (_sentPending.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSentRequestsSection(
                context, isDark, _sentPending, currentUser.uid,
              ),
            ),

          if (_connectedBrokers.isEmpty &&
              _sentPending.isEmpty &&
              _incomingPending.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context, isDark),
            )
          else if (_connectedBrokers.isNotEmpty)
            _buildConnectedBrokersList(
              context, isDark, _connectedBrokers, currentUser.uid,
            ),

          const SliverToBoxAdapter(child: AppSpacing.gapH24),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark, int brokerCount) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.appBarBackground(context),
      foregroundColor: Colors.white,
      elevation: 0,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppColors.darkSurface, AppColors.darkSurfaceVariant],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.only(
                left: AppSpacing.md,
                top: AppSpacing.xs,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Brokers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Text(
                          '$brokerCount connected',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── INCOMING PENDING REQUESTS ────────────────────────────

  Widget _buildIncomingRequestsSection(
    BuildContext context,
    bool isDark,
    List<LinkRequest> requests,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.only(
            left: AppSpacing.md,
            top: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Pending Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText(context),
                ),
              ),
              AppSpacing.gapW8,
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...requests.map((request) =>
            _buildIncomingRequestCard(context, isDark, request)),
        Padding(
          padding: AppSpacing.horizontalMd,
          child: Divider(color: AppTheme.divider(context), height: 32),
        ),
      ],
    );
  }

  Widget _buildIncomingRequestCard(
    BuildContext context,
    bool isDark,
    LinkRequest request,
  ) {
    final displayName =
        _displayNamesByUserId[request.fromUserId] ?? request.fromUserName;
    final timeAgo = _formatTimeAgo(request.createdAt);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.warning.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.warning.withValues(alpha: 0.2)
                : AppColors.warning.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? AppColors.warningLight : AppColors.warningDark,
                  ),
                ),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          request.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' \u00b7 $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.tertiaryText(context),
                        ),
                      ),
                    ],
                  ),
                  if (request.note != null && request.note!.isNotEmpty) ...[
                    AppSpacing.gapH4,
                    Text(
                      request.note!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.secondaryText(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapW8,
            Column(
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(linkRepositoryProvider)
                          .acceptLinkRequest(request.id);
                      if (!context.mounted) return;
                      setState(() {});
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connected with $displayName'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(AppStrings.accept),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(linkRepositoryProvider)
                          .declineLinkRequest(request.id);
                      if (!context.mounted) return;
                      setState(() {});
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Declined request from $displayName'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text(AppStrings.decline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SENT PENDING REQUESTS ────────────────────────────────

  Widget _buildSentRequestsSection(
    BuildContext context,
    bool isDark,
    List<LinkRequest> requests,
    String currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.only(
            left: AppSpacing.md,
            top: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Requests Sent',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText(context),
                ),
              ),
              AppSpacing.gapW8,
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...requests.map((request) =>
            _buildSentRequestCard(context, isDark, request, currentUserId)),
        Padding(
          padding: AppSpacing.horizontalMd,
          child: Divider(color: AppTheme.divider(context), height: 32),
        ),
      ],
    );
  }

  Widget _buildSentRequestCard(
    BuildContext context,
    bool isDark,
    LinkRequest request,
    String currentUserId,
  ) {
    final displayName =
        _displayNamesByUserId[request.toUserId] ?? request.toUserName;
    final timeAgo = _formatTimeAgo(request.createdAt);
    final isBrokerRequest = request.type == LinkRequestType.parentToBroker;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.info.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.info.withValues(alpha: 0.15)
                : AppColors.info.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.info.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isBrokerRequest ? Icons.person : Icons.business,
                      size: 22,
                      color: isDark ? AppColors.infoLight : AppColors.info,
                    ),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.roundedXs,
                            ),
                            child: const Text(
                              'Awaiting response',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                          Text(
                            ' \u00b7 $timeAgo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.tertiaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Call $displayName'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryText(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: AppSpacing.verticalXs,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final convId = await ref
                          .read(messagingRepositoryProvider)
                          .getOrCreateConversation(
                            currentUserId,
                            request.toUserId,
                          );
                      if (!context.mounted) return;
                      context.pushNamed(
                        RouteNames.chat,
                        pathParameters: {'conversationId': convId},
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sacredSaffron,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: AppSpacing.verticalXs,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.allXxl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.sacredSaffron.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 44,
                color: isDark
                    ? AppColors.sacredSaffronLight
                    : AppColors.sacredSaffron,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              AppStrings.noBrokersConnected,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText(context),
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'Connect with experienced brokers to help you find the right match for your family.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                context.goNamed(RouteNames.parentSearch);
              },
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text(AppStrings.findBrokers),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sacredSaffron,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONNECTED BROKERS LIST ───────────────────────────────

  Widget _buildConnectedBrokersList(
    BuildContext context,
    bool isDark,
    List<BrokerProfile> brokers,
    String currentUserId,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: AppSpacing.only(
                left: AppSpacing.md,
                top: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Connected Brokers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText(context),
                    ),
                  ),
                ],
              ),
            );
          }

          final broker = brokers[index - 1];
          return _buildConnectedBrokerCard(
              context, isDark, broker, currentUserId);
        },
        childCount: brokers.length + 1,
      ),
    );
  }

  Widget _buildConnectedBrokerCard(
    BuildContext context,
    bool isDark,
    BrokerProfile broker,
    String currentUserId,
  ) {
    final agencyName = _agencyNamesByBrokerId[broker.userId];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      child: Material(
        color: AppTheme.cardSurface(context),
        borderRadius: AppSpacing.roundedLg,
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: AppSpacing.roundedLg,
          onTap: () {
            _showBrokerDetailSheet(context, broker, agencyName);
          },
          child: Container(
            padding: AppSpacing.allMd,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : AppColors.lightDivider,
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.deepMaroon.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              broker.name.isNotEmpty
                                  ? broker.name[0].toUpperCase()
                                  : 'B',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.sacredSaffronLight
                                    : AppColors.deepMaroon,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: broker.isOnline
                                  ? AppColors.success
                                  : AppTheme.tertiaryText(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cardSurface(context),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  broker.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryText(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: broker.isOnline
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : (isDark
                                          ? AppColors.darkSurfaceVariant
                                          : AppColors.lightSurfaceVariant),
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  broker.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: broker.isOnline
                                        ? AppColors.success
                                        : AppTheme.tertiaryText(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (agencyName != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 13,
                                  color: AppTheme.tertiaryText(context),
                                ),
                                AppSpacing.gapW4,
                                Expanded(
                                  child: Text(
                                    agencyName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.secondaryText(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ..._buildStarRating(broker.rating),
                              const SizedBox(width: 6),
                              Text(
                                broker.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText(context),
                                ),
                              ),
                              if (broker.experienceYears > 0) ...[
                                AppSpacing.gapW12,
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 13,
                                  color: AppTheme.tertiaryText(context),
                                ),
                                AppSpacing.gapW4,
                                Text(
                                  '${broker.experienceYears} yr${broker.experienceYears != 1 ? 's' : ''} exp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryText(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH12,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Call ${broker.phoneNumber}'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryText(context),
                          side: BorderSide(color: AppTheme.border(context)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final convId = await ref
                              .read(messagingRepositoryProvider)
                              .getOrCreateConversation(
                                currentUserId,
                                broker.userId,
                              );
                          if (!context.mounted) return;
                          context.pushNamed(
                            RouteNames.chat,
                            pathParameters: {'conversationId': convId},
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sacredSaffron,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── UTILITIES ────────────────────────────────────────────

  List<Widget> _buildStarRating(double rating) {
    final List<Widget> stars = [];
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(
            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half_rounded,
            size: 16, color: AppColors.warning));
      } else {
        stars.add(Icon(Icons.star_outline_rounded,
            size: 16, color: AppColors.warning.withValues(alpha: 0.4)));
      }
    }
    return stars;
  }

  void _showBrokerDetailSheet(
    BuildContext context,
    BrokerProfile broker,
    String? agencyName,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppSpacing.borderRadiusXl),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          AppColors.deepMaroon.withValues(alpha: 0.1),
                      child: Text(
                        broker.name.isNotEmpty ? broker.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(broker.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (agencyName != null)
                            Text(agencyName,
                                style: TextStyle(
                                    color: AppTheme.secondaryText(context))),
                          Text(broker.phoneNumber,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryText(context))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (broker.bio.isNotEmpty) ...[
                  AppSpacing.gapH12,
                  Text(broker.bio,
                      style: TextStyle(
                          color: AppTheme.secondaryText(context),
                          height: 1.4)),
                ],
                AppSpacing.gapH12,
                Row(
                  children: [
                    ..._buildStarRating(broker.rating),
                    const SizedBox(width: 6),
                    Text(
                      '${broker.rating.toStringAsFixed(1)} \u2022 ${broker.experienceYears} yrs exp \u2022 ${broker.clientCount} clients',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText(context)),
                    ),
                  ],
                ),
                if (broker.areasServed.isNotEmpty) ...[
                  AppSpacing.gapH12,
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: broker.areasServed
                        .map((a) => Chip(
                              label: Text(a),
                              backgroundColor:
                                  AppColors.info.withValues(alpha: 0.08),
                              labelStyle: const TextStyle(
                                  fontSize: 12, color: AppColors.info),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
                AppSpacing.gapH8,
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
