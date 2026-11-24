import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/services/push_notification_service.dart';
import 'router.dart';

class LaganStaffApp extends ConsumerStatefulWidget {
  const LaganStaffApp({super.key});

  @override
  ConsumerState<LaganStaffApp> createState() => _LaganStaffAppState();
}

class _LaganStaffAppState extends ConsumerState<LaganStaffApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final pushService = ref.read(pushNotificationServiceProvider);
        final router = ref.read(routerProvider);
        pushService.onNotificationTapped = (route) {
          router.push(route);
        };
        pushService.initialize();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LaganStaff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
