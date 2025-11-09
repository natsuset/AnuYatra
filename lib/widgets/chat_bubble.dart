import 'package:flutter/material.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSentByUser;
  final DateTime timestamp;
  final bool isProfileDetails;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSentByUser,
    required this.timestamp,
    this.isProfileDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // WhatsApp-like bubble colors
    final bubbleColor = isSentByUser
        ? (isDark
              ? const Color(0xFF005C4B) // Dark mode sent message
              : const Color(
                  0xFFDCF8C6,
                )) // Light mode sent message (WhatsApp green)
        : (isDark
              ? const Color(0xFF1F2C34) // Dark mode received message
              : Colors.white); // Light mode received message

    final textColor = isDark
        ? Colors.white
        : (isSentByUser ? Colors.black87 : AppColors.lightPrimaryText);

    return Column(
      crossAxisAlignment: isSentByUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomLeft: isSentByUser
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: isSentByUser
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isProfileDetails)
                _buildFormattedProfileText(context)
              else
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : (isSentByUser
                                ? Colors.black.withValues(alpha: 0.6)
                                : AppTheme.lightTextColor),
                      fontSize: 11,
                    ),
                  ),
                  if (isSentByUser) ...[
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
    );
  }

  Widget _buildFormattedProfileText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : AppColors.lightPrimaryText;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.lightSecondaryText;
    final accentColor = isDark ? AppColors.sacredSaffron : AppTheme.deepMaroon;

    final lines = message.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: 4);
        }

        // Check if line starts with emoji (indicating a category)
        final isCategory = line.startsWith(RegExp(r'[👤📏💼🎓📍👨‍👩‍👧‍👦]'));
        final isFamilyHeader = line == '👨‍👩‍👧‍👦 Family:';

        if (isCategory && !isFamilyHeader) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.3,
              ),
            ),
          );
        } else if (isFamilyHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accentColor,
                height: 1.3,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 16),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: 1.3,
              ),
            ),
          );
        }
      }).toList(),
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
