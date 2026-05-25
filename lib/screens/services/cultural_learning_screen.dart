import 'package:flutter/material.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/data/premium_services_data.dart';
import 'package:testing_flutter/common/widgets/molecules/service_feature_card.dart';
import 'package:testing_flutter/common/widgets/molecules/service_progress_card.dart';

class CulturalLearningScreen extends StatelessWidget {
  const CulturalLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PremiumServicesData.getServiceById('cultural_learning')!;

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
                    colors: [service.primaryColor, AppTheme.sacredSaffron],
                  ),
                ),
                child: Stack(
                  children: [
                    // Traditional pattern decoration
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Icon(
                        Icons.temple_hindu,
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
                _buildSectionHeader('Learning Modules', Icons.checklist),
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

                // Cultural Topics
                _buildSectionHeader('Cultural Topics', Icons.menu_book),
                const SizedBox(height: 12),

                _buildTopicCard(
                  context,
                  'Wedding Rituals',
                  'Learn the significance of each ceremony',
                  Icons.celebration,
                  service.primaryColor,
                  '12 lessons',
                ),

                const SizedBox(height: 12),

                _buildTopicCard(
                  context,
                  'Regional Customs',
                  'Understand local traditions and practices',
                  Icons.location_city,
                  service.primaryColor,
                  '8 lessons',
                ),

                const SizedBox(height: 12),

                _buildTopicCard(
                  context,
                  'Sanskrit Basics',
                  'Learn essential mantras and meanings',
                  Icons.translate,
                  service.primaryColor,
                  '15 lessons',
                ),

                const SizedBox(height: 12),

                _buildTopicCard(
                  context,
                  'Cultural History',
                  'Discover the roots of wedding traditions',
                  Icons.history_edu,
                  service.primaryColor,
                  '10 lessons',
                ),

                const SizedBox(height: 24),

                // Expert Scholars
                _buildSectionHeader('Cultural Scholars', Icons.school),
                const SizedBox(height: 12),

                _buildScholarCard(
                  context,
                  'Dr. Ramesh Gupta',
                  'Sanskrit Scholar & Vedic Expert',
                  'Specializes in wedding rituals and mantras',
                  service.primaryColor,
                ),

                const SizedBox(height: 12),

                _buildScholarCard(
                  context,
                  'Prof. Lakshmi Devi',
                  'Cultural Anthropologist',
                  'Expert in regional wedding customs',
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
                      'Begin Cultural Learning',
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

  Widget _buildTopicCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color primaryColor,
    String lessonsCount,
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
                const SizedBox(height: 4),
                Text(
                  lessonsCount,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_filled, color: primaryColor, size: 32),
        ],
      ),
    );
  }

  Widget _buildScholarCard(
    BuildContext context,
    String name,
    String title,
    String specialization,
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
          // Scholar image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.school, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          // Scholar details
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
          // Consult button
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
              'Consult',
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
          'Ready to dive deep into your cultural heritage? '
          'Our scholars will guide you through every tradition.',
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
