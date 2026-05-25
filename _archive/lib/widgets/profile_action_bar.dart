import 'package:flutter/material.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class ProfileActionBar extends StatelessWidget {
  final ProfileStatus currentStatus;
  final Function(ProfileStatus) onActionPressed;

  const ProfileActionBar({
    super.key,
    required this.currentStatus,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: currentStatus == ProfileStatus.pending
              ? _buildActionButtons()
              : _buildStatusMessage(context),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Interested button
        Expanded(
          child: _ActionButton(
            icon: Icons.favorite,
            label: 'Interested',
            backgroundColor: AppTheme.statusGreen,
            onPressed: () => onActionPressed(ProfileStatus.interested),
          ),
        ),

        const SizedBox(width: 12),

        // Not a Match button
        Expanded(
          child: _ActionButton(
            icon: Icons.close,
            label: 'Not a Match',
            backgroundColor: AppTheme.statusRed,
            onPressed: () => onActionPressed(ProfileStatus.notMatch),
          ),
        ),

        const SizedBox(width: 12),

        // Save button
        Expanded(
          child: _ActionButton(
            icon: Icons.star,
            label: 'Save',
            backgroundColor: AppTheme.statusAmber,
            onPressed: () => onActionPressed(ProfileStatus.saved),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    IconData icon;
    Color color;
    String message;

    switch (currentStatus) {
      case ProfileStatus.interested:
        icon = Icons.favorite;
        color = AppTheme.statusGreen;
        message = 'You showed interest in this profile';
        break;
      case ProfileStatus.notMatch:
        icon = Icons.close;
        color = AppTheme.statusRed;
        message = 'You marked this as not a match';
        break;
      case ProfileStatus.saved:
        icon = Icons.star;
        color = AppTheme.statusAmber;
        message = 'You saved this profile for later';
        break;
      case ProfileStatus.mutualInterest:
        icon = Icons.favorite;
        color = AppTheme.statusGreen;
        message = 'Mutual interest! Contact your broker for next steps';
        break;
      case ProfileStatus.awaitingResponse:
        icon = Icons.schedule;
        color = AppTheme.statusAmber;
        message = 'Awaiting response from their family';
        break;
      default:
        icon = Icons.info;
        color = AppTheme.secondaryText(context);
        message = 'Profile status updated';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (currentStatus == ProfileStatus.mutualInterest ||
              currentStatus == ProfileStatus.awaitingResponse)
            TextButton(
              onPressed: () {
                // TODO: Navigate to broker chat
              },
              child: const Text('Contact Broker'),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
