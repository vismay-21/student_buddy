import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_state.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();
  runApp(const StudentBuddyApp());
}

class StudentBuddyApp extends StatelessWidget {
  const StudentBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Student Buddy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
