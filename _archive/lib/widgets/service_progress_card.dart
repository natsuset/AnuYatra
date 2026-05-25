import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class ServiceProgressCard extends StatelessWidget {
  final PremiumService service;

  const ServiceProgressCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: service.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: service.accentColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width:
                    MediaQuery.of(context).size.width * 0.8 * service.progress,
                decoration: BoxDecoration(
                  color: service.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service.progressText,
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 14,
                ),
              ),
              Text(
                '${(service.progress * 100).toInt()}%',
                style: TextStyle(
                  color: service.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (service.nextAppointment != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: service.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next appointment: ${service.nextAppointment.toString().split(' ')[0]}',
                    style: TextStyle(
                      color: service.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
