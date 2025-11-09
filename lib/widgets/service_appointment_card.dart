import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ServiceAppointmentCard extends StatelessWidget {
  final ServiceAppointment appointment;
  final Color primaryColor;

  const ServiceAppointmentCard({
    super.key,
    required this.appointment,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Date/Time section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(appointment.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd').format(appointment.dateTime),
                  style: TextStyle(
                    fontSize: 18,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(appointment.dateTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Appointment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${appointment.expertName} - ${appointment.expertRole}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      appointment.location == 'Online'
                          ? Icons.video_call
                          : Icons.location_on,
                      size: 16,
                      color: AppTheme.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        appointment.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextColor,
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

          // Action button
          ElevatedButton(
            onPressed: () {
              // TODO: Handle appointment action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              appointment.location == 'Online' ? 'Join' : 'Navigate',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
