import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/cloud_sync_status.dart';
import '../../models/social/social_session.dart';
import '../../repositories/app_data_repository.dart';
import '../local_storage_service.dart';
import 'social_backend_bootstrap_service.dart';
import 'social_supabase_service.dart';

/// Keeps Hive as the source of truth and mirrors a full private snapshot later.
class CloudSyncService {
  CloudSyncService({
    required AppDataRepository appDataRepository,
    required SocialBackendBootstrapService bootstrapService,
    Connectivity? connectivity,
  }) : _appDataRepository = appDataRepository,
       _bootstrapService = bootstrapService,
       _connectivity = connectivity ?? Connectivity();

  static const _enabledAccountKey = 'cloud_sync_enabled_account_id';
  static const _dirtyKey = 'cloud_sync_has_pending_changes';
  static const _lastSyncedAtKey = 'cloud_sync_last_synced_at';
  static const _lastErrorKey = 'cloud_sync_last_error';

  final AppDataRepository _appDataRepository;
  final SocialBackendBootstrapService _bootstrapService;
  final Connectivity _connectivity;

  final List<StreamSubscription<BoxEvent>> _boxSubscriptions = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  SocialSession? _session;
  bool _isSyncing = false;
  bool _isRestoring = false;
  int _changeVersion = 0;

  Future<void> configure(SocialSession? session) async {
    _session = session;
    if (!_isEligible(session) || !_isEnabledFor(session!)) {
      return;
    }

    _startWatchingLocalChanges();
    await _startWatchingConnectivity();
    if (_hasPendingChanges) _scheduleSync();
  }

  Future<CloudSyncStatus> status(SocialSession? session) async {
    final isAvailable =
        _bootstrapService.config.isConfigured &&
        SocialSupabaseService.isInitialized;
    final isAuthenticated = session?.isAuthenticated ?? false;
    final isEnabled = isAuthenticated && _isEnabledFor(session!);
    return CloudSyncStatus(
      isAvailable: isAvailable,
      isAuthenticated: isAuthenticated,
      isEnabled: isEnabled,
      hasPendingChanges: isEnabled && _hasPendingChanges,
      isSyncing: _isSyncing,
      lastSyncedAt: _readDate(_metadata.get(_lastSyncedAtKey)),
      lastError: _metadata.get(_lastErrorKey) as String?,
    );
  }

  /// Enables sync by uploading this device first, so no local data is lost.
  Future<void> enable(SocialSession session) async {
    _requireEligible(session);
    await _metadata.put(_enabledAccountKey, session.profileId);
    await _markDirty();
    await configure(session);
    await syncNow(session);
  }

  Future<void> disable() async {
    _syncTimer?.cancel();
    await _metadata.delete(_enabledAccountKey);
    await _metadata.delete(_dirtyKey);
  }

  Future<void> syncNow(SocialSession? session) async {
    final resolvedSession = session ?? _session;
    if (!_isEligible(resolvedSession) || !_isEnabledFor(resolvedSession!)) {
      return;
    }
    if (_isSyncing) return;

    _isSyncing = true;
    final versionAtStart = _changeVersion;
    try {
      final profileId = await _remoteProfileId(resolvedSession);
      final snapshot = await _appDataRepository.snapshot();
      await SocialSupabaseService.client.from('user_data_snapshots').upsert({
        'profile_id': profileId,
        'payload': snapshot.toMap(),
      }, onConflict: 'profile_id');

      if (_changeVersion == versionAtStart) {
        await _metadata.put(_dirtyKey, false);
      }
      await _metadata.put(_lastSyncedAtKey, DateTime.now().toIso8601String());
      await _metadata.delete(_lastErrorKey);
    } catch (error) {
      await _metadata.put(_dirtyKey, true);
      await _metadata.put(_lastErrorKey, error.toString());
    } finally {
      _isSyncing = false;
      if (_hasPendingChanges) _scheduleSync(delay: const Duration(seconds: 8));
    }
  }

  /// Replaces local content only after the caller obtains explicit confirmation.
  Future<bool> restoreFromCloud(SocialSession session) async {
    _requireEligible(session);
    final profileId = await _remoteProfileId(session);
    final row =
        await SocialSupabaseService.client
            .from('user_data_snapshots')
            .select('payload')
            .eq('profile_id', profileId)
            .maybeSingle();
    if (row == null || row['payload'] is! Map) return false;

    _isRestoring = true;
    try {
      final snapshot = AppDataSnapshot.fromMap(
        Map<String, dynamic>.from(row['payload'] as Map),
      );
      await _appDataRepository.replaceSnapshot(snapshot);
      await Future<void>.delayed(Duration.zero);
      await _metadata.put(_dirtyKey, false);
      await _metadata.delete(_lastErrorKey);
      return true;
    } finally {
      _isRestoring = false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    for (final subscription in _boxSubscriptions) {
      subscription.cancel();
    }
    _boxSubscriptions.clear();
  }

  Box<dynamic> get _metadata => LocalStorageService.cloudSyncBox;

  bool get _hasPendingChanges => _metadata.get(_dirtyKey) == true;

  bool _isEligible(SocialSession? session) =>
      _bootstrapService.config.isConfigured &&
      SocialSupabaseService.isInitialized &&
      session?.isAuthenticated == true &&
      session?.profileId != null;

  bool _isEnabledFor(SocialSession session) =>
      _metadata.get(_enabledAccountKey) == session.profileId;

  void _requireEligible(SocialSession session) {
    if (!_isEligible(session)) {
      throw StateError('Entre em uma conta para usar a sincronizacao.');
    }
  }

  Future<String> _remoteProfileId(SocialSession session) async {
    final row =
        await SocialSupabaseService.client
            .from('profiles')
            .select('id')
            .eq('auth_user_id', session.profileId!)
            .maybeSingle();
    final profileId = row?['id'];
    if (profileId is! String) {
      throw StateError(
        'Sua conta ainda esta sendo preparada. Tente novamente.',
      );
    }
    return profileId;
  }

  void _startWatchingLocalChanges() {
    if (_boxSubscriptions.isNotEmpty) return;
    for (final box in LocalStorageService.syncableBoxes) {
      _boxSubscriptions.add(box.watch().listen(_handleLocalChange));
    }
  }

  Future<void> _startWatchingConnectivity() async {
    if (_connectivitySubscription != null) return;
    final connection = await _connectivity.checkConnectivity();
    if (_hasNetwork(connection)) _scheduleSync();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      connection,
    ) {
      if (_hasNetwork(connection) && _hasPendingChanges) _scheduleSync();
    });
  }

  void _handleLocalChange(BoxEvent _) {
    if (_isRestoring) return;
    _changeVersion++;
    unawaited(_markDirty());
  }

  Future<void> _markDirty() async {
    final session = _session;
    if (!_isEligible(session) || !_isEnabledFor(session!)) return;
    await _metadata.put(_dirtyKey, true);
    _scheduleSync();
  }

  void _scheduleSync({Duration delay = const Duration(milliseconds: 900)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () => unawaited(syncNow(_session)));
  }

  bool _hasNetwork(List<ConnectivityResult> connection) =>
      connection.any((item) => item != ConnectivityResult.none);

  DateTime? _readDate(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }
}
