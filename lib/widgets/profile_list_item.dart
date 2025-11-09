import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileListItem extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const ProfileListItem({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rectangular profile photo for better visibility
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          (profile.photos.isEmpty ||
                              profile.photos.first.isEmpty)
                          ? _getAvatarColor(profile.name)
                          : AppTheme.whatsAppGray,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(profile.name),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // New profile indicator
                  if (profile.isNew)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.statusGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Profile information - More detailed and organized
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and Age
                              Text(
                                profile.displayName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Profession
                              Text(
                                profile.profession,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.sacredSaffron,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Time and status indicator
                        SizedBox(
                          width: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(profile.createdAt),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppTheme.lightTextColor),
                              ),
                              if (profile.status != ProfileStatus.pending) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(profile.status),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(profile.status),
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Detailed information in organized rows
                    _buildInfoRow(
                      context,
                      Icons.school,
                      'Education',
                      profile.education,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      context,
                      Icons.location_city,
                      'Location',
                      profile.city +
                          (profile.community.isNotEmpty
                              ? ' • ${profile.community}'
                              : ''),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      context,
                      Icons.height,
                      'Height',
                      profile.height,
                    ),

                    const SizedBox(height: 8),

                    // Status message if not pending
                    if (profile.status != ProfileStatus.pending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            profile.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getStatusColor(
                              profile.status,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(profile.status),
                              size: 14,
                              color: _getStatusColor(profile.status),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                profile.status.actionLabel.isNotEmpty
                                    ? profile.status.actionLabel
                                    : profile.status.displayName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _getStatusColor(profile.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryTextColor),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ProfileStatus status) {
    switch (status) {
      case ProfileStatus.interested:
      case ProfileStatus.mutualInterest:
        return AppTheme.statusGreen;
      case ProfileStatus.notMatch:
        return AppTheme.statusRed;
      case ProfileStatus.saved:
      case ProfileStatus.awaitingResponse:
        return AppTheme.statusAmber;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  IconData _getStatusIcon(ProfileStatus status) {
    switch (status) {
      case ProfileStatus.interested:
        return Icons.favorite;
      case ProfileStatus.notMatch:
        return Icons.close;
      case ProfileStatus.saved:
        return Icons.star;
      case ProfileStatus.mutualInterest:
        return Icons.favorite;
      case ProfileStatus.awaitingResponse:
        return Icons.schedule;
      default:
        return Icons.circle;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'UN';
  }

  Color _getAvatarColor(String name) {
    // Generate a color based on the name for consistent avatar colors
    final colors = [
      AppTheme.sacredSaffron,
      AppTheme.deepMaroon,
      const Color(0xFF7B68EE), // Medium Slate Blue
      const Color(0xFF20B2AA), // Light Sea Green
      const Color(0xFF8FBC8F), // Dark Sea Green
      const Color(0xFFCD853F), // Peru
      const Color(0xFF4682B4), // Steel Blue
      const Color(0xFF9370DB), // Medium Purple
      const Color(0xFF3CB371), // Medium Sea Green
      const Color(0xFFB8860B), // Dark Goldenrod
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
