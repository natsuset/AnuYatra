import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_provider.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/constants/app_colors.dart';
import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/constants/app_strings.dart';

/// 6-digit OTP verification screen.
/// Code "123456" always works (mock).
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _verifyOtp() {
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.invalidOtpError)),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is AuthOtpSent) {
      ref.read(authProvider.notifier).verifyOtp(
        phoneNumber: authState.phoneNumber,
        otpCode: code,
        selectedRole: authState.selectedRole,
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    String phoneNumber = '';
    if (authState is AuthOtpSent) {
      phoneNumber = authState.phoneNumber;
    }

    // Show error if any
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).goBackToInitial();
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
                AppStrings.verifyNumber,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                AppStrings.otpSentTo(phoneNumber),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),

              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedMd,
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedMd,
                          borderSide: BorderSide(
                            color: AppColors.sacredSaffron,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  );
                }),
              ),

              AppSpacing.gapH32,

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _verifyOtp,
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
                          AppStrings.verifyAndContinue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              AppSpacing.gapH24,

              // Resend code
              Center(
                child: TextButton(
                  onPressed: () {
                    // In demo mode, just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo: OTP code is always 123456')),
                    );
                  },
                  child: Text(
                    AppStrings.resendCode,
                    style: TextStyle(
                      color: AppColors.sacredSaffron,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Hint
              Container(
                margin: EdgeInsets.only(bottom: AppSpacing.lg),
                padding: AppSpacing.allSm,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: AppColors.success),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Text(
                        AppStrings.otpHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
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
