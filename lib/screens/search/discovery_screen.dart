import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/agency.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/search_filter.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchType _selectedFilter = SearchType.all;
  List<Agency> _agencies = [];
  List<BrokerProfile> _brokers = [];
  Map<String, int> _agencyBrokerCounts = {};
  Map<String, String?> _brokerAgencyNames = {};
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Load all results on init
    WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      expandedHeight: 130,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search brokers, agencies, cities...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTertiaryText : AppColors.lightSecondaryText,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.darkTertiaryText : AppColors.lightSecondaryText,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                selectedColor: AppColors.sacredSaffron.withValues(alpha: 0.15),
                checkmarkColor: AppColors.sacredSaffron,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.sacredSaffron
                      : AppTheme.secondaryText(context),
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.sacredSaffron.withValues(alpha: 0.5)
                      : AppTheme.border(context),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sacredSaffron.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.sacredSaffron,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters to find brokers and agencies',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _selectedFilter = SearchType.all;
                _performSearch();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear search'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.sacredSaffron,
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
        title: 'Brokers',
        count: _brokers.length,
      ));
      for (final broker in _brokers) {
        items.add(_buildBrokerCard(context, isDark, broker));
      }
    }

    // Bottom padding
    items.add(const SizedBox(height: 24));

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.sacredSaffron),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText(context),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.sacredSaffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sacredSaffron,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAgencyDetail(context, agency),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : AppColors.lightDivider,
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
                    gradient: AppColors.primaryGradient,
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
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.tertiaryText(context),
                          ),
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: AppTheme.tertiaryText(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$brokerCount broker${brokerCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.sacredSaffron.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.sacredSaffronLight
                                      : AppColors.deepMaroon,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBrokerDetail(context, broker),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : AppColors.lightDivider,
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
                            ? AppColors.darkSurfaceVariant
                            : AppColors.deepMaroon.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          broker.name.isNotEmpty ? broker.name[0].toUpperCase() : 'B',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.sacredSaffronLight
                                : AppColors.deepMaroon,
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
                            color: AppColors.success,
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
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${broker.experienceYears} yr${broker.experienceYears != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
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
                            const SizedBox(width: 4),
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
                            const SizedBox(width: 12),
                            Icon(
                              Icons.group_outlined,
                              size: 14,
                              color: AppTheme.tertiaryText(context),
                            ),
                            const SizedBox(width: 4),
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
                            const SizedBox(width: 4),
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: broker.specializations.take(3).map((spec) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.deepMaroon.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.sacredSaffronLight
                                      : AppColors.deepMaroon,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                const SizedBox(height: 16),
                // Agency header
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
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
                const SizedBox(height: 16),
                if (agency.description.isNotEmpty) ...[
                  Text(agency.description, style: TextStyle(color: AppTheme.secondaryText(context), height: 1.5)),
                  const SizedBox(height: 16),
                ],
                // Specializations
                if (agency.specializations.isNotEmpty) ...[
                  Text('Specializations', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText(context))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: agency.specializations.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: AppColors.sacredSaffron.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.sacredSaffron),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Connect button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendLinkRequest(context, agencyId: agency.id);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Connect with Agency'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredSaffron,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                // Brokers list
                if (brokers.isNotEmpty) ...[
                  Text('${brokers.length} Broker${brokers.length != 1 ? 's' : ''}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText(context))),
                  const SizedBox(height: 8),
                  ...brokers.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.deepMaroon.withValues(alpha: 0.1),
                      child: Text(b.name.isNotEmpty ? b.name[0] : '?',
                        style: const TextStyle(color: AppColors.deepMaroon, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(b.name),
                    subtitle: Text('${b.experienceYears} yrs exp • ${b.clientCount} clients'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._buildStarRating(b.rating),
                        const SizedBox(width: 4),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.deepMaroon.withValues(alpha: 0.1),
                      child: Text(
                        broker.name.isNotEmpty ? broker.name[0] : '?',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepMaroon),
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
                  const SizedBox(height: 12),
                  Text(broker.bio, style: TextStyle(color: AppTheme.secondaryText(context), height: 1.4)),
                ],
                if (broker.areasServed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: broker.areasServed.map((a) => Chip(
                      label: Text(a),
                      backgroundColor: AppColors.info.withValues(alpha: 0.08),
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.info),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendLinkRequest(context, brokerId: broker.userId);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Connect with Broker'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredSaffron,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      toUserName = (await agencyRepo.getAgency(agencyId))?.name ?? 'Agency';
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
      const SnackBar(
        content: Text('Connection request sent!'),
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
        stars.add(const Icon(Icons.star_rounded, size: 16, color: AppColors.warning));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half_rounded, size: 16, color: AppColors.warning));
      } else {
        stars.add(Icon(Icons.star_outline_rounded, size: 16, color: AppColors.warning.withValues(alpha: 0.4)));
      }
    }
    return stars;
  }
}
