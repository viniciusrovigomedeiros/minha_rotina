import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/okr_migration_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await OkrMigrationService().ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: MinhaRotinaApp()));
}
