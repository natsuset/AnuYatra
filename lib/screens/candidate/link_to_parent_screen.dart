import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/link_request.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Screen for candidates to link to their parent's account.
/// Enter parent's phone number → find parent → send link request.
class LinkToParentScreen extends ConsumerStatefulWidget {
  const LinkToParentScreen({super.key});

  @override
  ConsumerState<LinkToParentScreen> createState() => _LinkToParentScreenState();
}

class _LinkToParentScreenState extends ConsumerState<LinkToParentScreen> {
  final _phoneController = TextEditingController();
  String? _searchResult;
  String? _foundParentName;
  String? _foundParentId;
  bool _requestSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _searchParent() {
    final storage = ref.read(localStorageServiceProvider);
    final phone = '+91${_phoneController.text.trim()}';
    final user = storage.getUserByPhone(phone);

    setState(() {
      if (user != null && user.role == UserRole.parent) {
        _searchResult = 'found';
        _foundParentName = user.displayName;
        _foundParentId = user.uid;
      } else if (user != null) {
        _searchResult = 'not_parent';
        _foundParentName = null;
        _foundParentId = null;
      } else {
        _searchResult = 'not_found';
        _foundParentName = null;
        _foundParentId = null;
      }
    });
  }

  void _sendLinkRequest() async {
    final storage = ref.read(localStorageServiceProvider);
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated || _foundParentId == null) return;

    final user = authState.user;

    await storage.sendLinkRequest(
      fromUserId: user.uid,
      toUserId: _foundParentId!,
      fromUserName: user.displayName,
      toUserName: _foundParentName!,
      type: LinkRequestType.childToParent,
      note: 'I would like to link my account to yours.',
    );

    setState(() {
      _requestSent = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link request sent to $_foundParentName!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Link to Parent')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Link your account to your parent\'s account. They can share profiles with you and you\'ll both stay connected on your matchmaking journey.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Enter your parent\'s phone number',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Phone input
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          '+91',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '9800001001',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _searchParent,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredSaffron,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search result
          if (_searchResult == 'found' && _foundParentName != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.success.withValues(alpha: 0.2),
                        child: Icon(Icons.person, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundParentName!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Parent / Family',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _requestSent ? null : _sendLinkRequest,
                      icon: Icon(
                        _requestSent ? Icons.check : Icons.link,
                        color: Colors.white,
                      ),
                      label: Text(
                        _requestSent ? 'Request Sent!' : 'Send Link Request',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _requestSent
                            ? AppColors.success
                            : AppColors.sacredSaffron,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_searchResult == 'not_found')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_off, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No parent account found with this number. Ask your parent to create an account first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_searchResult == 'not_parent')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'An account exists with this number but it\'s not a parent account.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Demo hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demo: Try 9800001001 (Ramesh Kumar) or 9800001002 (Meera Nair)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
