import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_flutter/core/auth/auth_state.dart';
import 'package:testing_flutter/core/services/local_storage_service.dart';
import 'package:testing_flutter/models/user_role.dart';
import 'package:testing_flutter/models/broker_profile.dart';
import 'package:testing_flutter/models/parent_profile.dart';

/// Mock OTP code that always works
const _mockOtpCode = '123456';

/// Auth notifier that manages login/logout via local Hive storage.
/// No real backend — phone + OTP "123456" always works.
class AuthNotifier extends StateNotifier<AuthState> {
  final LocalStorageService _storage;

  AuthNotifier(this._storage) : super(const AuthInitial());

  /// Check if user is already logged in (on app start)
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();

    final user = _storage.currentUser;
    if (user != null) {
      state = AuthAuthenticated(user: user);
    } else {
      state = const AuthInitial();
    }
  }

  /// Step 1: User selects role and enters phone → send OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required UserRole selectedRole,
  }) async {
    state = const AuthLoading();

    // Mock: simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Store the OTP (mock: always "123456")
    state = AuthOtpSent(
      phoneNumber: phoneNumber,
      selectedRole: selectedRole,
    );
  }

  /// Step 2: Verify OTP code
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required UserRole selectedRole,
  }) async {
    state = const AuthLoading();

    // Mock: simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock OTP verification
    if (otpCode != _mockOtpCode) {
      state = AuthError(
        message: 'Invalid OTP. Use "$_mockOtpCode" for demo.',
        previousState: AuthOtpSent(
          phoneNumber: phoneNumber,
          selectedRole: selectedRole,
        ),
      );
      return;
    }

    // Check if user already exists with this phone number
    final existingUser = _storage.getUserByPhone(phoneNumber);

    if (existingUser != null) {
      // Existing user → log them in
      await _storage.setCurrentUser(existingUser.uid);
      state = AuthAuthenticated(user: existingUser);
    } else {
      // New user → needs to complete profile
      // Pre-register with minimal info
      final user = await _storage.registerUser(
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
      final user = _storage.getUser(uid);
      if (user == null) throw Exception('User not found');

      final updatedUser = user.copyWith(displayName: displayName);
      await _storage.saveUser(updatedUser);

      // Create role-specific profile
      switch (role) {
        case UserRole.agencyAdmin:
          final agency = await _storage.createAgency(
            adminUserId: uid,
            name: agencyName ?? '$displayName\'s Agency',
            city: agencyCity ?? '',
            state: agencyState ?? '',
            description: agencyDescription ?? '',
            specializations: agencySpecializations ?? [],
          );
          await _storage.saveUser(updatedUser.copyWith(agencyId: agency.id));
          break;

        case UserRole.broker:
          await _storage.saveBrokerProfile(BrokerProfile(
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
          await _storage.saveParentProfile(ParentProfile(
            userId: uid,
            name: displayName,
            lookingFor: looking,
            city: parentCity ?? '',
            state: parentState ?? '',
            createdAt: DateTime.now(),
          ));
          break;

        case UserRole.candidate:
          // Minimal profile at setup — can be enhanced later
          break;
      }

      // Log the user in
      final finalUser = _storage.getUser(uid)!;
      await _storage.setCurrentUser(uid);
      state = AuthAuthenticated(user: finalUser);
    } catch (e) {
      state = AuthError(message: 'Profile setup failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storage.clearSession();
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
  final storage = ref.watch(localStorageServiceProvider);
  return AuthNotifier(storage);
});
