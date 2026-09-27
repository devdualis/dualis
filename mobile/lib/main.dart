import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/app_notification_center.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DualisApp(),
    ),
  );
}

class DualisApp extends ConsumerStatefulWidget {
  const DualisApp({super.key});

  @override
  ConsumerState<DualisApp> createState() => _DualisAppState();
}

class _DualisAppState extends ConsumerState<DualisApp> {
  @override
  void initState() {
    super.initState();
    ref.read(authControllerProvider.notifier).restoreSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Single owner of the notification plugin: registers the one tap
      // handler, captures a cold-start tap, then asks for notification
      // permission the first time the app is opened.
      unawaited(
        ref.read(appNotificationCenterProvider).requestPermissionsOnFirstLaunch(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'DualisCheckUp',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
