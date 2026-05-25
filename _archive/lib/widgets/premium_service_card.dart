import 'package:flutter/material.dart';
import 'package:testing_flutter/models/premium_service.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class PremiumServiceCard extends StatelessWidget {
  final PremiumService service;
  final VoidCallback onTap;

  const PremiumServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: service.primaryColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: service.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Container(
              height: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    service.primaryColor.withValues(alpha: 0.1),
                    service.accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: service.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      service.icon,
                      color: service.primaryColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (service.status != ServiceStatus.notStarted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(service.status, context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      service.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText(context),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText(context),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Progress or Price
                    if (service.status == ServiceStatus.notStarted) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 12,
                            color: AppTheme.tertiaryText(context),
                          ),
                          Flexible(
                            child: Text(
                              '${service.estimatedPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Progress indicator
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.tertiaryText(context),
                                ),
                              ),
                              Text(
                                '${(service.progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: service.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: service.progress,
                              backgroundColor: service.accentColor.withValues(alpha: 
                                0.3,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                service.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceStatus status, BuildContext context) {
    switch (status) {
      case ServiceStatus.notStarted:
        return AppTheme.tertiaryText(context);
      case ServiceStatus.inProgress:
        return AppTheme.sacredSaffron;
      case ServiceStatus.completed:
        return AppTheme.statusGreen;
      case ServiceStatus.scheduled:
        return Colors.blue;
    }
  }
}
