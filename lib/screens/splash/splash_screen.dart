import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../data/repositories/semester_repository.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startTime = DateTime.now();
    try {
      final list = await SemesterRepository().getSemesters();
      if (list.isNotEmpty) {
        final savedId = AppState.instance.savedActiveSemesterId;
        final found = list.firstWhere(
          (s) => s.semesterId == savedId,
          orElse: () => list.first,
        );
        AppState.instance.setActiveSemester(found);
      } else {
        AppState.instance.setActiveSemester(null);
      }
    } catch (e) {
      debugPrint('Failed to bootstrap semesters: $e');
      AppState.instance.setActiveSemester(null);
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Icon Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 90,
                          color: AppTheme.primary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Icon(
                            Icons.school_rounded,
                            size: 40,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // App Title
              FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    Text(
                      'STUDENT BUDDY',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = AppTheme.primaryGradient.createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                          ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Academic Operating System',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
