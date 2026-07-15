import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'common_providers.dart';
import '../services/bootstrap_service.dart';
import '../exceptions/sync_exceptions.dart';
import '../../data/api/user_api.dart';

// Stream of auth state updates from Supabase
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user profile
final currentUserProvider = Provider<User?>((ref) {
  // Listen to auth state to re-evaluate when user changes
  ref.watch(authStateProvider);
  return ref.read(authServiceProvider).currentUser;
});

// Check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authServiceProvider).isSignedIn;
});

enum BootstrapState { uninitialized, initializing, success, protocolMismatch, error }

class BootstrapNotifier extends AsyncNotifier<BootstrapState> {
  @override
  Future<BootstrapState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return BootstrapState.uninitialized;
    }

    try {
      final dbHelper = ref.read(databaseHelperProvider);
      // Initialize database for user
      await dbHelper.initDatabase(user.id);

      final isBootstrapped = await dbHelper.isBootstrapped();
      if (!isBootstrapped) {
        // Perform best-effort user initialization on backend
        try {
          await UserApi().initializeUser();
        } catch (_) {
          // Best-effort, bootstrap will proceed
        }

        // Seed database from backend
        await BootstrapService.instance.bootstrapUser(user.id);
      }
      return BootstrapState.success;
    } on UnsupportedSyncProtocolException {
      return BootstrapState.protocolMismatch;
    } catch (_) {
      return BootstrapState.error;
    }
  }

  Future<void> retryBootstrap() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return BootstrapState.uninitialized;

      final dbHelper = ref.read(databaseHelperProvider);
      await dbHelper.initDatabase(user.id);
      
      try {
        await UserApi().initializeUser();
      } catch (_) {}

      await BootstrapService.instance.bootstrapUser(user.id);
      return BootstrapState.success;
    });
  }
}

final bootstrapStatusProvider = AsyncNotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);
