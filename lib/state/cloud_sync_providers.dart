import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cloud_sync_status.dart';
import '../data/services/social/cloud_sync_service.dart';
import 'providers.dart';
import 'social/social_providers.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final service = CloudSyncService(
    appDataRepository: ref.read(appDataRepositoryProvider),
    bootstrapService: ref.read(socialBackendBootstrapServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final cloudSyncAutoStartProvider = Provider<void>((ref) {
  final session = ref.watch(socialSessionControllerProvider).valueOrNull;
  final service = ref.read(cloudSyncServiceProvider);
  unawaited(service.configure(session));
});

final cloudSyncStatusProvider = FutureProvider<CloudSyncStatus>((ref) async {
  final session = ref.watch(socialSessionControllerProvider).valueOrNull;
  return ref.read(cloudSyncServiceProvider).status(session);
});
