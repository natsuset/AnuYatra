import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/data/premium_services_data.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/common/widgets/molecules/premium_service_card.dart';
import 'package:testing_flutter/common/widgets/molecules/appointment_card.dart';
import 'package:testing_flutter/common/widgets/molecules/task_card.dart';
import 'package:testing_flutter/screens/services/beauty_transformation_screen.dart';
import 'package:testing_flutter/screens/services/health_wellness_screen.dart';
import 'package:testing_flutter/screens/services/cultural_learning_screen.dart';

class VivahaSamskaraHomeScreen extends StatefulWidget {
  const VivahaSamskaraHomeScreen({super.key});

  @override
  State<VivahaSamskaraHomeScreen> createState() =>
      _VivahaSamskaraHomeScreenState();
}

class _VivahaSamskaraHomeScreenState extends State<VivahaSamskaraHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    final services = PremiumServicesData.services;
    final upcomingAppointments = PremiumServicesData.upcomingAppointments;
    final todaysTasks = PremiumServicesData.todaysTasks;
    final overallProgress = PremiumServicesData.getOverallProgress();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced Premium App Bar
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.deepMaroon,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Vivaha Samskara',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.deepMaroon,
                      AppTheme.deepMaroon.withValues(alpha: 0.9),
                      AppTheme.sacredSaffron.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Enhanced decorative pattern
                    Positioned(
                      top: 60,
                      right: -20,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 80,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 100,
                      left: -10,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Icon(
                          Icons.diamond_outlined,
                          color: Colors.white.withValues(alpha: 0.1),
                          size: 60,
                        ),
                      ),
                    ),
                    // Premium gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    // Enhanced content
                    Positioned(
                      bottom: 70,
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
                              '✨ Premium Wedding Services',
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
                              Expanded(
                                child: Container(
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
                                      Icon(
                                        Icons.trending_up,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${(overallProgress * 100).toInt()}% Journey Complete',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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

          // Enhanced Content with animations
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Enhanced Progress Overview
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildEnhancedProgressOverview(overallProgress),
                  ),
                ),

                const SizedBox(height: 28),

                // Enhanced Today's Tasks
                if (todaysTasks.isNotEmpty) ...[
                  _buildEnhancedSectionHeader(
                    'Today\'s Focus',
                    Icons.today_outlined,
                    'Stay on track with your daily goals',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: todaysTasks.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.only(
                            right: index < todaysTasks.length - 1 ? 16 : 0,
                          ),
                          child: TaskCard(task: todaysTasks[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Enhanced Upcoming Appointments
                if (upcomingAppointments.isNotEmpty) ...[
                  _buildEnhancedSectionHeader(
                    'Upcoming Sessions',
                    Icons.calendar_month_outlined,
                    'Your scheduled expert consultations',
                  ),
                  const SizedBox(height: 16),
                  ...upcomingAppointments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final appointment = entry.value;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 400 + (index * 150)),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: AppointmentCard(appointment: appointment),
                    );
                  }),
                  const SizedBox(height: 28),
                ],

                // Enhanced Premium Services
                _buildEnhancedSectionHeader(
                  'Premium Services',
                  Icons.auto_awesome_outlined,
                  'Comprehensive wedding preparation modules',
                ),
                const SizedBox(height: 16),

                // Enhanced Services Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 3
                        : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      child: PremiumServiceCard(
                        service: services[index],
                        onTap: () => _navigateToService(services[index]),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressOverview(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.sacredSaffron.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.sacredSaffron, AppTheme.deepMaroon],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Wedding Journey',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Preparing for your special day',
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
          const SizedBox(height: 24),

          // Enhanced Progress Bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.divider(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.divider(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOutCubic,
                  height: 12,
                  width: (MediaQuery.of(context).size.width - 88) * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.sacredSaffron,
                        AppTheme.deepMaroon.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sacredSaffron.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${PremiumServicesData.getTotalCompletedTasks()} of ${PremiumServicesData.getTotalTasks()} tasks',
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'completed',
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                      AppTheme.sacredSaffron.withValues(alpha: 0.1),
                      AppTheme.deepMaroon.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.sacredSaffron.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.deepMaroon,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionHeader(
    String title,
    IconData icon,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.deepMaroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.deepMaroon, size: 20),
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
                      color: AppTheme.deepMaroon,
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

  void _navigateToService(PremiumService service) {
    Widget? targetScreen;

    switch (service.type) {
      case ServiceType.beautyTransformation:
        targetScreen = const BeautyTransformationScreen();
        break;
      case ServiceType.healthWellness:
        targetScreen = const HealthWellnessScreen();
        break;
      case ServiceType.culturalLearning:
        targetScreen = const CulturalLearningScreen();
        break;
      case ServiceType.financialPlanning:
      case ServiceType.spiritualGuidance:
        // TODO: Implement remaining service screens
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.title} coming soon!'),
            backgroundColor: service.primaryColor,
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen!),
    );
  }
}
