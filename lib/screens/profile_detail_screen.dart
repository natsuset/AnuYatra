import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/models/profile.dart';
import 'package:testing_flutter/models/broker.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/theme/theme_extensions.dart';
import 'package:testing_flutter/widgets/chat_bubble.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final Function(Profile) onStatusChanged;
  final Broker? sentByBroker;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    required this.onStatusChanged,
    this.sentByBroker,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  late Profile currentProfile;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final PageController _photoPageController = PageController();
  final List<ProfileMessage> _messages = [];
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.profile;
    _initializeMessages();
  }

  void _initializeMessages() {
    // Initial broker introduction
    _messages.add(
      ProfileMessage(
        id: '1',
        type: ProfileMessageType.brokerIntro,
        content:
            'Here\'s a profile I think would be perfect for you. Take a look at the details below.',
        timestamp: currentProfile.createdAt,
        isSentByUser: false,
      ),
    );

    // Profile photos message
    if (currentProfile.photos.isNotEmpty) {
      _messages.add(
        ProfileMessage(
          id: '2',
          type: ProfileMessageType.profilePhoto,
          content: '', // Photos rendered separately
          timestamp: currentProfile.createdAt.add(const Duration(seconds: 30)),
          isSentByUser: false,
        ),
      );
    }

    // Profile details message
    _messages.add(
      ProfileMessage(
        id: '3',
        type: ProfileMessageType.profileDetails,
        content: _buildDetailedInfo(),
        timestamp: currentProfile.createdAt.add(const Duration(minutes: 1)),
        isSentByUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final chatBackgroundColor = isDark
        ? const Color(0xFF0B141A) // WhatsApp dark mode
        : const Color(0xFFECE5DD); // WhatsApp light mode

    return Scaffold(
      backgroundColor: chatBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.deepMaroon,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.whatsAppGray,
              backgroundImage: currentProfile.photos.isNotEmpty
                  ? CachedNetworkImageProvider(currentProfile.photos.first)
                  : null,
              child: currentProfile.photos.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal space',
                    style: Theme.of(
                      context,
                    ).appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Sent by ${widget.sentByBroker?.displayName ?? 'your broker'}',
                    style: Theme.of(context).appBarTheme.titleTextStyle
                        ?.copyWith(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showProfileMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // Message input area (always visible)
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ProfileMessage message) {
    // For profile photos and details, use wider layout but with proper constraints
    final bool isWideMessage =
        message.type == ProfileMessageType.profilePhoto ||
        message.type == ProfileMessageType.profileDetails;

    if (isWideMessage) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.whatsAppGray,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: _buildMessageContent(message),
              ),
            ),
            const SizedBox(width: 4), // Small padding on right
          ],
        ),
      );
    }

    // For regular messages, use the normal layout
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isSentByUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.whatsAppGray,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ] else
            const Spacer(),
          Flexible(child: _buildMessageContent(message)),
          if (message.isSentByUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.sacredSaffron,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ProfileMessage message) {
    switch (message.type) {
      case ProfileMessageType.brokerIntro:
        return ChatBubble(
          message: message.content,
          isSentByUser: false,
          timestamp: message.timestamp,
        );

      case ProfileMessageType.profilePhoto:
        return _buildProfilePhotos();

      case ProfileMessageType.profileDetails:
        return _buildProfileDetailsWithActions(message);

      case ProfileMessageType.userNote:
        return ChatBubble(
          message: message.content,
          isSentByUser: true,
          timestamp: message.timestamp,
        );

      case ProfileMessageType.statusUpdate:
        return _buildStatusUpdateMessage(message);

      default:
        return ChatBubble(
          message: message.content,
          isSentByUser: message.isSentByUser,
          timestamp: message.timestamp,
        );
    }
  }

  Widget _buildProfilePhotos() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _photoPageController,
                itemCount: currentProfile.photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openPhotoGallery(index),
                    child: CachedNetworkImage(
                      imageUrl: currentProfile.photos[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.whatsAppGray,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.whatsAppGray,
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Photo counter overlay
            if (currentProfile.photos.length > 1)
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
                    '${_currentPhotoIndex + 1}/${currentProfile.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // Page indicators
            if (currentProfile.photos.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    currentProfile.photos.length,
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
    );
  }

  Widget _buildProfileDetailsWithActions(ProfileMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
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
          // Sections - Personal Details
          _buildSectionTitle('Personal Details'),
          const SizedBox(height: 8),
          _buildDetailsGrid([
            MapEntry('Height', currentProfile.height),
            MapEntry('Religion', currentProfile.religion),
            MapEntry('Caste', currentProfile.caste),
            MapEntry('Mother Tongue', currentProfile.motherTongue),
            MapEntry('Marital Status', currentProfile.maritalStatus),
          ]),

          // About Me
          if (currentProfile.aboutMe.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('About Me'),
            const SizedBox(height: 6),
            _buildSectionParagraph(currentProfile.aboutMe),
          ],

          // Family Background
          if (_familySummary().trim().isNotEmpty ||
              currentProfile.familyBackground.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Family Background'),
            const SizedBox(height: 6),
            _buildSectionParagraph(
              currentProfile.familyBackground.trim().isNotEmpty
                  ? currentProfile.familyBackground
                  : _familySummary(),
            ),
          ],

          // Interests & Hobbies
          if (currentProfile.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Interests & Hobbies'),
            const SizedBox(height: 8),
            _buildSectionChips(currentProfile.interests),
          ],

          const SizedBox(height: 16),

          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.favorite,
                  label: 'Interested',
                  color: AppColors.success,
                  onTap: () => _handleQuickAction('interested'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.schedule,
                  label: 'Maybe',
                  color: AppColors.warning,
                  onTap: () => _handleQuickAction('pending'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.close,
                  label: 'Pass',
                  color: AppColors.error,
                  onTap: () => _handleQuickAction('not_match'),
                ),
              ),
            ],
          ),

          // Timestamp
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.lightSecondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: isDark ? Colors.white : AppColors.lightPrimaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDetailsGrid(List<MapEntry<String, String>> pairs) {
    final items = pairs
        .where((e) => e.value.trim().isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          children: items
              .map(
                (e) => SizedBox(
                  width: itemWidth,
                  child: _buildDetailTile(
                    context,
                    e.key,
                    e.value,
                  ), // reuse pattern
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDetailTile(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: isDark
          ? Colors.white.withValues(alpha: 0.7)
          : AppColors.lightTertiaryText,
    );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white : AppColors.lightPrimaryText,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24323A) : Colors.white,
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

  Widget _buildSectionParagraph(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white : AppColors.lightPrimaryText,
        height: 1.35,
      ),
    );
  }

  Widget _buildSectionChips(List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.lightBorder,
            ),
          ),
          child: Text(
            e,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white : AppColors.lightPrimaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _familySummary() {
    final parts = <String>[];
    if (currentProfile.fatherOccupation.isNotEmpty) {
      parts.add('Father: ${currentProfile.fatherOccupation}');
    }
    if (currentProfile.motherOccupation.isNotEmpty) {
      parts.add('Mother: ${currentProfile.motherOccupation}');
    }
    if (currentProfile.siblings.isNotEmpty) {
      parts.add('Siblings: ${currentProfile.siblings}');
    }
    return parts.join(' • ');
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoGallery(
          photos: currentProfile.photos,
          initialIndex: initialIndex,
          profileName: currentProfile.name,
        ),
      ),
    );
  }

  Widget _buildStatusUpdateMessage(ProfileMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3942) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white : AppColors.lightPrimaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDetailedInfo() {
    final details = StringBuffer();

    details.writeln('👤 ${currentProfile.displayName}');
    details.writeln('📏 Height: ${currentProfile.height}');
    details.writeln('💼 ${currentProfile.profession}');
    details.writeln('🎓 ${currentProfile.education}');
    details.writeln(
      '📍 ${currentProfile.city}${currentProfile.community.isNotEmpty ? ' • ${currentProfile.community}' : ''}',
    );

    if (currentProfile.fatherOccupation.isNotEmpty ||
        currentProfile.motherOccupation.isNotEmpty) {
      details.writeln('');
      details.writeln('👨‍👩‍👧‍👦 Family:');
      if (currentProfile.fatherOccupation.isNotEmpty) {
        details.writeln('Father: ${currentProfile.fatherOccupation}');
      }
      if (currentProfile.motherOccupation.isNotEmpty) {
        details.writeln('Mother: ${currentProfile.motherOccupation}');
      }
      if (currentProfile.siblings.isNotEmpty) {
        details.writeln('Siblings: ${currentProfile.siblings}');
      }
    }

    return details.toString().trim();
  }

  Widget _buildMessageInput(bool isDark) {
    final inputBackgroundColor = isDark
        ? const Color(0xFF1E2A32) // WhatsApp dark input background
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: inputBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Voice note button
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.sacredSaffron,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement voice note
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice note feature coming soon!'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightPrimaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note or question...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A3942)
                        : const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => _sendMessage(text),
                ),
              ),

              const SizedBox(width: 12),

              // Send button
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.sacredSaffron,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = ProfileMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ProfileMessageType.userNote,
      content: text.trim(),
      timestamp: DateTime.now(),
      isSentByUser: true,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate broker response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final response = ProfileMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ProfileMessageType.brokerResponse,
          content:
              'Thank you for your note. I\'ll get back to you shortly about this profile.',
          timestamp: DateTime.now(),
          isSentByUser: false,
        );

        setState(() {
          _messages.add(response);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _handleQuickAction(String action) {
    ProfileStatus status;
    String statusMessage = '';
    Color bgColor = AppColors.success;

    switch (action) {
      case 'interested':
        status = ProfileStatus.interested;
        statusMessage = '✅ Marked as Interested!';
        bgColor = AppColors.success;
        break;
      case 'pending':
        status = ProfileStatus.saved;
        statusMessage = '⏰ Saved for later review';
        bgColor = AppColors.warning;
        break;
      case 'not_match':
        status = ProfileStatus.notMatch;
        statusMessage = '❌ Marked as Not Interested';
        bgColor = AppColors.error;
        break;
      default:
        return;
    }

    // Update profile status
    setState(() {
      currentProfile = currentProfile.copyWith(status: status, isNew: false);
    });

    widget.onStatusChanged(currentProfile);

    // Add status update message to chat
    final statusUpdate = ProfileMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ProfileMessageType.statusUpdate,
      content: statusMessage,
      timestamp: DateTime.now(),
      isSentByUser: false,
    );

    setState(() {
      _messages.add(statusUpdate);
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Contact Broker'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to broker chat
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Full-screen photo gallery (WhatsApp-style)
class FullScreenPhotoGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String profileName;

  const FullScreenPhotoGallery({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.profileName,
  });

  @override
  State<FullScreenPhotoGallery> createState() => _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<FullScreenPhotoGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.profileName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '${_currentIndex + 1} of ${widget.photos.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'save') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save feature coming soon!')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'save', child: Text('Save to device')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 60),
                    ),
                  ),
                ),
              );
            },
          ),

          // Page indicators at bottom
          if (widget.photos.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Data classes for profile chat messages
enum ProfileMessageType {
  brokerIntro,
  profilePhoto,
  profileDetails,
  userNote,
  statusUpdate,
  brokerResponse,
}

class ProfileMessage {
  final String id;
  final ProfileMessageType type;
  final String content;
  final DateTime timestamp;
  final bool isSentByUser;

  ProfileMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.isSentByUser,
  });
}
