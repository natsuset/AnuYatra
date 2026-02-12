import 'package:testing_flutter/models/app_user.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Sealed class representing all possible authentication states.
sealed class AuthState {
  const AuthState();
}

/// Initial state — checking if user is already logged in
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state — performing auth operation
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP has been sent to the phone number
class AuthOtpSent extends AuthState {
  final String phoneNumber;
  final UserRole selectedRole;

  const AuthOtpSent({
    required this.phoneNumber,
    required this.selectedRole,
  });
}

/// User is fully authenticated with a complete profile
class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated({required this.user});
}

/// User verified OTP but needs to complete their profile
class AuthNeedsProfile extends AuthState {
  final String uid;
  final String phoneNumber;
  final UserRole role;

  const AuthNeedsProfile({
    required this.uid,
    required this.phoneNumber,
    required this.role,
  });
}

/// Authentication error
class AuthError extends AuthState {
  final String message;
  final AuthState? previousState;

  const AuthError({
    required this.message,
    this.previousState,
  });
}
