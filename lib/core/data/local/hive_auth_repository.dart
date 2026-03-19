import 'package:testing_flutter/core/data/repositories/auth_repository.dart';
import 'package:testing_flutter/models/user_role.dart';

/// Mock OTP code used for demo mode.
const _mockOtpCode = '123456';

/// Hive-backed (local/mock) implementation of [AuthRepository].
///
/// Always accepts OTP [_mockOtpCode]. A future remote implementation
/// would call a real SMS/auth service.
class HiveAuthRepository implements AuthRepository {
  @override
  Future<bool> sendOtp({
    required String phoneNumber,
    required UserRole selectedRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return otpCode == _mockOtpCode;
  }

  @override
  String? get demoOtpCode => _mockOtpCode;
}
