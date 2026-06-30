import 'package:testing_flutter/core/data/remote/api_client.dart';
import 'package:testing_flutter/core/data/repositories/auth_repository.dart';
import 'package:testing_flutter/models/user_role.dart';

/// [AuthRepository] backed by the Go REST API.
///
/// Unlike the Hive implementation, OTP is actually sent server-side.
/// The session ID returned by `sendOtp` must be passed to `verifyOtp`.
/// Token storage is handled by [ApiClient], not by this repository.
class RemoteAuthRepository implements AuthRepository {
  final ApiClient _api;

  String? _sessionId;
  String? _lastOtpHint;

  RemoteAuthRepository(this._api);

  @override
  Future<bool> sendOtp({
    required String phoneNumber,
    required UserRole selectedRole,
  }) async {
    final data = await _api.post('/api/v1/auth/send-otp', body: {
      'phoneNumber': phoneNumber,
      'role': selectedRole.name,
    });
    _sessionId = data['sessionId'] as String?;
    _lastOtpHint = data['otp'] as String?;
    return true;
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final data = await _api.post('/api/v1/auth/verify-otp', body: {
        'sessionId': _sessionId ?? '',
        'phoneNumber': phoneNumber,
        'otp': otpCode,
        'role': 'parent',
      });

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        await _api.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String? get demoOtpCode => _lastOtpHint;
}
