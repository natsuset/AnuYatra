import 'package:flutter/material.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class ServiceFeatureCard extends StatelessWidget {
  final String feature;
  final Color primaryColor;
  final bool isCompleted;

  const ServiceFeatureCard({
    super.key,
    required this.feature,
    required this.primaryColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? primaryColor : Colors.grey.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? primaryColor : AppTheme.tertiaryText(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted ? primaryColor : AppTheme.primaryText(context),
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
