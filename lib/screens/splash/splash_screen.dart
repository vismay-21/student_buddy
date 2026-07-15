import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/common_providers.dart';
import '../../core/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../navigation_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatusAndNavigate();
    });
  }

  Future<void> _checkStatusAndNavigate() async {
    final startTime = DateTime.now();

    final bootstrapVal = await ref.read(bootstrapStatusProvider.future);

    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    if (bootstrapVal == BootstrapState.success) {
      _navigateTo(const NavigationShell());
    } else if (bootstrapVal == BootstrapState.uninitialized) {
      _navigateTo(const LoginScreen());
    } else if (bootstrapVal == BootstrapState.protocolMismatch) {
      setState(() {
        _errorMessage = 'This version of Student Buddy is no longer compatible with the server. Please update the application.';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to load offline data. Please check your internet connection and try again.';
        _isLoading = false;
      });
    }
  }

  void _navigateTo(Widget destination) {
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

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(authServiceProvider).signOut();
      await ref.read(databaseHelperProvider).closeDatabase();
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

  Future<void> _retryBootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await ref.read(bootstrapStatusProvider.notifier).retryBootstrap();
    _checkStatusAndNavigate();
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
                            onPressed: _retryBootstrap,
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
