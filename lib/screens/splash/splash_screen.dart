import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/bootstrap_service.dart';
import '../../data/local/database_helper.dart';
import '../../data/api/user_api.dart';
import '../../data/repositories/semester_repository.dart';
import '../../core/exceptions/sync_exceptions.dart';
import '../auth/login_screen.dart';
import '../navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String? _errorMessage;
  bool _isLoading = true;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final startTime = DateTime.now();

    // Check if the user already has an active Supabase session.
    final hasSession = AuthService.instance.isSignedIn;
    final userId = AuthService.instance.currentUser?.id;
    Widget destination;

    if (hasSession && userId != null) {
      bool bootstrapSucceeded = false;
      try {
        // Initialize SQLite Database
        await DatabaseHelper.instance.initDatabase(userId);
        
        // Check if database is already bootstrapped locally
        final isBootstrapped = await DatabaseHelper.instance.isBootstrapped();
        if (!isBootstrapped) {
          // Perform idempotent user initialization on backend
          try {
            await UserApi().initializeUser();
          } catch (_) {
            // Best-effort user initialization, bootstrap will proceed
          }
          
          // Seed local database from backend
          await BootstrapService.instance.bootstrapUser(userId);
        }
        bootstrapSucceeded = true;
      } on UnsupportedSyncProtocolException catch (e) {
        debugPrint('Bootstrap failed due to protocol version mismatch: $e');
        setState(() {
          _errorMessage = 'This version of Student Buddy is no longer compatible with the server. Please update the application.';
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('Bootstrap failed during splash screen: $e');
        setState(() {
          _errorMessage = 'Failed to load offline data. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      if (bootstrapSucceeded) {
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
          debugPrint('Failed to load semesters after bootstrap: $e');
          AppState.instance.setActiveSemester(null);
        }
      }
      destination = const NavigationShell();
    } else {
      // No session — go to login.
      destination = const LoginScreen();
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await AuthService.instance.signOut();
      await DatabaseHelper.instance.closeDatabase();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Failed to sign out from splash error screen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to sign out. Please close the app and reopen it.';
        });
      }
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
              
              // Loading or Error UI
              if (_isLoading)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _bootstrap,
                            icon: const Icon(Icons.refresh),
                            label: const String.fromEnvironment('test') != ''
                                ? const Text('Retry')
                                : const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
