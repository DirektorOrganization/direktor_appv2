import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app_defaults.dart';
import 'app/direktor_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(appLocale.toLanguageTag());
  Intl.defaultLocale = appLocale.toLanguageTag();
  runApp(const DirektorApp());
}
