import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';

class PremiumServicesData {
  static List<PremiumService> get services => [
    // Beauty Transformation
    const PremiumService(
      id: 'beauty_transformation',
      title: 'Beauty Transformation',
      description: 'Complete bridal beauty journey with expert guidance',
      type: ServiceType.beautyTransformation,
      icon: Icons.face_retouching_natural,
      primaryColor: Color(0xFFE91E63), // Pink
      accentColor: Color(0xFFF8BBD9),
      features: [
        'Skincare consultation & treatment plan',
        'Professional makeup tutorials',
        'Hair styling sessions',
        'Pre-wedding fitness guidance',
        'Beauty timeline planning',
        'Product recommendations',
      ],
      totalTasks: 12,
      estimatedPrice: 25000,
    ),

    // Health & Wellness
    const PremiumService(
      id: 'health_wellness',
      title: 'Health & Wellness',
      description: 'Complete health checkup and wellness planning',
      type: ServiceType.healthWellness,
      icon: Icons.favorite,
      primaryColor: Color(0xFF4CAF50), // Green
      accentColor: Color(0xFFC8E6C9),
      features: [
        'Pre-marriage health screening',
        'Mental health counseling',
        'Nutritional planning',
        'Fertility guidance',
        'Couple wellness activities',
        'Health monitoring',
      ],
      totalTasks: 8,
      estimatedPrice: 35000,
    ),

    // Cultural Learning
    const PremiumService(
      id: 'cultural_learning',
      title: 'Cultural Learning',
      description: 'Deep dive into traditions and wedding customs',
      type: ServiceType.culturalLearning,
      icon: Icons.school,
      primaryColor: AppTheme.deepMaroon,
      accentColor: Color(0xFFFFCDD2),
      features: [
        'Wedding ritual explanations',
        'Regional custom guidance',
        'Sanskrit learning basics',
        'Cultural significance education',
        'Interfaith wedding support',
        'Expert scholar consultations',
      ],
      totalTasks: 15,
      estimatedPrice: 15000,
    ),

    // Financial Planning
    const PremiumService(
      id: 'financial_planning',
      title: 'Financial Planning',
      description: 'Smart financial preparation for your future',
      type: ServiceType.financialPlanning,
      icon: Icons.account_balance,
      primaryColor: Color(0xFF2196F3), // Blue
      accentColor: Color(0xFFBBDEFB),
      features: [
        'Wedding budget planning',
        'Investment guidance',
        'Insurance planning',
        'Joint account setup',
        'Property planning advice',
        'Financial goal setting',
      ],
      totalTasks: 10,
      estimatedPrice: 20000,
    ),

    // Spiritual Guidance
    const PremiumService(
      id: 'spiritual_guidance',
      title: 'Spiritual Guidance',
      description: 'Spiritual preparation and alignment for married life',
      type: ServiceType.spiritualGuidance,
      icon: Icons.self_improvement,
      primaryColor: AppTheme.sacredSaffron,
      accentColor: Color(0xFFFFE0B2),
      features: [
        'Detailed horoscope matching',
        'Spiritual counseling sessions',
        'Guided meditation programs',
        'Daily prayer resources',
        'Vastu consultation',
        'Spiritual community access',
      ],
      totalTasks: 7,
      estimatedPrice: 18000,
    ),
  ];

  static List<ServiceAppointment> get upcomingAppointments => [
    ServiceAppointment(
      id: 'beauty_consult_1',
      serviceId: 'beauty_transformation',
      title: 'Skincare Consultation',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      expertName: 'Dr. Priya Sharma',
      expertRole: 'Dermatologist',
      location: 'Online',
      description: 'Initial skin assessment and treatment plan discussion',
      estimatedDuration: const Duration(minutes: 45),
    ),
    ServiceAppointment(
      id: 'health_checkup_1',
      serviceId: 'health_wellness',
      title: 'Comprehensive Health Checkup',
      dateTime: DateTime.now().add(const Duration(days: 5, hours: 9)),
      expertName: 'Dr. Rajesh Kumar',
      expertRole: 'General Physician',
      location: 'Apollo Hospital, Bangalore',
      description:
          'Complete health screening including blood tests and consultation',
      estimatedDuration: const Duration(hours: 2),
    ),
  ];

  static List<ServiceTask> get todaysTasks => [
    const ServiceTask(
      id: 'skincare_routine',
      serviceId: 'beauty_transformation',
      title: 'Start Daily Skincare Routine',
      description: 'Begin the recommended morning and evening skincare regimen',
      dueDate: null, // Today
      priority: TaskPriority.high,
      resources: ['skincare_guide.pdf', 'product_recommendations.pdf'],
    ),
    const ServiceTask(
      id: 'meditation_session',
      serviceId: 'spiritual_guidance',
      title: 'Morning Meditation (15 min)',
      description: 'Practice the guided meditation for inner peace and clarity',
      priority: TaskPriority.medium,
      resources: ['meditation_audio.mp3'],
    ),
    const ServiceTask(
      id: 'budget_review',
      serviceId: 'financial_planning',
      title: 'Review Wedding Budget Draft',
      description:
          'Go through the preliminary budget breakdown and make adjustments',
      priority: TaskPriority.high,
      resources: ['budget_template.xlsx'],
    ),
  ];

  static PremiumService? getServiceById(String id) {
    try {
      return services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<PremiumService> getActiveServices() {
    return services.where((service) => service.isActive).toList();
  }

  static int getTotalCompletedTasks() {
    return services.fold(0, (sum, service) => sum + service.completedTasks);
  }

  static int getTotalTasks() {
    return services.fold(0, (sum, service) => sum + service.totalTasks);
  }

  static double getOverallProgress() {
    final totalTasks = getTotalTasks();
    final completedTasks = getTotalCompletedTasks();
    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }
}
