import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/models/broker.dart';
import 'package:testing_flutter/screens/profile_detail_screen.dart';
import 'package:testing_flutter/screens/broker_screen.dart';
import 'package:testing_flutter/screens/design_system_demo_screen.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/widgets/profile_list_item.dart';
import 'package:testing_flutter/data/mock_data.dart';
import 'package:testing_flutter/common/widgets/atoms/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Profile> profiles = MockData.profiles;
  Broker broker = MockData.broker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whatsAppGray.withOpacity(0.1),
      appBar: AppBar(
        backgroundColor: AppTheme.deepMaroon,
        title: Row(
          children: [
            // Agency logo placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Anuyātrā',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          // Theme toggle button
          const ThemeToggleButton(),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'design_demo',
                child: Text('Design System Demo'),
              ),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'help', child: Text('Help')),
            ],
            onSelected: (value) {
              if (value == 'design_demo') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DesignSystemDemoScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Broker pinned chat at top
          _buildBrokerPinnedChat(),

          // Divider
          Container(height: 8, color: AppTheme.whatsAppGray.withOpacity(0.3)),

          // Profile list
          Expanded(
            child: profiles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return ProfileListItem(
                        profile: profile,
                        onTap: () => _navigateToProfile(profile),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerPinnedChat() {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.whatsAppGray,
              backgroundImage: broker.profilePhoto.isNotEmpty
                  ? CachedNetworkImageProvider(broker.profilePhoto)
                  : null,
              child: broker.profilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                  : null,
            ),
            // Pin indicator
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.sacredSaffron,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.push_pin,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                broker.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Your Broker',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.sacredSaffron,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              broker.isOnline ? Icons.circle : Icons.schedule,
              size: 12,
              color: broker.isOnline
                  ? AppTheme.statusGreen
                  : AppTheme.secondaryTextColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                broker.statusText,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: AppTheme.statusGreen),
              onPressed: () {
                // TODO: Implement call functionality
              },
            ),
            const Icon(Icons.chevron_right, color: AppTheme.lightTextColor),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BrokerScreen()),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppTheme.lightTextColor),
          const SizedBox(height: 16),
          Text(
            'No profiles yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your broker will share profiles soon',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BrokerScreen()),
              );
            },
            child: const Text('Contact Your Broker'),
          ),
        ],
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
              final index = profiles.indexWhere(
                (p) => p.id == updatedProfile.id,
              );
              if (index != -1) {
                profiles[index] = updatedProfile;
              }
            });
          },
        ),
      ),
    );
  }
}
