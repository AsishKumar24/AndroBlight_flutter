import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/scan_result.dart';

/// API Service - HTTP Client using Dio
/// Now supports JWT Authorization header for authenticated requests.

class ApiService {
  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Add interceptor for logging (debug mode)
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Auto-refresh token on 401
          if (error.response?.statusCode == 401 &&
              _refreshToken != null &&
              error.response?.data?['code'] == 'token_expired') {
            try {
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                // Retry the original request
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $_accessToken';
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (_) {}
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Set auth tokens (called after login/register)
  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear auth tokens (called on logout)
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Refresh access token
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        ApiConfig.refreshEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $_refreshToken'}),
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // HEALTH
  // ============================================================================

  /// Health check - GET /health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        ApiConfig.healthEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return data['status'] == 'ok';
      }
      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  // ============================================================================
  // SCAN ENDPOINTS
  // ============================================================================

  /// Scan APK file - POST /predict
  Future<ScanResult> scanApk(
    File file, {
    Map<String, dynamic>? deviceInfo,
    void Function(int sent, int total)? onProgress,
    bool forceRescan = false,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      };

      if (forceRescan) {
        fields['force_rescan'] = 'true';
      }

      // Attach device info fields for root detection (4A)
      if (deviceInfo != null) {
        fields['is_rooted'] = deviceInfo['is_rooted']?.toString() ?? 'false';
        if (deviceInfo['device_model'] != null) {
          fields['device_model'] = deviceInfo['device_model'];
        }
        if (deviceInfo['android_version'] != null) {
          fields['android_version'] = deviceInfo['android_version'];
        }
      }

      final formData = FormData.fromMap(fields);

      final response = await _dio.post(
        ApiConfig.predictEndpoint,
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return _scanResultFromResponseData(response.data);
      }
      throw ServerException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Scan Play Store app - POST /predict-playstore
  Future<ScanResult> scanPlayStore({String? packageName, String? url}) async {
    try {
      final Map<String, dynamic> body = {};
      if (url != null && url.isNotEmpty) {
        body['url'] = url;
      } else if (packageName != null && packageName.isNotEmpty) {
        body['package'] = packageName;
      } else {
        throw InvalidInputException('Please provide a package name or URL');
      }

      final response = await _dio.post(
        ApiConfig.predictPlaystoreEndpoint,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return _scanResultFromResponseData(response.data);
      }
      throw ServerException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Normalize Dio JSON (often `Map<dynamic, dynamic>`) for [ScanResult.fromJson].
  ScanResult _scanResultFromResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ScanResult.fromJson(data);
    }
    if (data is Map) {
      return ScanResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw ServerException('Invalid scan response: expected JSON object');
  }

  /// Clears server-side scan cache (`scan_cache.json`). POST /clear-cache
  Future<void> clearServerScanCache() async {
    try {
      final response = await _dio.post(ApiConfig.clearCacheEndpoint);
      if (response.statusCode == 200) {
        return;
      }
      throw ServerException('Unexpected response when clearing cache');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  /// Register - POST /auth/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          if (displayName != null) 'display_name': displayName,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        setTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return data;
      }
      throw ServerException('Registration failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Login - POST /auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {'email': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return data;
      }
      throw ServerException('Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get profile - GET /auth/me
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.profileEndpoint);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException('Failed to get profile');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // SYNC ENDPOINTS
  // ============================================================================

  /// Pull sync history - GET /sync/history
  Future<Map<String, dynamic>> pullSyncHistory({String? since}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (since != null) queryParams['since'] = since;

      final response = await _dio.get(
        ApiConfig.syncHistoryGet,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException('Failed to pull sync history');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Push sync history - POST /sync/history
  Future<Map<String, dynamic>> pushSyncHistory(
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.syncHistoryPush,
        data: {'records': records},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException('Failed to push sync history');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // HISTORY ENDPOINT
  // ============================================================================

  /// Get filtered history - GET /history
  Future<Map<String, dynamic>> getFilteredHistory({
    String? search,
    String? filter,
    String? sort,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filter != null && filter.isNotEmpty) queryParams['filter'] = filter;
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
      if (fromDate != null) queryParams['from'] = fromDate;
      if (toDate != null) queryParams['to'] = toDate;

      final response = await _dio.get(
        ApiConfig.historyEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException('Failed to get history');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['error'] ??
            e.response?.data?['message'] ??
            'Server error occurred';
        if (statusCode == 400) {
          return InvalidInputException(message.toString());
        }
        if (statusCode == 401) {
          return ApiException('Authentication failed', statusCode: statusCode);
        }
        if (statusCode == 404) {
          return ApiException('Resource not found', statusCode: statusCode);
        }
        if (statusCode == 409) {
          return ApiException(message.toString(), statusCode: statusCode);
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message.toString());
        }
        return ApiException(message.toString(), statusCode: statusCode);
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled');
      default:
        return NetworkException(e.message ?? 'An unexpected error occurred');
    }
  }

  // ============================================================================
  // MONITOR ENDPOINTS (Feature 1 / Chunk 4D)
  // ============================================================================

  /// Check installed apps - POST /monitor/installed-apps
  Future<Map<String, dynamic>> checkInstalledApps(List<String> packages) async {
    try {
      final response = await _dio.post(
        ApiConfig.monitorInstalledAppsEndpoint,
        data: {'packages': packages},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // RULES ENDPOINTS (Feature 6 / Chunk 5)
  // ============================================================================

  /// List all custom threat rules - GET /rules
  Future<List<Map<String, dynamic>>> getRules() async {
    try {
      final response = await _dio.get(ApiConfig.rulesEndpoint);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['rules'] ?? []);
      }
      throw ServerException('Failed to fetch rules');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a custom threat rule - POST /rules
  Future<Map<String, dynamic>> createRule({
    required String name,
    required List<String> permissions,
    required String threat,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.rulesEndpoint,
        data: {
          'name': name,
          'permissions': permissions,
          'threat': threat,
          'description': description,
        },
      );
      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to create rule');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update a custom threat rule - PUT /rules/<id>
  Future<Map<String, dynamic>> updateRule(
    int ruleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.rulesEndpoint}/$ruleId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to update rule');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a custom threat rule - DELETE /rules/<id>
  Future<void> deleteRule(int ruleId) async {
    try {
      await _dio.delete('${ApiConfig.rulesEndpoint}/$ruleId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============================================================================
  // RESCAN ENDPOINTS (Feature 2 / Chunk 5)
  // ============================================================================

  /// Get verdict-changed records since a timestamp - GET /rescan/updates?since=
  Future<Map<String, dynamic>> getRescanUpdates({String? since}) async {
    try {
      final queryParams = since != null
          ? {'since': since}
          : <String, dynamic>{};
      final response = await _dio.get(
        ApiConfig.rescanUpdatesEndpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to fetch rescan updates');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Two-Factor Authentication (Chunk 6) ──────────────────────────────────

  Future<Map<String, dynamic>> getTwoFaStatus() async {
    try {
      final response = await _dio.get(ApiConfig.twoFaStatusEndpoint);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to get 2FA status');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> setupTwoFa() async {
    try {
      final response = await _dio.post(ApiConfig.twoFaSetupEndpoint);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to setup 2FA');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> confirmTwoFa(String otp) async {
    try {
      final response = await _dio.post(
        ApiConfig.twoFaConfirmEndpoint,
        data: {'otp': otp},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to confirm 2FA');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify OTP during login — uses pre_auth_token in body, NOT the auth header.
  Future<Map<String, dynamic>> verifyTwoFa(
    String preAuthToken,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.twoFaVerifyEndpoint,
        data: {'pre_auth_token': preAuthToken, 'otp': otp},
        options: Options(headers: {'Authorization': 'Bearer $preAuthToken'}),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to verify OTP');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> disableTwoFa(String password, String otp) async {
    try {
      final response = await _dio.post(
        ApiConfig.twoFaDisableEndpoint,
        data: {'password': password, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException('Failed to disable 2FA');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
