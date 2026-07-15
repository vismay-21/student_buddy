import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'common_providers.dart';

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final syncService = ref.watch(syncServiceProvider);
    
    // Listen to changes on the SyncService ValueNotifier
    syncService.stateNotifier.addListener(_listener);
    
    // Dispose listener when provider is destroyed
    ref.onDispose(() {
      syncService.stateNotifier.removeListener(_listener);
    });
    
    return syncService.stateNotifier.value;
  }
  
  void _listener() {
    state = ref.read(syncServiceProvider).stateNotifier.value;
  }

  Future<void> triggerSync() async {
    await ref.read(syncServiceProvider).sync();
  }
}

final syncStateProvider = NotifierProvider<SyncStateNotifier, SyncState>(SyncStateNotifier.new);
