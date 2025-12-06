import 'package:flutter/material.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/screens/profile_detail_screen.dart';
import 'package:testing_flutter/screens/brokers_list_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme-driven scaffold background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // AppBar colors come from global theme
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
          // Broker entry point (replaces single pinned broker)
          _buildBrokerPinnedChat(),

          // Divider
          Container(
            height: 8,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),

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
    final brokerCount = MockData.brokers.length;
    return Container(
      color:
          Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.sacredSaffron,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        title: Text(
          'Brokers',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$brokerCount chats',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.lightTextColor,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BrokersListScreen()),
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
                MaterialPageRoute(
                  builder: (context) => const BrokersListScreen(),
                ),
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
