import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'repositories/scan_repository.dart';
import 'repositories/history_repository.dart';
import 'providers/health_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/history_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/monitor_provider.dart';
import 'providers/rules_provider.dart';
import 'providers/totp_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService();

  // Initialize auth service (restores saved tokens into ApiService)
  final authService = AuthService(apiService);
  await authService.init();

  // Restore AuthProvider state from storage before any screen reads isAuthenticated.
  // (Hot restart re-runs main; without awaiting, Splash could see initial != authenticated.)
  final authProvider = AuthProvider(authService);
  await authProvider.init();

  // Create repositories
  final scanRepository = ScanRepository(apiService);
  final historyRepository = HistoryRepository(storageService, apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => authProvider,
        ),
        ChangeNotifierProvider(create: (_) => HealthProvider(scanRepository)),
        ChangeNotifierProvider(
          create: (_) => ScanProvider(scanRepository, historyRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(historyRepository, apiService),
        ),
        // Feature 1 / Chunk 4D — Installed App Monitoring
        ChangeNotifierProvider(create: (_) => MonitorProvider(apiService)),
        // Feature 6 / Chunk 5 — Custom Threat Rules
        ChangeNotifierProvider(create: (_) => RulesProvider(apiService)),
        // Chunk 6 — Two-Factor Authentication
        ChangeNotifierProvider(create: (_) => TotpProvider(apiService)),
      ],
      child: const AndroBlight(),
    ),
  );
}

class AndroBlight extends StatelessWidget {
  const AndroBlight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndroBlight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
