import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/models/broker.dart';
import 'package:testing_flutter/screens/profile_detail_screen.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class ProfileMessageCard extends StatefulWidget {
  final Profile profile;
  final DateTime timestamp;
  final bool isSentByBroker;
  final Broker? broker;

  const ProfileMessageCard({
    super.key,
    required this.profile,
    required this.timestamp,
    required this.isSentByBroker,
    this.broker,
  });

  @override
  State<ProfileMessageCard> createState() => _ProfileMessageCardState();
}

class _ProfileMessageCardState extends State<ProfileMessageCard> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors for profile card
    final cardColor = widget.isSentByBroker
        ? (isDark ? const Color(0xFF1F2C34) : Colors.white)
        : (isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6));

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12).copyWith(
          bottomLeft: widget.isSentByBroker
              ? const Radius.circular(4)
              : const Radius.circular(12),
          bottomRight: widget.isSentByBroker
              ? const Radius.circular(12)
              : const Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photos with page view
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.profile.photos.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openPhotoGallery(context, index),
                        child: CachedNetworkImage(
                          imageUrl: widget.profile.photos.isNotEmpty
                              ? widget.profile.photos[index]
                              : '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.whatsAppGray,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.whatsAppGray,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Photo counter overlay
                  if (widget.profile.photos.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPhotoIndex + 1}/${widget.profile.photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Page indicators
                  if (widget.profile.photos.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.profile.photos.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoIndex == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Profile info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                Text(
                  widget.profile.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.primaryTextColor,
                  ),
                ),

                const SizedBox(height: 2),

                // Profession
                Text(
                  widget.profile.profession,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Education and city
                Text(
                  widget.profile.snippet,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.lightTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Sent by broker info
                if (widget.broker != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sent by ${widget.broker!.displayName}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppTheme.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Personal Details section (compact)
                _buildPersonalDetailsSection(context),

                const SizedBox(height: 8),

                // View profile button
                InkWell(
                  onTap: () => _openProfile(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.sacredSaffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.sacredSaffron.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 16,
                          color: AppTheme.sacredSaffron,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Full Profile',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.sacredSaffron,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Quick action buttons - NEW!
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.favorite,
                        label: 'Interested',
                        color: AppColors.success,
                        onTap: () => _handleAction(context, 'interested'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.schedule,
                        label: 'Maybe',
                        color: AppColors.warning,
                        onTap: () => _handleAction(context, 'pending'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.close,
                        label: 'Pass',
                        color: AppColors.error,
                        onTap: () => _handleAction(context, 'not_match'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(widget.timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.lightTextColor,
                        fontSize: 11,
                      ),
                    ),
                    if (!widget.isSentByBroker) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection(BuildContext context) {
    final profile = widget.profile;
    final details = <MapEntry<String, String>>[
      MapEntry('Height', profile.height),
      MapEntry('Religion', profile.religion),
      MapEntry('Caste', profile.caste),
      MapEntry('Mother Tongue', profile.motherTongue),
      MapEntry('Marital Status', profile.maritalStatus),
    ].where((e) => e.value.trim().isNotEmpty).toList();

    if (details.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: isDark
          ? Colors.white.withValues(alpha: 0.8)
          : AppTheme.secondaryTextColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Details', style: titleStyle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: details.map((e) {
                return SizedBox(
                  width: itemWidth,
                  child: _buildDetailTile(context, e.key, e.value),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailTile(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: isDark
          ? Colors.white.withValues(alpha: 0.7)
          : AppTheme.lightTextColor,
    );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white : AppTheme.primaryTextColor,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.whatsAppGray.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          Text(
            value,
            style: valueStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    String message = '';
    Color bgColor = AppColors.success;

    switch (action) {
      case 'interested':
        message = 'Marked as Interested! Your broker will be notified.';
        bgColor = AppColors.success;
        break;
      case 'pending':
        message = 'Saved for later review.';
        bgColor = AppColors.warning;
        break;
      case 'not_match':
        message = 'Marked as Not Interested.';
        bgColor = AppColors.error;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              action == 'interested'
                  ? Icons.favorite
                  : action == 'pending'
                  ? Icons.schedule
                  : Icons.close,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Profile',
          textColor: Colors.white,
          onPressed: () => _openProfile(context),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: widget.profile,
          sentByBroker: widget.broker,
          onStatusChanged: (updatedProfile) {
            // Handle status change if needed
          },
        ),
      ),
    );
  }

  void _openPhotoGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: widget.profile,
          sentByBroker: widget.broker,
          onStatusChanged: (updatedProfile) {
            // Handle status change if needed
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }
}
