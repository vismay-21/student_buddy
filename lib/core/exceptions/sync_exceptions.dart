class UnsupportedSyncProtocolException implements Exception {
  final int minExpectedVersion;
  final int maxExpectedVersion;
  final int? receivedVersion;

  UnsupportedSyncProtocolException({
    required this.minExpectedVersion,
    required this.maxExpectedVersion,
    required this.receivedVersion,
  });

  @override
  String toString() =>
      'Sync protocol mismatch. Client supports: $minExpectedVersion-$maxExpectedVersion, Server returned: ${receivedVersion ?? "unknown"}. Synchronization aborted.';
}
