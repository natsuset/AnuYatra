import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/routing/route_names.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
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
          context.l10n.appName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: AppSpacing.allMd,
        children: [
          // Astrology Match — Kundali / Guna Milan
          _SectionCard(
            icon: Icons.stars_rounded,
            title: 'Kundali Match',
            subtitle: 'Guna Milan · Ashtakoota compatibility score',
            color: const Color(0xFF7B2FBE),
            onTap: () => context.pushNamed(RouteNames.astrologyCalculator),
          ),
          AppSpacing.gapH12,

          // Premium Services Section
          _SectionCard(
            icon: Icons.auto_awesome,
            title: context.l10n.vivahaSamskara,
            subtitle: context.l10n.vivahaSamskaraDesc,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VivahaSamskaraHomeScreen(),
              ),
            ),
          ),
          AppSpacing.gapH12,

          // Trust Verification
          _SectionCard(
            icon: Icons.verified_user,
            title: context.l10n.trustVerification,
            subtitle: 'Verify profiles with trust scores & endorsements',
            color: context.palette.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TrustVerificationScreen(),
              ),
            ),
          ),
          AppSpacing.gapH12,

          // Financial Compatibility
          _SectionCard(
            icon: Icons.account_balance_wallet,
            title: context.l10n.financialCompatibility,
            subtitle: 'Analyze financial alignment between profiles',
            color: context.palette.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinancialCompatibilityScreen(),
              ),
            ),
          ),
          AppSpacing.gapH24,

          // Coming Soon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ),
                AppSpacing.gapH12,
                Text(
                  context.l10n.comingSoon,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  context.l10n.comingSoonHint,
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
      borderRadius: AppSpacing.roundedLg,
      elevation: isDark ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(icon, color: color),
              ),
              AppSpacing.gapW16,
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
