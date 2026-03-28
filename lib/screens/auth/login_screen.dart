import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Phone number entry screen with +91 country code.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the selected role from the route extra
    final extra = GoRouterState.of(context).extra;
    if (extra is UserRole) {
      _selectedRole = extra;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    final role = _selectedRole ?? UserRole.parent;
    ref.read(authProvider.notifier).sendOtp(
      phoneNumber: '+91$phone',
      selectedRole: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).goBackToInitial();
            context.go('/role-selection');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.gapH16,

              Text(
                AppStrings.enterPhoneTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                AppStrings.enterPhoneSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapH8,

              if (_selectedRole != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sacredSaffron.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    AppStrings.registeringAs(_selectedRole!.displayName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.sacredSaffron,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              AppSpacing.gapH32,

              // Phone input
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: AppSpacing.borderRadiusMd,
                          bottomLeft: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      child: Text(
                        '+91',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: '9876543210',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapH24,

              // Send OTP button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _sendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredSaffron,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          AppStrings.sendOtp,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              // Demo hint
              Container(
                margin: EdgeInsets.only(bottom: AppSpacing.lg),
                padding: AppSpacing.allSm,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.info),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Text(
                        AppStrings.demoOtpHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          height: 1.4,
                        ),
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
}
