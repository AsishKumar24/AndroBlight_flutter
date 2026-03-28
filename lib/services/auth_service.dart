import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';

/// Auth Service - Handles login, register, token management
/// Stores tokens securely in Hive

class AuthService {
  final ApiService _apiService;

  static const String _authBoxName = 'auth_tokens';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_display_name';
  static const String _userIdKey = 'user_id';

  late Box _authBox;

  AuthService(this._apiService);

  /// Initialize auth storage and restore tokens
  Future<void> init() async {
    _authBox = await Hive.openBox(_authBoxName);

    // Restore saved tokens
    final accessToken = _authBox.get(_accessTokenKey);
    final refreshToken = _authBox.get(_refreshTokenKey);

    if (accessToken != null && refreshToken != null) {
      _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => _authBox.get(_accessTokenKey) != null;

  /// Get stored user email
  String? get userEmail => _authBox.get(_userEmailKey);

  /// Get stored user display name
  String? get displayName => _authBox.get(_userNameKey);

  /// Get stored user ID
  int? get userId => _authBox.get(_userIdKey);

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _apiService.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    // Save tokens and user info
    await _saveAuthData(response);
    return response;
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);

    // 2FA flow: server returns status=="2fa_required" without full tokens
    if (response['status'] != '2fa_required') {
      await _saveAuthData(response);
    }
    return response;
  }

  /// Logout — clear tokens
  Future<void> logout() async {
    _apiService.clearTokens();
    await _authBox.clear();
  }

  /// Verify TOTP code during login (2FA step 2)
  Future<Map<String, dynamic>> verifyTotp(
    String preAuthToken,
    String otp,
  ) async {
    final response = await _apiService.verifyTwoFa(preAuthToken, otp);
    await _saveAuthData(response);
    return response;
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _authBox.put(_accessTokenKey, data['access_token']);
    await _authBox.put(_refreshTokenKey, data['refresh_token']);

    final user = data['user'];
    if (user != null) {
      await _authBox.put(_userEmailKey, user['email']);
      await _authBox.put(_userNameKey, user['display_name']);
      await _authBox.put(_userIdKey, user['id']);
    }
  }
}
