import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:testing_flutter/core/errors/app_exceptions.dart';

/// Thin HTTP client wrapping [http.Client] with:
///
/// - Automatic `Authorization: Bearer <token>` injection
/// - Token persistence via [FlutterSecureStorage]
/// - Token refresh on 401
/// - Consistent error mapping to [AppException] subtypes
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage? storage,
  })  : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // ── Token lifecycle ────────────────────────────────────────────────

  /// Restore tokens from secure storage on app start.
  Future<void> restoreTokens() async {
    _accessToken = await _storage.read(key: _keyAccess);
    _refreshToken = await _storage.read(key: _keyRefresh);
  }

  /// Store tokens after login/refresh.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _keyAccess, value: accessToken),
      _storage.write(key: _keyRefresh, value: refreshToken),
    ]);
  }

  /// Clear tokens on logout.
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
    ]);
  }

  bool get hasTokens => _accessToken != null && _accessToken!.isNotEmpty;

  // ── HTTP verbs ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _send(() => _http.get(uri, headers: _headers()));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _send(
      () => _http.post(uri, headers: _headers(), body: _encode(body)),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _send(
      () => _http.put(uri, headers: _headers(), body: _encode(body)),
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    final response = await _send(() => _http.delete(uri, headers: _headers()));
    if (response.statusCode >= 400) {
      _throwForStatus(response);
    }
  }

  // ── Internals ──────────────────────────────────────────────────────

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    return h;
  }

  String? _encode(Map<String, dynamic>? body) =>
      body != null ? jsonEncode(body) : null;

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 400) {
      _throwForStatus(response);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Sends a request with automatic 401 retry (token refresh).
  Future<http.Response> _send(
    Future<http.Response> Function() doRequest,
  ) async {
    final response = await doRequest();
    if (response.statusCode == 401 && !_isRefreshing && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return doRequest();
      }
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final uri = _buildUri('/api/v1/auth/refresh');
      final response = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String;
        _accessToken = newAccess;
        await _storage.write(key: _keyAccess, value: newAccess);
        return true;
      }
      await clearTokens();
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Never _throwForStatus(http.Response response) {
    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    final apiError = errorBody?['error'] as Map<String, dynamic>?;
    final message = apiError?['message'] as String? ?? response.reasonPhrase ?? 'Unknown error';
    final code = apiError?['code'] as String? ?? '';

    switch (response.statusCode) {
      case 400:
        throw ValidationException(field: '', message: message);
      case 401:
        throw AuthException(message);
      case 403:
        throw AuthException('Forbidden: $message');
      case 404:
        throw NotFoundException(entityType: code, id: message);
      case 409:
        throw DuplicateException(entityType: code, message: message);
      default:
        throw AppException('Server error (${ response.statusCode}): $message');
    }
  }
}
