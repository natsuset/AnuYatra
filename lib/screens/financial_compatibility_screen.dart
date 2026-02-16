import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/models/financial_profile.dart';
import 'package:testing_flutter/data/revolutionary_features_data.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';

class FinancialCompatibilityScreen extends StatefulWidget {
  const FinancialCompatibilityScreen({super.key});

  @override
  State<FinancialCompatibilityScreen> createState() =>
      _FinancialCompatibilityScreenState();
}

class _FinancialCompatibilityScreenState
    extends State<FinancialCompatibilityScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userFinancialProfile =
        RevolutionaryFeaturesData.mockFinancialProfiles.first;
    final compatibility =
        RevolutionaryFeaturesData.mockFinancialCompatibilities.first;
    final marketInsights = RevolutionaryFeaturesData.marketInsights;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.successDark, // Financial green
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Financial Compatibility',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.successDark, // Deep green
                      AppColors.success, // Bright green
                      AppColors.successLight, // Light green
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: 60,
                      right: -10,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 80,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: -20,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white.withValues(alpha: 0.1),
                          size: 60,
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 60,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '💰 Transparent Financial Planning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.assessment,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${userFinancialProfile.profileCompleteness}% Profile Complete',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Financial Profile Overview
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildFinancialProfileCard(userFinancialProfile),
                  ),
                ),

                const SizedBox(height: 28),

                // Top Matches
                _buildSectionHeader(
                  'Top Financial Matches',
                  Icons.people_outline,
                  'Families with similar financial values',
                ),
                const SizedBox(height: 16),
                _buildMatchCard(compatibility),

                const SizedBox(height: 28),

                // Financial Compatibility Breakdown
                _buildSectionHeader(
                  'Compatibility Analysis',
                  Icons.analytics_outlined,
                  'Detailed financial alignment scores',
                ),
                const SizedBox(height: 16),
                _buildCompatibilityBreakdown(compatibility),

                const SizedBox(height: 28),

                // Market Insights
                _buildSectionHeader(
                  'Market Insights',
                  Icons.insights_outlined,
                  'Financial trends in your area',
                ),
                const SizedBox(height: 16),
                _buildMarketInsights(marketInsights),

                const SizedBox(height: 28),

                // Action Cards
                _buildSectionHeader(
                  'Improve Your Profile',
                  Icons.trending_up_outlined,
                  'Complete your financial planning',
                ),
                const SizedBox(height: 16),
                _buildActionCards(),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.successDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.secondaryText(context).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialProfileCard(FinancialProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.successDark.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.successDark, AppColors.success],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Financial Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.incomeDisplayRange,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successDark.withValues(alpha: 0.1),
                      AppColors.success.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.successDark.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${profile.profileCompleteness}%',
                  style: const TextStyle(
                    color: AppColors.successDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile details
          _buildFinancialDetailRow('Lifestyle', profile.lifestyleDisplayName),
          const SizedBox(height: 12),
          _buildFinancialDetailRow(
            'Saving Approach',
            profile.savingDisplayName,
          ),
          const SizedBox(height: 12),
          _buildFinancialDetailRow(
            'Dual Income',
            profile.supportsDualIncome ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondaryText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(FinancialCompatibility compatibility) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
                radius: 24,
                backgroundColor: AppColors.successDark.withValues(alpha: 0.1),
                child: const Text(
                  'P',
                  style: TextStyle(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priya Gupta\'s Family',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      compatibility.compatibilityLevel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getCompatibilityColor(
                          compatibility.overallCompatibility,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getCompatibilityColor(
                    compatibility.overallCompatibility,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      compatibility.compatibilityEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${compatibility.overallCompatibility}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getCompatibilityColor(
                          compatibility.overallCompatibility,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alignment points
          if (compatibility.alignmentPoints.isNotEmpty) ...[
            Text(
              'Strong Alignment:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            ...compatibility.alignmentPoints
                .take(2)
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.successDark,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],

          if (compatibility.discussionNeeded.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Discussion Needed:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            ...compatibility.discussionNeeded
                .take(1)
                .map(
                  (point) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startFinancialDiscussion(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Financial Discussion',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityBreakdown(FinancialCompatibility compatibility) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: compatibility.categoryScores.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildScoreItem(entry.key, entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreItem(String category, int score) {
    final color = _getCompatibilityColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildMarketInsights(Map<String, dynamic> insights) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInsightRow(
            'Average Wedding Budget',
            insights['averageWeddingBudget'],
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Dual Income Preference',
            '${insights['dualIncomePreference']}% of families',
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Home Purchase Priority',
            '${insights['homePurchasePriority']}% prioritize within 3 years',
            Icons.home,
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Education Investment',
            '${insights['educationInvestmentFocus']}% focus on quality education',
            Icons.school,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.successDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.successDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _buildActionCard(
          'Budget Planner',
          'Plan your wedding budget with family',
          Icons.calculate,
          AppColors.meetingPurpleLight,
          () => _showBudgetPlanner(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Complete Financial Profile',
          'Add future goals and investment preferences',
          Icons.timeline,
          AppColors.info,
          () => _showProfileCompletion(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Financial Counseling',
          'Get expert advice on financial planning',
          Icons.support_agent,
          AppColors.success,
          () => _showCounselingOptions(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 90) return AppColors.successDark;
    if (score >= 80) return AppColors.success;
    if (score >= 70) return AppColors.successLight;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _startFinancialDiscussion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting financial discussion...'),
        backgroundColor: AppColors.successDark,
      ),
    );
  }

  void _showBudgetPlanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wedding Budget Planner'),
        content: const Text(
          'Plan your wedding budget with detailed breakdown and family contributions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successDark,
            ),
            child: const Text('Start Planning'),
          ),
        ],
      ),
    );
  }

  void _showProfileCompletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Profile'),
        content: const Text(
          'Add your future financial goals and investment preferences for better matches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successDark,
            ),
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  void _showCounselingOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Financial Counseling'),
        content: const Text(
          'Get expert guidance on financial planning and investment strategies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successDark,
            ),
            child: const Text('Book Session'),
          ),
        ],
      ),
    );
  }
}
