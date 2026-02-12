import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/screens/vivaha_samskara_home_screen.dart';
import 'package:testing_flutter/screens/trust_verification_screen.dart';
import 'package:testing_flutter/screens/financial_compatibility_screen.dart';

/// Hub screen for the Anuyatra tab in Parent and Candidate shells.
/// Combines Vivaha Samskara (premium services) + Trust Verification + Financial Compatibility.
class AnuyatraHubScreen extends StatelessWidget {
  const AnuyatraHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Anuyatra',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Premium Services Section
          _SectionCard(
            icon: Icons.auto_awesome,
            title: 'Vivaha Samskara',
            subtitle: 'Premium wedding preparation services',
            color: AppColors.sacredSaffron,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VivahaSamskaraHomeScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Trust Verification
          _SectionCard(
            icon: Icons.verified_user,
            title: 'Trust Verification',
            subtitle: 'Verify profiles with trust scores & endorsements',
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TrustVerificationScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Financial Compatibility
          _SectionCard(
            icon: Icons.account_balance_wallet,
            title: 'Financial Compatibility',
            subtitle: 'Analyze financial alignment between profiles',
            color: AppColors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinancialCompatibilityScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Coming Soon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.sacredSaffron.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.sacredSaffron.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 40,
                  color: AppColors.sacredSaffron.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'More features coming soon!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Virtual meetings, AI matching, and more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
