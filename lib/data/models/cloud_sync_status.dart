class CloudSyncStatus {
  const CloudSyncStatus({
    required this.isAvailable,
    required this.isAuthenticated,
    required this.isEnabled,
    required this.hasPendingChanges,
    required this.isSyncing,
    this.lastSyncedAt,
    this.lastError,
  });

  final bool isAvailable;
  final bool isAuthenticated;
  final bool isEnabled;
  final bool hasPendingChanges;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? lastError;
}
