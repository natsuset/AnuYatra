import 'package:testing_flutter/models/user_role.dart';

/// Contract for authentication operations.
///
/// Separates auth concerns (OTP, verification) from user CRUD.
/// The current implementation uses a mock OTP; a future backend
/// implementation would call a real auth service.
abstract class AuthRepository {
  /// Send an OTP to the given phone number.
  ///
  /// Returns true if the OTP was sent successfully.
  Future<bool> sendOtp({
    required String phoneNumber,
    required UserRole selectedRole,
  });

  /// Verify an OTP code for the given phone number.
  ///
  /// Returns true if the OTP is valid.
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  });

  /// Get the demo OTP code (for display on login screen).
  ///
  /// Returns null if the implementation does not support demo mode.
  String? get demoOtpCode;
}
