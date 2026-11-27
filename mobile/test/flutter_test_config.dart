import 'dart:async';
import 'dart:ui';

import 'package:dualis_mobile/l10n/locale_provider.dart';

/// The test device reports en_US; the suite is written against Portuguese.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugDeviceLocales = const [Locale('pt', 'BR')];
  await testMain();
}
