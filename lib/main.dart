import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app_defaults.dart';
import 'app/direktor_app.dart';
import 'app/notifications/notification_service.dart';
import 'app/sync/background_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(appLocale.toLanguageTag());
  Intl.defaultLocale = appLocale.toLanguageTag();
  await NotificationService.instance.initialize();
  await BackgroundSyncService.initialize();
  runApp(const DirektorApp());
}
