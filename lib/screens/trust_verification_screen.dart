import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/models/trust_verification.dart';
import 'package:testing_flutter/data/revolutionary_features_data.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';

class TrustVerificationScreen extends StatefulWidget {
  const TrustVerificationScreen({super.key});

  @override
  State<TrustVerificationScreen> createState() =>
      _TrustVerificationScreenState();
}

class _TrustVerificationScreenState extends State<TrustVerificationScreen>
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
    final userTrust = RevolutionaryFeaturesData.mockTrustVerifications.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: context.palette.trustBlue, // Trust blue
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Trust & Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.palette.trustBlue, // Deep blue
                      context.palette.info, // Bright blue
                      context.palette.info, // Light blue
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
                          Icons.verified_user,
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
                          Icons.shield_outlined,
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
                              '🛡️ Community Verified Profiles',
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
                                    Text(
                                      userTrust.levelEmoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${userTrust.trustScore}/100 Trust Score',
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
                // Trust Status Overview
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildTrustStatusCard(userTrust),
                  ),
                ),

                const SizedBox(height: 28),

                // Verification Breakdown
                _buildSectionHeader(
                  'Verification Breakdown',
                  Icons.fact_check_outlined,
                  'Your complete verification status',
                ),
                const SizedBox(height: 16),
                _buildVerificationBreakdown(userTrust),

                const SizedBox(height: 28),

                // Recent Endorsements
                _buildSectionHeader(
                  'Recent Endorsements',
                  Icons.people_outline,
                  'Community members vouching for you',
                ),
                const SizedBox(height: 16),
                ...userTrust.endorsements
                    .take(3)
                    .map(
                      (endorsement) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildEndorsementCard(endorsement),
                      ),
                    ),

                const SizedBox(height: 28),

                // Action Cards
                _buildSectionHeader(
                  'Build Your Trust',
                  Icons.trending_up_outlined,
                  'Increase your verification level',
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
                color: context.palette.trustBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.palette.trustBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.palette.trustBlue,
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

  Widget _buildTrustStatusCard(TrustVerification trust) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: context.palette.trustBlue.withValues(alpha: isDark ? 0.2 : 0.1),
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
                  gradient: LinearGradient(
                    colors: [context.palette.trustBlue, context.palette.info],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  trust.levelEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trust.levelDisplayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.palette.trustBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Community verified profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
                      context.palette.trustBlue.withValues(alpha: 0.1),
                      context.palette.info.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.palette.trustBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${trust.trustScore}/100',
                  style: TextStyle(
                    color: context.palette.trustBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.trustBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: context.palette.trustBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${trust.totalEndorsements} community members have endorsed your profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.palette.trustBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBreakdown(TrustVerification trust) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildVerificationItem(
            'Family Friends',
            '${trust.familyFriendsCount}/5',
            Icons.people,
            trust.familyFriendsCount >= 3,
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            'Professional Network',
            '${trust.professionalCount}/2',
            Icons.work,
            trust.professionalCount >= 1,
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            'Community Leaders',
            '${trust.communityLeaderCount}/1',
            Icons.account_balance,
            trust.communityLeaderCount >= 1,
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            'Government ID',
            'Verified',
            Icons.credit_card,
            trust.verificationChecks['government_id'] == true,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
    String title,
    String status,
    IconData icon,
    bool isVerified,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isVerified
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText(context),
            ),
          ),
        ),
        Row(
          children: [
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isVerified ? Icons.check_circle : Icons.schedule,
              color: isVerified ? Colors.green : Colors.orange,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndorsementCard(Endorsement endorsement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.palette.trustBlue.withValues(alpha: 0.1),
                child: Text(
                  endorsement.endorserName.substring(0, 1),
                  style: TextStyle(
                    color: context.palette.trustBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endorsement.endorserName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          endorsement.typeIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            endorsement.relationship,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryText(context),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${endorsement.yearsKnown} years',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            endorsement.message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryText(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _buildActionCard(
          'Invite More Verifiers',
          'Add family friends and colleagues',
          Icons.person_add,
          context.palette.success,
          () => _showInviteDialog(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Complete Profile Verification',
          'Upload documents and complete all checks',
          Icons.upload_file,
          context.palette.info,
          () => _showVerificationDialog(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'View Verification Report',
          'Download your complete trust report',
          Icons.download,
          context.palette.meetingPurple,
          () => _showReportDialog(),
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
          color: AppTheme.cardSurface(context),
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

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Verifiers'),
        content: const Text(
          'Send verification requests to family friends, colleagues, and community members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Send Invites'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Verification'),
        content: const Text(
          'Upload required documents to complete your profile verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upload Documents'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trust Report'),
        content: const Text(
          'Download your complete verification report to share with families.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
