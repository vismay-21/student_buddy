import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentBuddyProviderObserver extends ProviderObserver {
  const StudentBuddyProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Exclude high-frequency or noisy states from verbose logging
    if (provider.name == 'connectivityProvider') return;

    if (kDebugMode) {
      debugPrint('[Riverpod Update] ${provider.name ?? provider.runtimeType}');
      if (previousValue is AsyncValue && newValue is AsyncValue) {
        if (newValue.isLoading) {
          debugPrint('  --> Transitioned to Loading');
        } else if (newValue.hasError) {
          debugPrint('  --> Error: ${newValue.error}');
        } else {
          debugPrint('  --> Loaded Success');
        }
      } else {
        debugPrint('  --> Value changed from $previousValue to $newValue');
      }
    }
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('[Riverpod Add] ${provider.name ?? provider.runtimeType} initialized');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('[Riverpod Dispose] ${provider.name ?? provider.runtimeType} disposed');
    }
  }
}
