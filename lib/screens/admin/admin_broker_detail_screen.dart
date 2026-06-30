import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/broker_profile.dart';

/// Agency-admin view of one broker: profile, performance stats, specializations,
/// areas served, and the clients + profiles they handle. Read-only oversight.
class AdminBrokerDetailScreen extends ConsumerStatefulWidget {
  const AdminBrokerDetailScreen({super.key, required this.brokerUserId});

  final String brokerUserId;

  @override
  ConsumerState<AdminBrokerDetailScreen> createState() =>
      _AdminBrokerDetailScreenState();
}

class _AdminBrokerDetailScreenState
    extends ConsumerState<AdminBrokerDetailScreen> {
  BrokerProfile? _broker;
  AppUser? _user;
  List<_ClientRow> _clients = [];
  int _profileCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    final broker = await brokerRepo.getBrokerProfile(widget.brokerUserId);
    final user = await userRepo.getUser(widget.brokerUserId);
    final parentIds = await linkRepo.getConnectedParentIds(widget.brokerUserId);
    final candidates =
        await profileRepo.getCandidatesByBroker(widget.brokerUserId);

    final clients = <_ClientRow>[];
    for (final pid in parentIds) {
      final p = await profileRepo.getParentProfile(pid);
      final u = await userRepo.getUser(pid);
      clients.add(_ClientRow(
        userId: pid,
        name: p?.name ?? u?.displayName ?? 'Client',
        subtitle: p == null
            ? ''
            : [p.city, 'seeking ${p.lookingForDisplay}']
                .where((s) => s.isNotEmpty)
                .join(' · '),
      ));
    }

    if (!mounted) return;
    setState(() {
      _broker = broker;
      _user = user;
      _clients = clients;
      _profileCount = candidates.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = context.palette;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final broker = _broker;
    if (broker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Broker')),
        body: const Center(child: Text('Broker not found')),
      );
    }

    final isActive = _user?.isActive ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(broker.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header
          Container(
            padding: AppSpacing.allMd,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              gradient: LinearGradient(
                colors: [
                  colors.secondary.withValues(alpha: 0.14),
                  colors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: colors.secondary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.secondary.withValues(alpha: 0.18),
                  child: Text(
                    broker.name.isNotEmpty ? broker.name[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppSpacing.gapW16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(broker.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(broker.phoneNumber,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                      AppSpacing.gapH8,
                      Row(
                        children: [
                          _Tag(
                            label: isActive ? 'Active' : 'Inactive',
                            color: isActive ? palette.success : colors.onSurfaceVariant,
                          ),
                          if (broker.rating > 0) ...[
                            AppSpacing.gapW8,
                            _Tag(
                              label: '★ ${broker.rating.toStringAsFixed(1)}',
                              color: palette.warning,
                            ),
                          ],
                          if (broker.isVerified) ...[
                            AppSpacing.gapW8,
                            _Tag(label: 'Verified', color: palette.info),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapH16,

          // Performance stats
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Clients',
                  value: '${_clients.length}',
                  icon: Icons.family_restroom_rounded,
                  color: palette.info,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: _Stat(
                  label: 'Profiles',
                  value: '$_profileCount',
                  icon: Icons.badge_rounded,
                  color: palette.success,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: _Stat(
                  label: 'Experience',
                  value: '${broker.experienceYears}y',
                  icon: Icons.work_history_rounded,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,

          if (broker.bio.isNotEmpty) ...[
            _Card(
              colors: colors,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  AppSpacing.gapH8,
                  Text(broker.bio,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant, height: 1.4)),
                ],
              ),
            ),
            AppSpacing.gapH16,
          ],

          if (broker.specializations.isNotEmpty) ...[
            _ChipsCard(
              title: 'Specializations',
              items: broker.specializations,
              color: palette.info,
              colors: colors,
              theme: theme,
            ),
            AppSpacing.gapH16,
          ],

          if (broker.areasServed.isNotEmpty) ...[
            _ChipsCard(
              title: 'Areas Served',
              items: broker.areasServed,
              color: colors.primary,
              colors: colors,
              theme: theme,
            ),
            AppSpacing.gapH16,
          ],

          // Clients handled
          Text('Clients (${_clients.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          AppSpacing.gapH8,
          if (_clients.isEmpty)
            Text('No connected clients yet.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant))
          else
            ..._clients.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: colors.surface,
                    borderRadius: AppSpacing.roundedMd,
                    child: InkWell(
                      borderRadius: AppSpacing.roundedMd,
                      onTap: () => context.pushNamed(
                        RouteNames.brokerClientHub,
                        pathParameters: {'id': c.userId},
                      ),
                      child: Container(
                        padding: AppSpacing.allSm,
                        decoration: BoxDecoration(
                          borderRadius: AppSpacing.roundedMd,
                          border:
                              Border.all(color: colors.outlineVariant, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  colors.primary.withValues(alpha: 0.12),
                              child: Text(
                                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600)),
                                  if (c.subtitle.isNotEmpty)
                                    Text(c.subtitle,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                            color: colors.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: colors.outline, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ClientRow {
  const _ClientRow(
      {required this.userId, required this.name, required this.subtitle});
  final String userId;
  final String name;
  final String subtitle;
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapH12,
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.0)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.colors});
  final Widget child;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: child,
    );
  }
}

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({
    required this.title,
    required this.items,
    required this.color,
    required this.colors,
    required this.theme,
  });
  final String title;
  final List<String> items;
  final Color color;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          AppSpacing.gapH12,
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
