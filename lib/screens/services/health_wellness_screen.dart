import 'package:flutter/material.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/data/premium_services_data.dart';
import 'package:testing_flutter/widgets/service_feature_card.dart';
import 'package:testing_flutter/widgets/service_progress_card.dart';

class HealthWellnessScreen extends StatelessWidget {
  const HealthWellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PremiumServicesData.getServiceById('health_wellness')!;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with service theme
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: service.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                service.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      service.primaryColor,
                      service.accentColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative icon
                    Positioned(
                      top: 80,
                      right: 30,
                      child: Icon(
                        service.icon,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 80,
                      ),
                    ),
                    // Service info
                    Positioned(
                      bottom: 70,
                      left: 20,
                      right: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Text(
                                  '${service.estimatedPrice.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Progress Overview
                ServiceProgressCard(service: service),

                const SizedBox(height: 20),

                // Service Features
                _buildSectionHeader('What\'s Included', Icons.checklist),
                const SizedBox(height: 12),

                ...service.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ServiceFeatureCard(
                      feature: feature,
                      primaryColor: service.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Health Screening Areas
                _buildSectionHeader(
                  'Health Screening Areas',
                  Icons.medical_services,
                ),
                const SizedBox(height: 12),

                _buildHealthScreeningGrid(context, service.primaryColor),

                const SizedBox(height: 24),

                // Wellness Programs
                _buildSectionHeader('Wellness Programs', Icons.fitness_center),
                const SizedBox(height: 12),

                _buildWellnessProgram(
                  context,
                  'Pre-Wedding Fitness',
                  'Customized workout plans to help you feel your best',
                  Icons.fitness_center,
                  service.primaryColor,
                ),

                const SizedBox(height: 12),

                _buildWellnessProgram(
                  context,
                  'Mental Health Support',
                  'Counseling sessions to manage pre-wedding stress',
                  Icons.psychology,
                  service.primaryColor,
                ),

                const SizedBox(height: 12),

                _buildWellnessProgram(
                  context,
                  'Nutritional Guidance',
                  'Meal planning for optimal health and energy',
                  Icons.restaurant,
                  service.primaryColor,
                ),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showBookingDialog(context, service);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: service.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Your Wellness Journey',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepMaroon, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepMaroon,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScreeningGrid(BuildContext context, Color primaryColor) {
    final screenings = [
      {'title': 'Blood Tests', 'icon': Icons.bloodtype},
      {'title': 'Heart Health', 'icon': Icons.favorite},
      {'title': 'Vision Check', 'icon': Icons.visibility},
      {'title': 'Dental Care', 'icon': Icons.medical_services},
      {'title': 'Women\'s Health', 'icon': Icons.woman},
      {'title': 'Men\'s Health', 'icon': Icons.man},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: screenings.length,
      itemBuilder: (context, index) {
        final screening = screenings[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                screening['icon'] as IconData,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  screening['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWellnessProgram(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.tertiaryText(context),
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, PremiumService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${service.title}'),
        content: Text(
          'Ready to prioritize your health and wellness? '
          'Our medical experts will create a personalized plan for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${service.title} booking initiated!'),
                  backgroundColor: service.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: service.primaryColor,
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
