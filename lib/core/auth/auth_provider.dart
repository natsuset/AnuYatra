import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/data/repositories/auth_repository.dart';
import 'package:testing_flutter/core/data/repositories/user_repository.dart';
import 'package:testing_flutter/core/data/repositories/profile_repository.dart';
import 'package:testing_flutter/core/data/repositories/agency_repository.dart';
import 'package:testing_flutter/core/data/repositories/broker_repository.dart';
import 'package:testing_flutter/core/providers/repository_providers.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

/// Indian mobile number: starts with 6-9, followed by 9 digits.
final _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

/// Auth notifier that manages login/logout via repository interfaces.
///
/// Uses [AuthRepository] for OTP verification, [UserRepository] for
/// user CRUD/session, and role-specific repositories for profile setup.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ProfileRepository _profileRepo;
  final AgencyRepository _agencyRepo;
  final BrokerRepository _brokerRepo;

  AuthNotifier({
    required AuthRepository authRepo,
    required UserRepository userRepo,
    required ProfileRepository profileRepo,
    required AgencyRepository agencyRepo,
    required BrokerRepository brokerRepo,
  })  : _authRepo = authRepo,
        _userRepo = userRepo,
        _profileRepo = profileRepo,
        _agencyRepo = agencyRepo,
        _brokerRepo = brokerRepo,
        super(const AuthInitial());

  /// Check if user is already logged in (on app start)
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();

    try {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user: user);
      } else {
        state = const AuthInitial();
      }
    } catch (e) {
      state = const AuthInitial();
    }
  }

  /// Validate an Indian mobile number (10 digits, starting with 6-9).
  /// Accepts both raw (`9876543210`) and prefixed (`+919876543210`) formats.
  static bool isValidIndianPhone(String phone) {
    final digits = phone.replaceFirst('+91', '');
    return _indianPhoneRegex.hasMatch(digits);
  }

  /// Step 1: User selects role and enters phone → send OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required UserRole selectedRole,
  }) async {
    if (!isValidIndianPhone(phoneNumber)) {
      state = const AuthError(
        errorType: AuthErrorType.invalidPhone,
        previousState: AuthInitial(),
      );
      return;
    }

    state = const AuthLoading();

    try {
      await _authRepo.sendOtp(
        phoneNumber: phoneNumber,
        selectedRole: selectedRole,
      );

      state = AuthOtpSent(
        phoneNumber: phoneNumber,
        selectedRole: selectedRole,
      );
    } catch (e) {
      debugPrint('sendOtp failed: $e');
      state = AuthError(
        errorType: AuthErrorType.sendOtpFailed,
        previousState: const AuthInitial(),
      );
    }
  }

  /// Step 2: Verify OTP code
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required UserRole selectedRole,
  }) async {
    state = const AuthLoading();

    try {
      final isValid = await _authRepo.verifyOtp(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );

      if (!isValid) {
        final hint = _authRepo.demoOtpCode;
        state = AuthError(
          errorType: hint != null
              ? AuthErrorType.invalidOtpWithHint
              : AuthErrorType.invalidOtp,
          detail: hint,
          previousState: AuthOtpSent(
            phoneNumber: phoneNumber,
            selectedRole: selectedRole,
          ),
        );
        return;
      }

      final existingUser = await _userRepo.getUserByPhone(phoneNumber);

      if (existingUser != null) {
        await _userRepo.setCurrentUser(existingUser.uid);
        state = AuthAuthenticated(user: existingUser);
      } else {
        final user = await _userRepo.registerUser(
          phoneNumber: phoneNumber,
          displayName: '',
          role: selectedRole,
        );
        state = AuthNeedsProfile(
          uid: user.uid,
          phoneNumber: phoneNumber,
          role: selectedRole,
        );
      }
    } catch (e) {
      debugPrint('verifyOtp failed: $e');
      state = AuthError(
        errorType: AuthErrorType.verificationFailed,
        previousState: AuthOtpSent(
          phoneNumber: phoneNumber,
          selectedRole: selectedRole,
        ),
      );
    }
  }

  /// Step 3: Complete profile setup (for new users)
  Future<void> completeProfileSetup({
    required String uid,
    required String displayName,
    required UserRole role,
    // Agency-specific
    String? agencyName,
    String? agencyCity,
    String? agencyState,
    String? agencyDescription,
    List<String>? agencySpecializations,
    // Broker-specific
    String? brokerBio,
    List<String>? brokerSpecializations,
    List<String>? brokerAreasServed,
    int? brokerExperienceYears,
    // Parent-specific
    String? lookingFor, // 'bride' or 'groom'
    String? parentCity,
    String? parentState,
    // Candidate-specific (minimal at setup)
    int? candidateAge,
    String? candidateGender,
  }) async {
    state = const AuthLoading();

    try {
      // Update the user's display name
      final user = await _userRepo.getUser(uid);
      if (user == null) throw Exception('User not found');

      final updatedUser = user.copyWith(displayName: displayName);
      await _userRepo.saveUser(updatedUser);

      // Create role-specific profile
      switch (role) {
        case UserRole.agencyAdmin:
          final agency = await _agencyRepo.createAgency(
            adminUserId: uid,
            name: agencyName ?? '$displayName\'s Agency',
            city: agencyCity ?? '',
            state: agencyState ?? '',
            description: agencyDescription ?? '',
            specializations: agencySpecializations ?? [],
          );
          await _userRepo.saveUser(
              updatedUser.copyWith(agencyId: agency.id));
          break;

        case UserRole.broker:
          await _brokerRepo.saveBrokerProfile(BrokerProfile(
            userId: uid,
            name: displayName,
            phoneNumber: user.phoneNumber,
            bio: brokerBio ?? '',
            specializations: brokerSpecializations ?? [],
            areasServed: brokerAreasServed ?? [],
            experienceYears: brokerExperienceYears ?? 0,
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          ));
          break;

        case UserRole.parent:
          final looking = lookingFor == 'groom'
              ? LookingFor.groom
              : LookingFor.bride;
          await _profileRepo.saveParentProfile(ParentProfile(
            userId: uid,
            name: displayName,
            lookingFor: looking,
            city: parentCity ?? '',
            state: parentState ?? '',
            createdAt: DateTime.now(),
          ));
          break;

        case UserRole.candidate:
          break;
      }

      // Log the user in
      final finalUser = (await _userRepo.getUser(uid))!;
      await _userRepo.setCurrentUser(uid);
      state = AuthAuthenticated(user: finalUser);
    } catch (e) {
      state = AuthError(
        errorType: AuthErrorType.profileSetupFailed,
        detail: e.toString(),
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _userRepo.clearSession();
    state = const AuthInitial();
  }

  /// Switch account (logout and go to login)
  Future<void> switchAccount() async {
    await logout();
  }

  /// Go back from OTP screen to initial
  void goBackToInitial() {
    state = const AuthInitial();
  }

  /// Clear error and go back to previous state
  void clearError() {
    if (state is AuthError) {
      final errorState = state as AuthError;
      state = errorState.previousState ?? const AuthInitial();
    }
  }
}

/// Riverpod provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepo: ref.watch(authRepositoryProvider),
    userRepo: ref.watch(userRepositoryProvider),
    profileRepo: ref.watch(profileRepositoryProvider),
    agencyRepo: ref.watch(agencyRepositoryProvider),
    brokerRepo: ref.watch(brokerRepositoryProvider),
  );
});
