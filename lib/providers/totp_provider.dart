import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// TOTP Provider — manages 2FA setup, confirmation, and disable flow

enum TotpState { idle, loading, success, error }

class TotpProvider extends ChangeNotifier {
  final ApiService _apiService;

  TotpState _state = TotpState.idle;
  String? _errorMessage;
  bool _twoFaEnabled = false;
  String? _secret;
  String? _otpauthUri;

  TotpProvider(this._apiService);

  // Getters
  TotpState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get twoFaEnabled => _twoFaEnabled;
  String? get secret => _secret;
  String? get otpauthUri => _otpauthUri;
  bool get isLoading => _state == TotpState.loading;

  /// Load current 2FA status from the server
  Future<void> loadStatus() async {
    _state = TotpState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getTwoFaStatus();
      _twoFaEnabled = response['two_factor_enabled'] as bool? ?? false;
      _state = TotpState.success;
    } catch (e) {
      _state = TotpState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  /// Request a new TOTP secret and provisioning URI for QR display
  Future<bool> setupTwoFa() async {
    _state = TotpState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.setupTwoFa();
      _secret = response['secret'] as String?;
      _otpauthUri = response['otpauth_uri'] as String?;
      _state = TotpState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = TotpState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Confirm the first OTP to activate 2FA
  Future<bool> confirmTwoFa(String otp) async {
    _state = TotpState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.confirmTwoFa(otp);
      _twoFaEnabled = true;
      _state = TotpState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = TotpState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Disable 2FA (requires current password + OTP)
  Future<bool> disableTwoFa(String password, String otp) async {
    _state = TotpState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.disableTwoFa(password, otp);
      _twoFaEnabled = false;
      _secret = null;
      _otpauthUri = null;
      _state = TotpState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = TotpState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_state == TotpState.error) {
      _state = TotpState.idle;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _state = TotpState.idle;
    _errorMessage = null;
    _secret = null;
    _otpauthUri = null;
    notifyListeners();
  }
}
