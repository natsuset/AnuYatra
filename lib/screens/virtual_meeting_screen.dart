import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testing_flutter/models/virtual_meeting.dart';
import 'package:testing_flutter/data/revolutionary_features_data.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:intl/intl.dart';

class VirtualMeetingScreen extends StatefulWidget {
  const VirtualMeetingScreen({super.key});

  @override
  State<VirtualMeetingScreen> createState() => _VirtualMeetingScreenState();
}

class _VirtualMeetingScreenState extends State<VirtualMeetingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _tabController = TabController(length: 3, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetings = RevolutionaryFeaturesData.mockVirtualMeetings;
    final upcomingMeetings = meetings.where((m) => m.isUpcoming).toList();
    final completedMeetings = meetings
        .where((m) => m.status == MeetingStatus.completed)
        .toList();
    final meetingHistory = RevolutionaryFeaturesData.meetingHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED), // Purple
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Virtual Family Meets',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7C3AED), // Deep purple
                      Color(0xFF8B5CF6), // Bright purple
                      Color(0xFFA78BFA), // Light purple
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: 60,
                      right: -10,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Icon(
                          Icons.video_call,
                          color: Colors.white.withOpacity(0.15),
                          size: 80,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: -20,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Icon(
                          Icons.family_restroom,
                          color: Colors.white.withOpacity(0.1),
                          size: 60,
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 60,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '🎥 Meet Before Meeting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${meetingHistory['averageRating']}/5 Rating',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: AppTheme.secondaryTextColor,
                indicatorColor: const Color(0xFF7C3AED),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'History'),
                  Tab(text: 'Templates'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Meetings Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Meeting Stats
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildMeetingStatsCard(meetingHistory),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Upcoming meetings
                      if (upcomingMeetings.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildSectionHeader(
                          'Scheduled Meetings',
                          Icons.schedule_outlined,
                          '${upcomingMeetings.length} upcoming sessions',
                        ),
                        const SizedBox(height: 16),
                        ...upcomingMeetings.map(
                          (meeting) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMeetingCard(meeting),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Quick Schedule
                      _buildSectionHeader(
                        'Quick Schedule',
                        Icons.add_circle_outline,
                        'Start a new meeting instantly',
                      ),
                      const SizedBox(height: 16),
                      _buildQuickScheduleCards(),
                    ],
                  ),
                ),

                // History Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (completedMeetings.isEmpty)
                        _buildEmptyHistoryState()
                      else ...[
                        _buildSectionHeader(
                          'Completed Meetings',
                          Icons.history,
                          '${completedMeetings.length} successful sessions',
                        ),
                        const SizedBox(height: 16),
                        ...completedMeetings.map(
                          (meeting) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildHistoryMeetingCard(meeting),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Templates Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSectionHeader(
                        'Meeting Templates',
                        Icons.view_list_outlined,
                        'Choose from structured meeting formats',
                      ),
                      const SizedBox(height: 16),
                      _buildMeetingTemplates(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.secondaryTextColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeetingStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Your Meeting Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Meetings',
                  '${stats['totalMeetings']}',
                  Icons.video_call,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${stats['successRate']}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  '${stats['averageRating']}/5',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7C3AED),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(VirtualMeeting meeting) {
    final families = <String, List<MeetingParticipant>>{};
    for (final participant in meeting.participants) {
      families.putIfAbsent(participant.familyName, () => []).add(participant);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meeting.typeEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('MMM dd, yyyy').format(meeting.scheduledTime)} • ${DateFormat('h:mm a').format(meeting.scheduledTime)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meeting.isToday
                      ? Colors.green.withOpacity(0.1)
                      : const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  meeting.isToday ? 'Today' : '${meeting.durationMinutes} min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: meeting.isToday
                        ? Colors.green
                        : const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Participants
          Text(
            'Participants (${meeting.participants.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            children: families.entries.map((family) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${family.key} (${family.value.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rescheduleMeeting(meeting),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _joinMeeting(meeting),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Join Meeting',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMeetingCard(VirtualMeeting meeting) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(meeting.typeEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meeting.typeDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ),
              if (meeting.feedback != null) ...[
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: index < meeting.feedback!.overallRating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    );
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy • h:mm a').format(meeting.scheduledTime),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          if (meeting.feedback?.privateNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              meeting.feedback!.privateNotes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryTextColor,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickScheduleCards() {
    final templates = [
      {
        'type': MeetingType.firstIntroduction,
        'title': 'First Introduction',
        'emoji': '👋',
        'duration': 30,
        'description': 'Basic introductions and compatibility check',
      },
      {
        'type': MeetingType.culturalExchange,
        'title': 'Cultural Exchange',
        'emoji': '🌍',
        'duration': 60,
        'description': 'Share traditions and cultural values',
      },
      {
        'type': MeetingType.virtualDinner,
        'title': 'Virtual Dinner',
        'emoji': '🍽️',
        'duration': 90,
        'description': 'Informal family bonding over meal',
      },
    ];

    return Column(
      children: templates.map((template) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _scheduleQuickMeeting(template['type'] as MeetingType),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          template['description'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${template['duration']} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF7C3AED),
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeetingTemplates() {
    return Column(
      children: [
        _buildTemplateCard(
          'First Introduction',
          '30 minutes',
          '👋',
          'Family introductions and basic compatibility',
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Values Discussion',
          '45 minutes',
          '💭',
          'Religious practices and family values',
          const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Cultural Exchange',
          '60 minutes',
          '🌍',
          'Regional customs and tradition sharing',
          const Color(0xFFf59e0b),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Future Planning',
          '45 minutes',
          '🔮',
          'Career goals and life planning discussion',
          const Color(0xFFEC4899),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Virtual Dinner',
          '90 minutes',
          '🍽️',
          'Extended family participation and bonding',
          const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    String title,
    String duration,
    String emoji,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      duration,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.video_call_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Upcoming Meetings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedule your first virtual family meet to start building connections',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _scheduleFirstMeeting(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Schedule Meeting',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Meeting History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed meetings will appear here with ratings and feedback',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  void _joinMeeting(VirtualMeeting meeting) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Joining meeting...'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  void _rescheduleMeeting(VirtualMeeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Meeting'),
        content: const Text('Choose a new time for your virtual family meet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  void _scheduleQuickMeeting(MeetingType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule ${_getMeetingTypeTitle(type)}'),
        content: const Text(
          'Choose a time and invite families for this meeting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _scheduleFirstMeeting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening meeting scheduler...'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  String _getMeetingTypeTitle(MeetingType type) {
    switch (type) {
      case MeetingType.firstIntroduction:
        return 'First Introduction';
      case MeetingType.valuesDiscussion:
        return 'Values Discussion';
      case MeetingType.culturalExchange:
        return 'Cultural Exchange';
      case MeetingType.futurePlanning:
        return 'Future Planning';
      case MeetingType.virtualDinner:
        return 'Virtual Dinner';
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF8F6F3), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
