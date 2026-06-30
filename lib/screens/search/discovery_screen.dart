import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/search_filter.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/common/widgets/molecules/app_voice_search_bar.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  static const _recentSearchesKey = 'recent_searches_discovery';
  static const _maxRecentSearches = 5;

  final TextEditingController _searchController = TextEditingController();
  SearchType _selectedFilter = SearchType.all;
  List<Agency> _agencies = [];
  List<BrokerProfile> _brokers = [];
  Map<String, int> _agencyBrokerCounts = {};
  Map<String, String?> _brokerAgencyNames = {};
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRecentSearches();
      await _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchesKey) ?? const [];
    if (!mounted) return;
    setState(() => _recentSearches = saved);
  }

  Future<void> _saveRecentSearch(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return;
    final updated = [cleaned, ..._recentSearches.where((q) => q.toLowerCase() != cleaned.toLowerCase())]
        .take(_maxRecentSearches)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updated);
    if (!mounted) return;
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (!mounted) return;
    setState(() => _recentSearches = []);
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    final agencyRepo = ref.read(agencyRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final query = _searchController.text.trim();
    final q = query.isEmpty ? null : query;

    final agencies = await agencyRepo.searchAgencies(query: q);
    final brokers = await brokerRepo.searchBrokers(query: q);

    final agencyBrokerCounts = <String, int>{};
    for (final agency in agencies) {
      final brokerList = await brokerRepo.getBrokersByAgency(agency.id);
      agencyBrokerCounts[agency.id] = brokerList.length;
    }

    final brokerAgencyNames = <String, String?>{};
    for (final broker in brokers) {
      if (broker.agencyId != null) {
        final agency = await agencyRepo.getAgency(broker.agencyId!);
        brokerAgencyNames[broker.userId] = agency?.name;
      }
    }

    if (!mounted) return;
    setState(() {
      _agencies = agencies;
      _brokers = brokers;
      _agencyBrokerCounts = agencyBrokerCounts;
      _brokerAgencyNames = brokerAgencyNames;
      _isLoading = false;
      _hasSearched = true;
    });
    if (query.isNotEmpty) {
      await _saveRecentSearch(query);
    }
  }

  void _onFilterChanged(SearchType filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _performSearch();
  }

  int get _totalResults {
    switch (_selectedFilter) {
      case SearchType.agencies:
        return _agencies.length;
      case SearchType.brokers:
        return _brokers.length;
      case SearchType.all:
        return _agencies.length + _brokers.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          if (_recentSearches.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecentSearches(context, isDark)),
          SliverToBoxAdapter(child: _buildFilterChips(context, isDark)),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasSearched && _totalResults == 0)
            SliverFillRemaining(child: _buildEmptyState(context, isDark))
          else
            _buildResultsList(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.appBarBackground(context),
      foregroundColor: Colors.white,
      elevation: 0,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                children: [
                  Text(
                    context.l10n.discover,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  AppSpacing.gapH12,
                  _buildSearchBar(context, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return AppVoiceSearchBar(
      controller: _searchController,
      hintText: context.l10n.searchBrokersAgenciesHint,
      onSubmitted: (_) => _performSearch(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_totalResults results',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondaryText(context),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: SearchType.values.map((filter) {
              final isSelected = _selectedFilter == filter;
              return FilterChip(
                label: Text(filter.displayName),
                selected: isSelected,
                onSelected: (_) => _onFilterChanged(filter),
                backgroundColor: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.secondaryText(context),
                ),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                      : AppTheme.border(context),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedXl,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: 0,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 16, color: AppTheme.tertiaryText(context)),
              AppSpacing.gapW4,
              Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryText(context),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH8,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _recentSearches
                .map((q) => ActionChip(
                      label: Text(q),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryText(context),
                      ),
                      avatar: Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: AppTheme.tertiaryText(context),
                      ),
                      backgroundColor: isDark
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: AppTheme.border(context),
                        width: 0.5,
                      ),
                      onPressed: () {
                        _searchController.text = q;
                        _performSearch();
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.allXxl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              context.l10n.noResultsFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText(context),
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'Try adjusting your search or filters to find brokers and agencies',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            AppSpacing.gapH24,
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _selectedFilter = SearchType.all;
                _performSearch();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.clearSearch),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, bool isDark) {
    final List<Widget> items = [];

    // Add agency section header and cards
    if (_selectedFilter != SearchType.brokers && _agencies.isNotEmpty) {
      items.add(_buildSectionHeader(
        context,
        isDark,
        icon: Icons.business_rounded,
        title: 'Agencies',
        count: _agencies.length,
      ));
      for (final agency in _agencies) {
        items.add(_buildAgencyCard(context, isDark, agency));
      }
    }

    // Add broker section header and cards
    if (_selectedFilter != SearchType.agencies && _brokers.isNotEmpty) {
      items.add(_buildSectionHeader(
        context,
        isDark,
        icon: Icons.person_search_rounded,
        title: context.l10n.activeBrokers,
        count: _brokers.length,
      ));
      for (final broker in _brokers) {
        items.add(_buildBrokerCard(context, isDark, broker));
      }
    }

    // Bottom padding
    items.add(AppSpacing.gapH24);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => items[index],
        childCount: items.length,
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.md,
        top: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          AppSpacing.gapW8,
          Text(
            title,
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyCard(BuildContext context, bool isDark, Agency agency) {
    final brokerCount = _agencyBrokerCounts[agency.id] ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      child: Material(
        color: AppTheme.cardSurface(context),
        borderRadius: AppSpacing.roundedLg,
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: AppSpacing.roundedLg,
          onTap: () => _showAgencyDetail(context, agency),
          child: Container(
            padding: AppSpacing.allMd,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: isDark
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agency icon/logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      agency.name.isNotEmpty ? agency.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Agency details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agency.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (agency.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.palette.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.gapH4,
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.tertiaryText(context),
                          ),
                          AppSpacing.gapW4,
                          Flexible(
                            child: Text(
                              '${agency.city}, ${agency.state}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.gapW12,
                          Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: AppTheme.tertiaryText(context),
                          ),
                          AppSpacing.gapW4,
                          Text(
                            '$brokerCount broker${brokerCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      // Rating
                      Row(
                        children: [
                          ..._buildStarRating(agency.rating),
                          const SizedBox(width: 6),
                          Text(
                            agency.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText(context),
                            ),
                          ),
                        ],
                      ),
                      if (agency.specializations.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: agency.specializations.take(3).map((spec) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrokerCard(BuildContext context, bool isDark, BrokerProfile broker) {
    final agencyName = _brokerAgencyNames[broker.userId];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      child: Material(
        color: AppTheme.cardSurface(context),
        borderRadius: AppSpacing.roundedLg,
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: AppSpacing.roundedLg,
          onTap: () => _showBrokerDetail(context, broker),
          child: Container(
            padding: AppSpacing.allMd,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: isDark
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo placeholder / avatar
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          broker.name.isNotEmpty ? broker.name[0].toUpperCase() : 'B',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    // Online indicator
                    if (broker.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: context.palette.success,
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
                // Broker details
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
                          if (broker.experienceYears > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.palette.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${broker.experienceYears} yr${broker.experienceYears != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.info,
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
                      // Rating
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
                          if (broker.clientCount > 0) ...[
                            AppSpacing.gapW12,
                            Icon(
                              Icons.group_outlined,
                              size: 14,
                              color: AppTheme.tertiaryText(context),
                            ),
                            AppSpacing.gapW4,
                            Flexible(
                              child: Text(
                                '${broker.clientCount} client${broker.clientCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (broker.areasServed.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppTheme.tertiaryText(context),
                            ),
                            AppSpacing.gapW4,
                            Expanded(
                              child: Text(
                                broker.areasServed.take(3).join(', '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (broker.specializations.isNotEmpty) ...[
                        AppSpacing.gapH8,
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: broker.specializations.take(3).map((spec) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                                    : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAgencyDetail(BuildContext context, Agency agency) async {
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final brokers = await brokerRepo.getBrokersByAgency(agency.id);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppSpacing.borderRadiusXl),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                // Agency header
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          agency.name.isNotEmpty ? agency.name[0] : 'A',
                          style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agency.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          Text('${agency.city}, ${agency.state}',
                            style: TextStyle(color: AppTheme.secondaryText(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH16,
                if (agency.description.isNotEmpty) ...[
                  Text(agency.description, style: TextStyle(color: AppTheme.secondaryText(context), height: 1.5)),
                  AppSpacing.gapH16,
                ],
                // Specializations
                if (agency.specializations.isNotEmpty) ...[
                  Text(context.l10n.specializationsLabel, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText(context))),
                  AppSpacing.gapH8,
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: agency.specializations.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  AppSpacing.gapH16,
                ],
                // Connect button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendLinkRequest(context, agencyId: agency.id);
                  },
                  icon: const Icon(Icons.link),
                  label: Text(context.l10n.connectWithAgency),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                ),
                AppSpacing.gapH16,
                // Brokers list
                if (brokers.isNotEmpty) ...[
                  Text('${brokers.length} Broker${brokers.length != 1 ? 's' : ''}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText(context))),
                  AppSpacing.gapH8,
                  ...brokers.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      child: Text(b.name.isNotEmpty ? b.name[0] : '?',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(b.name),
                    subtitle: Text('${b.experienceYears} yrs exp • ${b.clientCount} clients'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._buildStarRating(b.rating),
                        AppSpacing.gapW4,
                        Text(b.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBrokerDetail(BuildContext context, BrokerProfile broker) async {
    String? agencyName;
    if (broker.agencyId != null) {
      final agencyRepo = ref.read(agencyRepositoryProvider);
      agencyName = (await agencyRepo.getAgency(broker.agencyId!))?.name;
    }
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
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
                    width: 40, height: 4,
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
                      backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      child: Text(
                        broker.name.isNotEmpty ? broker.name[0] : '?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(broker.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (agencyName != null) Text(agencyName, style: TextStyle(color: AppTheme.secondaryText(context))),
                          Text('${broker.experienceYears} yrs experience • ${broker.clientCount} clients',
                            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText(context))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (broker.bio.isNotEmpty) ...[
                  AppSpacing.gapH12,
                  Text(broker.bio, style: TextStyle(color: AppTheme.secondaryText(context), height: 1.4)),
                ],
                if (broker.areasServed.isNotEmpty) ...[
                  AppSpacing.gapH12,
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: broker.areasServed.map((a) => Chip(
                      label: Text(a),
                      backgroundColor: context.palette.info.withValues(alpha: 0.08),
                      labelStyle: TextStyle(fontSize: 12, color: context.palette.info),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
                AppSpacing.gapH16,
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendLinkRequest(context, brokerId: broker.userId);
                  },
                  icon: const Icon(Icons.link),
                  label: Text(context.l10n.connectWithBroker),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendLinkRequest(BuildContext context, {String? agencyId, String? brokerId}) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final agencyRepo = ref.read(agencyRepositoryProvider);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final linkRepo = ref.read(linkRepositoryProvider);

    final currentUser = authState.user;
    final type = agencyId != null
        ? LinkRequestType.parentToAgency
        : LinkRequestType.parentToBroker;
    final toUserId = agencyId ?? brokerId ?? '';

    String toUserName = '';
    if (agencyId != null) {
      final agency = await agencyRepo.getAgency(agencyId);
      if (!context.mounted) return;
      toUserName = agency?.name ?? context.l10n.agencyLabel;
    } else if (brokerId != null) {
      toUserName = (await brokerRepo.getBrokerProfile(brokerId))?.name ?? 'Broker';
    }

    await linkRepo.sendLinkRequest(
      fromUserId: currentUser.uid,
      toUserId: toUserId,
      fromUserName: currentUser.displayName,
      toUserName: toUserName,
      type: type,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.connectionRequestSent),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _buildStarRating(double rating) {
    final List<Widget> stars = [];
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star_rounded, size: 16, color: context.palette.warning));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(Icon(Icons.star_half_rounded, size: 16, color: context.palette.warning));
      } else {
        stars.add(Icon(Icons.star_outline_rounded, size: 16, color: context.palette.warning.withValues(alpha: 0.4)));
      }
    }
    return stars;
  }
}
