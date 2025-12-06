import 'package:flutter/material.dart';
import 'package:testing_flutter/screens/home_screen.dart';
import 'package:testing_flutter/screens/shortlist_screen.dart';
import 'package:testing_flutter/screens/brokers_list_screen.dart';
import 'package:testing_flutter/screens/vivaha_samskara_home_screen.dart';
import 'package:testing_flutter/screens/trust_verification_screen.dart';
import 'package:testing_flutter/screens/financial_compatibility_screen.dart';
import 'package:testing_flutter/screens/virtual_meeting_screen.dart';
import 'package:testing_flutter/theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Build screens in build() to safely access Theme.of(context)

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.star_border,
      activeIcon: Icons.star,
      label: 'Shortlist',
    ),
    NavigationItem(
      icon: Icons.phone_outlined,
      activeIcon: Icons.phone,
      label: 'Broker',
    ),
    NavigationItem(
      icon: Icons.diamond_outlined,
      activeIcon: Icons.diamond,
      label: 'Premium',
    ),
    NavigationItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Features',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreen(),
      ShortlistScreen(onNavigateToHome: () => _navigateToTab(0)),
      const BrokersListScreen(),
      const VivahaSamskaraHomeScreen(),
      _buildRevolutionaryFeaturesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildPremiumNavigationBar(),
    );
  }

  Widget _buildPremiumNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.sacredSaffron.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        transform: Matrix4.identity()
                          ..scale(isSelected ? 1.1 : 1.0),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppTheme.sacredSaffron
                              : AppTheme.secondaryTextColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.sacredSaffron
                              : AppTheme.secondaryTextColor,
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.2,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRevolutionaryFeaturesScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Revolutionary Features',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.sacredSaffron.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.15
                          : 0.1,
                    ),
                    AppTheme.deepMaroon.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.15
                          : 0.1,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.sacredSaffron.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.sacredSaffron, AppTheme.deepMaroon],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game-Changing Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Revolutionary tools for modern matrimony',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Revolutionary Features
            _buildRevolutionaryFeatureCard(
              'Trust & Verification',
              'Community verified profiles with 95% accuracy',
              Icons.verified_user,
              const Color(0xFF1A4B84),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrustVerificationScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildRevolutionaryFeatureCard(
              'Financial Compatibility',
              'Transparent financial planning and budget tools',
              Icons.account_balance_wallet,
              const Color(0xFF059669),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialCompatibilityScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildRevolutionaryFeatureCard(
              'Virtual Family Meets',
              'Meet families from anywhere with AI assistance',
              Icons.video_call,
              const Color(0xFF7C3AED),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VirtualMeetingScreen(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Coming Soon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.04,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.upcoming,
                        color: AppTheme.secondaryTextColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildComingSoonItem(
                    '🤖',
                    'AI Rishta Advisor',
                    'Personal marriage consultant with 85% success prediction',
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonItem(
                    '🎬',
                    'Video Rishta Stories',
                    'Real success stories from similar families',
                  ),
                  const SizedBox(height: 12),
                  _buildComingSoonItem(
                    '📱',
                    'WhatsApp Integration',
                    'Updates for parents via WhatsApp',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevolutionaryFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonItem(String emoji, String title, String description) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
