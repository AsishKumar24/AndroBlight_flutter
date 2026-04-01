/// API Configuration Constants
/// Change [baseUrl] to point to your backend server

class ApiConfig {
  // ⚠️ DEV MODE - Set to true to skip backend and use mock responses
  // Set to false to use real backend at baseUrl
  static const bool devMode = false;

  // Backend base URL - change this to your actual backend URL
  static const String baseUrl = 'http://localhost:5111';

  // Scan Endpoints
  static const String healthEndpoint = '/health';
  static const String predictEndpoint = '/predict';
  static const String predictPlaystoreEndpoint = '/predict-playstore';
  /// Clears server-side `scan_cache.json` (POST).
  static const String clearCacheEndpoint = '/clear-cache';

  // Auth Endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String profileEndpoint = '/auth/me';

  // Sync Endpoints
  static const String syncHistoryGet = '/sync/history';
  static const String syncHistoryPush = '/sync/history';

  // History Endpoints
  static const String historyEndpoint = '/history';

  // Monitor Endpoints (Feature 1 / Chunk 4D)
  static const String monitorInstalledAppsEndpoint = '/monitor/installed-apps';

  // AV Engines Endpoint (Feature 7 / Chunk 4C)
  static const String enginesEndpoint = '/engines';

  // Custom Threat Rules Endpoints (Feature 6 / Chunk 5)
  static const String rulesEndpoint = '/rules';

  // Rescan / Updates Endpoint (Feature 2 / Chunk 5)
  static const String rescanUpdatesEndpoint = '/rescan/updates';

  // Two-Factor Authentication Endpoints (Chunk 6)
  static const String twoFaStatusEndpoint = '/auth/2fa/status';
  static const String twoFaSetupEndpoint = '/auth/2fa/setup';
  static const String twoFaConfirmEndpoint = '/auth/2fa/confirm';
  static const String twoFaVerifyEndpoint = '/auth/2fa/verify';
  static const String twoFaDisableEndpoint = '/auth/2fa/disable';

  // Timeouts (in milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 60000;
  static const int sendTimeout = 60000;
}
