import 'package:flutter/material.dart';

enum ServiceStatus { notStarted, inProgress, completed, scheduled }

enum ServiceType {
  beautyTransformation,
  healthWellness,
  culturalLearning,
  financialPlanning,
  spiritualGuidance,
}

class PremiumService {
  final String id;
  final String title;
  final String description;
  final ServiceType type;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final List<String> features;
  final ServiceStatus status;
  final double progress; // 0.0 to 1.0
  final int completedTasks;
  final int totalTasks;
  final DateTime? nextAppointment;
  final String? expertName;
  final bool isPremiumRequired;
  final double estimatedPrice;

  const PremiumService({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    required this.features,
    this.status = ServiceStatus.notStarted,
    this.progress = 0.0,
    this.completedTasks = 0,
    this.totalTasks = 1,
    this.nextAppointment,
    this.expertName,
    this.isPremiumRequired = true,
    this.estimatedPrice = 0.0,
  });

  String get statusText {
    switch (status) {
      case ServiceStatus.notStarted:
        return 'Get Started';
      case ServiceStatus.inProgress:
        return 'Continue';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.scheduled:
        return 'Scheduled';
    }
  }

  String get progressText {
    if (totalTasks > 1) {
      return '$completedTasks/$totalTasks tasks completed';
    } else {
      return '${(progress * 100).toInt()}% complete';
    }
  }

  bool get isActive =>
      status == ServiceStatus.inProgress || status == ServiceStatus.scheduled;

  PremiumService copyWith({
    ServiceStatus? status,
    double? progress,
    int? completedTasks,
    DateTime? nextAppointment,
    String? expertName,
  }) {
    return PremiumService(
      id: id,
      title: title,
      description: description,
      type: type,
      icon: icon,
      primaryColor: primaryColor,
      accentColor: accentColor,
      features: features,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      expertName: expertName ?? this.expertName,
      isPremiumRequired: isPremiumRequired,
      estimatedPrice: estimatedPrice,
    );
  }
}

class ServiceAppointment {
  final String id;
  final String serviceId;
  final String title;
  final DateTime dateTime;
  final String expertName;
  final String expertRole;
  final String location; // 'Online' or physical address
  final String description;
  final Duration estimatedDuration;
  final AppointmentStatus status;

  const ServiceAppointment({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.dateTime,
    required this.expertName,
    required this.expertRole,
    required this.location,
    required this.description,
    required this.estimatedDuration,
    this.status = AppointmentStatus.scheduled,
  });
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

class ServiceTask {
  final String id;
  final String serviceId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<String> resources; // URLs or file paths
  final String? completionNote;

  const ServiceTask({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.resources = const [],
    this.completionNote,
  });

  ServiceTask copyWith({bool? isCompleted, String? completionNote}) {
    return ServiceTask(
      id: id,
      serviceId: serviceId,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate,
      priority: priority,
      resources: resources,
      completionNote: completionNote ?? this.completionNote,
    );
  }
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityExtension on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}
