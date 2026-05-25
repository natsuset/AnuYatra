import 'package:flutter/material.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/data/premium_services_data.dart';
import 'package:testing_flutter/common/widgets/molecules/service_feature_card.dart';
import 'package:testing_flutter/common/widgets/molecules/service_progress_card.dart';

class BeautyTransformationScreen extends StatelessWidget {
  const BeautyTransformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PremiumServicesData.getServiceById(
      'beauty_transformation',
    )!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                // Beauty Transformation Specific Sections
                _buildSectionHeader('Your Beauty Journey', Icons.timeline),
                const SizedBox(height: 12),

                // Beauty Timeline
                _buildBeautyTimeline(context, service.primaryColor),

                const SizedBox(height: 24),

                // Expert Consultation
                _buildSectionHeader('Expert Consultations', Icons.person),
                const SizedBox(height: 12),

                _buildExpertCard(
                  context,
                  'Dr. Priya Sharma',
                  'Celebrity Dermatologist',
                  'Skin analysis & treatment planning',
                  'assets/experts/dermatologist.jpg',
                  service.primaryColor,
                ),

                const SizedBox(height: 12),

                _buildExpertCard(
                  context,
                  'Meera Kapoor',
                  'Bridal Makeup Artist',
                  'Professional makeup tutorials',
                  'assets/experts/makeup_artist.jpg',
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
                      'Start Your Beauty Transformation',
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

  Widget _buildBeautyTimeline(BuildContext context, Color primaryColor) {
    final steps = [
      {
        'title': 'Skin Analysis',
        'description': 'Professional assessment',
        'weeks': '6 months before',
      },
      {
        'title': 'Treatment Plan',
        'description': 'Customized skincare routine',
        'weeks': '5 months before',
      },
      {
        'title': 'Makeup Trials',
        'description': 'Perfect your wedding look',
        'weeks': '2 months before',
      },
      {
        'title': 'Final Touch-ups',
        'description': 'Last-minute preparations',
        'weeks': '1 week before',
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Step details
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppTheme.isDark(context) ? 0.2 : 0.05,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step['title']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText(context),
                            ),
                          ),
                        ),
                        Text(
                          step['weeks']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['description']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExpertCard(
    BuildContext context,
    String name,
    String title,
    String specialization,
    String imagePath,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.25 : 0.08,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Expert image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.person, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          // Expert details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  specialization,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          // Book button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Book',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          'Ready to begin your beauty transformation journey? '
          'Our experts will guide you through every step.',
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
