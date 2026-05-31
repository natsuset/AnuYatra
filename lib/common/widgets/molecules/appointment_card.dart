import 'package:flutter/material.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/theme/app_theme.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:intl/intl.dart';

/// Compact card that summarises a [ServiceAppointment].
///
/// Layout: date column on the left, title + expert + location in the middle,
/// and a "Join" (for online appointments) or "Go" (for in-person) action button
/// on the right. The card has no built-in navigation — the caller passes
/// [onAction] to decide what tapping the button does.
class AppointmentCard extends StatelessWidget {
  final ServiceAppointment appointment;

  /// Invoked when the user taps the right-hand action button.
  /// When `null`, the button is disabled.
  final VoidCallback? onAction;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isOnline = appointment.location.toLowerCase() == 'online';

    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface(context),
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
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
            padding: AppSpacing.allSm,
            decoration: BoxDecoration(
              color: AppTheme.sacredSaffron.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSm,
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

          AppSpacing.gapW12,

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
                      isOnline ? Icons.video_call : Icons.location_on,
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

          // Action button (caller decides what tapping it does).
          SizedBox(
            width: 56,
            height: 32,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sacredSaffron,
                disabledBackgroundColor:
                    AppTheme.sacredSaffron.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedSm,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              ),
              child: Text(
                isOnline ? 'Join' : 'Go',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
