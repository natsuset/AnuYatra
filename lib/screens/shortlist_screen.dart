import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/screens/profile_detail_screen.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/data/mock_data.dart';

class ShortlistScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;

  const ShortlistScreen({super.key, this.onNavigateToHome});

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  List<Profile> shortlistedProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadShortlistedProfiles();
  }

  void _loadShortlistedProfiles() {
    // Filter profiles that are saved, interested, or have mutual interest
    shortlistedProfiles = MockData.profiles.where((profile) {
      return profile.status == ProfileStatus.saved ||
          profile.status == ProfileStatus.interested ||
          profile.status == ProfileStatus.mutualInterest ||
          profile.status == ProfileStatus.awaitingResponse;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme-driven scaffold background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // AppBar colors come from global theme
        title: const Text('Your Shortlist'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'sort', child: Text('Sort by')),
              const PopupMenuItem(value: 'filter', child: Text('Filter')),
              const PopupMenuItem(value: 'export', child: Text('Export list')),
            ],
            onSelected: (value) {
              // TODO: Implement menu actions
            },
          ),
        ],
      ),
      body: shortlistedProfiles.isEmpty
          ? _buildEmptyState()
          : _buildProfileGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: AppTheme.lightTextColor),
          const SizedBox(height: 16),
          Text(
            'No profiles in shortlist',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profiles you save or show interest in will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onNavigateToHome?.call();
            },
            child: const Text('Browse Profiles'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: shortlistedProfiles.length,
        itemBuilder: (context, index) {
          final profile = shortlistedProfiles[index];
          return _ShortlistCard(
            profile: profile,
            onTap: () => _navigateToProfile(profile),
          );
        },
      ),
    );
  }

  void _navigateToProfile(Profile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: profile,
          onStatusChanged: (updatedProfile) {
            setState(() {
              final index = shortlistedProfiles.indexWhere(
                (p) => p.id == updatedProfile.id,
              );
              if (index != -1) {
                // Update if still shortlisted, remove if not
                if (updatedProfile.status == ProfileStatus.saved ||
                    updatedProfile.status == ProfileStatus.interested ||
                    updatedProfile.status == ProfileStatus.mutualInterest ||
                    updatedProfile.status == ProfileStatus.awaitingResponse) {
                  shortlistedProfiles[index] = updatedProfile;
                } else {
                  shortlistedProfiles.removeAt(index);
                }
              }
            });
          },
        ),
      ),
    );
  }
}

class _ShortlistCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ShortlistCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: profile.photos.isNotEmpty
                      ? profile.photos.first
                      : '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.whatsAppGray,
                    child: const Center(child: CircularProgressIndicator()),
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
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Profession
                  Text(
                    profile.profession,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // City
                  Text(
                    profile.city,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(profile.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(profile.status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(profile.status),
                          size: 12,
                          color: _getStatusColor(profile.status),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            profile.status.displayName,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: _getStatusColor(profile.status),
                                  fontWeight: FontWeight.w500,
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
    );
  }

  Color _getStatusColor(ProfileStatus status) {
    switch (status) {
      case ProfileStatus.interested:
      case ProfileStatus.mutualInterest:
        return AppTheme.statusGreen;
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
}
