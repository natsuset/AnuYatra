import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  final ServiceAppointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.sacredSaffron.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Date/Time section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sacredSaffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(appointment.dateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.sacredSaffron,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd').format(appointment.dateTime),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.sacredSaffron,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(appointment.dateTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Appointment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appointment.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText(context),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: AppTheme.tertiaryText(context),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${appointment.expertName} - ${appointment.expertRole}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText(context),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      appointment.location == 'Online'
                          ? Icons.video_call
                          : Icons.location_on,
                      size: 14,
                      color: AppTheme.tertiaryText(context),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        appointment.location,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.tertiaryText(context),
                          height: 1.2,
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
          SizedBox(
            width: 56,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Join/Navigate to appointment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sacredSaffron,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                appointment.location == 'Online' ? 'Join' : 'Go',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
