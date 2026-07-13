import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_state.dart';
import 'core/network/interceptors.dart';
import 'core/services/sync_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';

// Supabase project credentials
const String _supabaseUrl = 'https://saixbsrkgwbkapvumyiy.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhaXhic3JrZ3dia2FwdnVteWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NTM3ODQsImV4cCI6MjA5OTIyOTc4NH0.0QaP9yKfkHrGNJrXTpfpiVMW_MblYz3-WzK2LLkB3z8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — must happen before any auth operations.
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  await AppState.instance.init();
  SyncService.instance.initialize();
  runApp(const StudentBuddyApp());
}

class StudentBuddyApp extends StatelessWidget {
  const StudentBuddyApp({super.key});

  // Global navigator key so the Dio interceptor can redirect on 401.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Wire the navigator key into the interceptor once.
    AppInterceptors.navigatorKey = navigatorKey;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, currentTheme, _) {
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
      },
    );
  }
}
