import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/network/interceptors.dart';
import 'core/network/api_constants.dart';
import 'core/services/sync_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/provider_observer.dart';
import 'core/providers/common_providers.dart';
import 'core/providers/app_settings_provider.dart';

// Supabase project credentials
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty || ApiConstants.baseUrl.isEmpty) {
    throw StateError(
      'Missing required compile-time variables. Build the application using:\n'
      '--dart-define=API_BASE_URL=... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...'
    );
  }

  // Initialize Supabase — must happen before any auth operations.
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  final sharedPrefs = await SharedPreferences.getInstance();

  SyncService.instance.initialize();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      observers: const [StudentBuddyProviderObserver()],
      child: const StudentBuddyApp(),
    ),
  );
}

class StudentBuddyApp extends ConsumerWidget {
  const StudentBuddyApp({super.key});

  // Global navigator key so the Dio interceptor can redirect on 401.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire the navigator key into the interceptor once.
    AppInterceptors.navigatorKey = navigatorKey;

    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Student Buddy',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentTheme,
      // Named routes used by the 401 interceptor redirect.
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
